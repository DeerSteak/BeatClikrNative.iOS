# Services

## Service Classes

- **ScheduledMetronomeEngine** - Sample-accurate metronome using `AVAudioEngine` and scheduled `AVAudioPlayerNode` buffers. It keeps a small audio lookahead window on the AVAudioEngine sample timeline, then schedules delegate callbacks from the same sample positions so visual animation, haptics, flashlight pulses, and ramp updates line up with beat onset instead of buffer completion. For odd meter grooves, steps through a `[Bool]` accent pattern on every subdivision tick and computes `beatInterval` (time to the next `true` entry) so the delegate can animate each group correctly

- **ScheduledPolyrhythmEngine** - Polyrhythm engine using two independent scheduled `AVAudioPlayerNode` tracks. For M beats against N: the beat track fires every quarter note, the rhythm track fires every `N × 60 / (bpm × M)` seconds, and both tracks start from the same scheduled origin. Schedules `polyrhythmBeatFired` callbacks from each track's sample timeline position with the active beat/rhythm index so the view can animate individual dots independently

- **AudioPlayerService** - `@MainActor` singleton wrapper that owns one `ScheduledMetronomeEngine` and one `ScheduledPolyrhythmEngine`. It configures the shared audio session, builds the app's sound catalog, starts both engines, and forwards callbacks to `MetronomePlaybackViewModel` via `metronomeDelegate` and `PolyrhythmViewModel` via `polyrhythmDelegate`. Metronome and polyrhythm sound loading are intentionally separate (`setupMetronomeAudio` and `setupPolyrhythmAudio`) so each mode can keep its own selected instruments without reloading the other engine. Real-time tempo/subdivision and ramp updates apply to the metronome engine.

- **FlashlightService** - Controls device flashlight for visual beat accessibility

- **VibrationService** - Manages haptic feedback via `UIImpactFeedbackGenerator`

- **UserDefaultsService** - Persists user preferences to both `UserDefaults.standard` and `NSUbiquitousKeyValueStore` for cross-device sync. Observes `didChangeExternallyNotification` to pull in changes from other devices. Exposes an `onSendRemindersEnabled` callback that fires when `sendReminders` transitions `false → true` via cloud sync, so `SettingsViewModel` can respond without coupling the two layers with Combine

- **ReminderNotificationService** - Manages `UNUserNotificationCenter` authorization and scheduling; schedules 7 individual ahead-of-time notifications (one per upcoming day) with pre-computed personalized bodies; caches the last set of bodies so time-change reschedules don't require a new body computation; exposes `currentAuthorizationStatus()` for non-prompting status checks

---

## About Keeping Time

Sample-accurate timing is critical for a metronome. The current implementation uses `AVAudioEngine` with scheduled `AVAudioPlayerNode` buffers so audio timing is handled on the audio render timeline rather than by main-thread timers.

### How it works

`ScheduledMetronomeEngine` pre-schedules a small lookahead window of audio buffers and a matching set of delegate events:

```
First Beat Delay:   67ms (gives the scheduler time to queue initial buffers)
Schedule Ahead:     4 buffers
Clock Source:       AVAudioTime sampleTime on the engine output sample rate
```

**Example with 100 BPM, 8th note subdivisions:**
- Subdivision duration: 60 / (100 BPM × 2 subdivisions) = 300 ms
- The engine converts that duration to samples at the current output sample rate
- Beat and rhythm buffers are scheduled at exact `AVAudioTime(sampleTime:atRate:)` positions
- Delegate callbacks are scheduled with `DispatchQueue.main.asyncAfter` from the same sample-time positions as playback
- Buffer completion callbacks only refill the audio lookahead window

This approach provides:
- **Hardware-timeline timing** — beats are scheduled on the audio engine sample clock
- **No main-thread polling jitter** — playback does not depend on a 1 ms timer
- **No drift** — future buffers are placed by sample time
- **Onset-aligned UI events** — visuals, haptics, flashlight pulses, and ramp callbacks are timed to the scheduled beat position rather than the end of a buffer
- **Real-time tempo changes** — newly scheduled buffers use updated BPM/subdivision settings
- **Simulator & device support** — works reliably on all platforms

### Delegate Pattern

`MetronomePlaybackViewModel` implements `MetronomeAudioEngineDelegate` to receive beat callbacks:
- Triggers visual animations (icon scale, beat pulse for transport bar)
- Fires haptic feedback via `VibrationService`
- Controls flashlight via `FlashlightService`
- Applies ramped BPM updates when `metronomeRampStepped(newBpm:)` fires
- All synchronized to the scheduled audio sample timeline

`PolyrhythmViewModel` implements `PolyrhythmAudioEngineDelegate` through `AudioPlayerService.polyrhythmDelegate`. The service keeps this separate from `metronomeDelegate` so metronome and polyrhythm screens do not overwrite each other's callback target.

---

## About Audio Playback

BeatClikrNative.iOS uses **AVFoundation** for sound playback. WAV files are read into `AVAudioPCMBuffer`s and played through `AVAudioPlayerNode`s connected to an `AVAudioEngine` mixer. The metronome and polyrhythm engines are separate instances, but both use the same scheduled-buffer approach.

### Sound Architecture
- WAV files are loaded as `AVAudioFile`s and converted into reusable `AVAudioPCMBuffer`s
- Beat and rhythm sounds are scheduled on separate player nodes
- Beat vs. rhythm buffers are selected based on the subdivision counter or accent pattern
- Metronome and polyrhythm sound choices are loaded independently through `AudioPlayerService`
- Supports instant sound switching without interrupting playback for the metronome path

