# Services

## Service Classes

- **AudioKitMetronomeEngine** - Sample-accurate metronome using AudioKit's AppleSampler. For odd meter grooves, steps through a `[Bool]` accent pattern on every subdivision tick and computes `beatInterval` (time to the next `true` entry) so the delegate can animate each group correctly

- **AudioKitPolyrhythmEngine** - Polyrhythm engine using a least-common-multiple grid. For M beats against N: cycle = N quarter notes; grid = LCM(M, N) equal steps; beat fires every LCM/N steps; rhythm fires every LCM/M steps. Step duration = N × (60/bpm) / LCM. Fires `polyrhythmBeatFired` with `beatFired`, `rhythmFired`, `beatIndex` (0..<N), and `rhythmIndex` (0..<M) so the view can animate individual dots independently

- **AudioPlayerService** - Singleton wrapper that owns both `AudioKitMetronomeEngine` and `AudioKitPolyrhythmEngine` (they share the same `AppleSampler`). Forwards delegate callbacks to `MetronomePlaybackViewModel` (via `delegate`) and `PolyrhythmViewModel` (via `polyrhythmDelegate`). Manages loading WAV files, configuring the audio engine, mapping user instrument preferences to MIDI notes, and real-time tempo/subdivision updates

- **FlashlightService** - Controls device flashlight for visual beat accessibility

- **VibrationService** - Manages haptic feedback via `UIImpactFeedbackGenerator`

- **UserDefaultsService** - Persists user preferences to both `UserDefaults.standard` and `NSUbiquitousKeyValueStore` for cross-device sync. Observes `didChangeExternallyNotification` to pull in changes from other devices. Exposes an `onSendRemindersEnabled` callback that fires when `sendReminders` transitions `false → true` via cloud sync, so `SettingsViewModel` can respond without coupling the two layers with Combine

- **ReminderNotificationService** - Manages `UNUserNotificationCenter` authorization and scheduling; schedules 7 individual ahead-of-time notifications (one per upcoming day) with pre-computed personalized bodies; caches the last set of bodies so time-change reschedules don't require a new body computation; exposes `currentAuthorizationStatus()` for non-prompting status checks

---

## About Keeping Time

Sample-accurate timing is critical for a metronome. The current implementation uses **AudioKit's AppleSampler** with **CFAbsoluteTime** for high-precision beat scheduling.

### How it works

`AudioKitMetronomeEngine` uses a polling approach with extremely tight tolerances:

```
Check Interval:      1ms (0.001s)
First Beat Delay:   67ms (ensures timer is running before first beat)
Lookahead Tolerance: 2ms (fires beat slightly early to account for processing)
```

**Example with 100 BPM, 8th note subdivisions:**
- Subdivision duration: 60 / (100 BPM × 2 subdivisions) = 300 ms
- Timer checks every 1ms to see if it's within 2ms of the next beat
- When threshold is met, plays the appropriate sound and notifies the delegate

This approach provides:
- **<5ms jitter** — beats stay locked to the tempo
- **No drift** — uses absolute time rather than cumulative intervals
- **Real-time tempo changes** — BPM/subdivisions can update while playing
- **Simulator & device support** — works reliably on all platforms

### Delegate Pattern

`MetronomePlaybackViewModel` implements `MetronomeAudioEngineDelegate` to receive beat callbacks:
- Triggers visual animations (icon scale, beat pulse for transport bar)
- Fires haptic feedback via `VibrationService`
- Controls flashlight via `FlashlightService`
- All synchronized to the audio engine's timing

---

## About Audio Playback

BeatClikrNative.iOS relies on **AudioKit** for sound playback via **AVAudioUnitSampler** (the same technology as GarageBand's soft instruments and Logic's EXS24 sampler).

### Sound Architecture
- WAV files are loaded into the AppleSampler at startup
- Each sound is mapped to a MIDI note number
- Beat vs. rhythm sounds are selected based on the subdivision counter
- Supports instant sound switching without interrupting playback (Instant Metronome only)

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

This array is passed to `AudioKitMetronomeEngine` as the `accentPattern`. The engine steps through it on every subdivision tick: a `true` entry triggers the beat sound and fires `isBeat: true`; a `false` entry triggers the rhythm sound and fires `isBeat: false`.

### Subdivision rate

- **Odd Quarter** (`subdivisions = 1`): one tick per quarter note. Use for meters where the quarter note is the pulse (e.g. 7/4 felt as 3+2+2 quarters)
- **Odd Eighth** (`subdivisions = 2`): two ticks per quarter note. Use for meters where the eighth note is the pulse (e.g. 7/8 felt as 3+2+2 eighths)

### Beat interval and animation

When the engine fires an accented beat (`isBeat: true`), it looks ahead in the pattern to compute how long until the *next* accented beat and passes that as `beatInterval` to the delegate:

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

### LCM grid approach

`AudioKitPolyrhythmEngine` computes the least common multiple of M and N to create a fine grid that aligns both rhythms exactly:

```
Grid steps per cycle  = LCM(M, N)
Beat fires every      = LCM / N  steps  (fires N times per cycle)
Rhythm fires every    = LCM / M  steps  (fires M times per cycle)
Step duration         = N × (60 / bpm) / LCM
```

**Example — 3 against 2 at 60 BPM:**
- LCM(3, 2) = 6 grid steps
- Beat fires every 3 steps → 2 times per cycle
- Rhythm fires every 2 steps → 3 times per cycle
- Cycle = 2.0 s; step duration ≈ 333 ms

The engine fires `polyrhythmBeatFired(beatFired:rhythmFired:beatIndex:rhythmIndex:)` at every grid step where at least one rhythm lands. Both can fire simultaneously on a shared step (e.g. the downbeat at step 0).

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