### Alternate Sixteenth Notes

When **Alternate Sixteenth Notes** is enabled and the sixteenth note groove is selected, beat and rhythm sounds alternate across each group of four subdivisions:

| Position | Counted as | Sound |
|----------|------------|-------|
| 1st (counter 0) | Downbeat | Beat |
| 2nd (counter 1) | "e" | Rhythm |
| 3rd (counter 2) | "and" | Beat |
| 4th (counter 3) | "ah" | Rhythm |

This gives an eighth-note pulse within the sixteenth pattern — useful for feeling the strong subdivisions at both the downbeat and the "and". When the setting is off, only the downbeat plays the beat sound and the remaining three play the rhythm sound (the default for all other grooves).

The visual animation, haptic feedback, and flashlight always pulse only on the downbeat (counter 0) regardless of this setting.

---

## About Odd Meter (Accented Patterns)

The **Odd Quarter** and **Odd Eighth** grooves support asymmetric meters like 5/8, 7/8, 9/8, 11/8, 13/8, and 15/8 via a `BeatPattern` that encodes how subdivisions are grouped.

### How BeatPattern works

A `BeatPattern` raw value is a comma-separated list of group sizes, e.g. `"3,2,2"` for 7/8. Its `accentArray` property converts this into a flat `[Bool]` array where `true` marks the first tick of each group:

```
"3,2,2"  →  [true, false, false, true, false, true, false]
```

This array is passed to `ScheduledMetronomeEngine` as the `accentPattern`. The engine steps through it on every subdivision tick: a `true` entry schedules the beat buffer and schedules an `isBeat: true` delegate event; a `false` entry schedules the rhythm buffer and schedules an `isBeat: false` delegate event.

### Subdivision rate

- **Odd Quarter** (`subdivisions = 1`): one tick per quarter note. Use for meters where the quarter note is the pulse (e.g. 7/4 felt as 3+2+2 quarters)
- **Odd Eighth** (`subdivisions = 2`): two ticks per quarter note. Use for meters where the eighth note is the pulse (e.g. 7/8 felt as 3+2+2 eighths)

### Beat interval and animation

When the engine schedules an accented beat (`isBeat: true`), it looks ahead in the pattern to compute how long until the *next* accented beat and passes that as `beatInterval` to the delegate:

```
beatInterval = ticksToNextBeat × subdivisionDuration
```

For a 7/8 (3+2+2) pattern at 120 BPM with Odd Eighth:
- Subdivision duration = 60 / (120 × 2) = 250 ms
- Beat 1 (group of 3): beatInterval = 3 × 250 ms = **750 ms**
- Beat 2 (group of 2): beatInterval = 2 × 250 ms = **500 ms**
- Beat 3 (group of 2): beatInterval = 2 × 250 ms = **500 ms**

`MetronomePlaybackViewModel` uses `beatInterval` as the animation duration for `iconScale` and `beatPulse`, so animations match the feel of each rhythmic group rather than a fixed quarter note.

---

## About Polyrhythm

Polyrhythm mode layers two independent rhythms at the same tempo: **M beats against N** (each 1–9). Both complete one cycle in the same total duration — N quarter notes.

### Independent track scheduling

`ScheduledPolyrhythmEngine` schedules the beat and rhythm as two independent tracks that share the same first-beat origin:

```
Cycle duration        = N × (60 / bpm)
Beat interval         = 60 / bpm
Rhythm interval       = Cycle duration / M
Shared origin         = firstBeatDelay on the AVAudioEngine sample timeline
```

**Example — 3 against 2 at 60 BPM:**
- Cycle = 2 quarter notes = 2.0 s
- Beat track fires every 1.0 s → 2 times per cycle
- Rhythm track fires every 2.0 / 3 ≈ 666.7 ms → 3 times per cycle
- Both tracks schedule their first buffer at the same sample-time origin

The engine schedules `polyrhythmBeatFired(beatFired:rhythmFired:beatIndex:rhythmIndex:)` from the same sample-time positions used for each track's audio buffers. Buffer completion callbacks are only used to refill each track's lookahead window. Because both tracks are scheduled on the same audio sample timeline, simultaneous hits (for example, the downbeat) remain aligned without buffer-mixing code.

### Visual dot rows

`PolyrhythmView` shows three rows, each spanning the full cycle width as a proportional timeline:
- **Beat row** — N dots spaced proportionally; the active dot lights up when the beat fires
- **Rhythm row** — M dots spaced proportionally; the active dot lights up when the rhythm fires
- **Playhead row** — a single orange dot that traverses the full cycle from left to right, restarting at each downbeat

Each dot row uses `HStack(spacing: 0)` with `Spacer(minLength: 0)` between dots so positions are proportional to their time in the cycle. Each dot sits centered on a `Capsule` background line to form a unified timeline metaphor.

Pulse values (`beatPulse` / `rhythmPulse`) snap to 1.0 on firing and fade linearly to 0.0:
- Beat pulse fades over one quarter note: `60 / bpm`
- Rhythm pulse fades over one rhythm interval: `against × (60 / bpm) / beats`

The active dot indices, pulses, and `cycleProgress` are all stored in `PolyrhythmViewModel`.

---

## Tap Tempo

The Instant Metronome includes a **Tap Tempo** button displayed as a circle to the right of the BPM display. Tapping it calculates BPM from the average interval of the last several taps. The result is rounded to one decimal place and clamped to the app's min/max BPM range. If more than 2 seconds pass between taps, the tap history is cleared so the user can start a new tempo.
