# Services

## Service Classes

- **ScheduledMetronomeEngine** - Sample-accurate metronome using `AVAudioEngine` and rolling `AVAudioPlayerNode` blocks. Stable playback renders a quarter-note or odd-meter block from independently rounded absolute sample positions into a reusable pool; scheduled slots remain immutable until consumed. Tempo ramps use the immutable per-click fallback. The engine exposes rendered playback time and schedules generation-scoped callbacks from the same absolute event positions.

- **ScheduledPolyrhythmEngine** - Renders both voices of an M:N polyrhythm into rolling cycle blocks from one absolute sample origin. Independently rounded cycle boundaries prevent cumulative phase error. Rendered playback time, event callbacks, and both voices share that origin, so visual phase and audio reunite at every cycle boundary.

- **AudioPlayerService** - `@MainActor` implementation of the injectable `AudioPlaybackService` protocol. It owns one `ScheduledMetronomeEngine` and one `ScheduledPolyrhythmEngine`, but prepares each engine lazily. Audio-session setup, sound loading, conversion, configuration, and engine start report typed `PlaybackError` failures rather than being swallowed. Metronome and polyrhythm sound loading remain separate so each mode keeps its own selected instruments.

- **PlaybackCoordinator** - The single app-level owner of `AudioPlayerService`.
  Both playback view models receive this coordinator rather than accessing the
  singleton directly. Starting metronome playback stops and invalidates
  polyrhythm playback first, and vice versa. Displaced owners are notified so
  their published state and animations return to idle synchronously.

- **PersistenceRepository** - Generic SwiftData fetch/save boundary returning
  typed failures and rolling back failed saves.

- **PracticeHistoryRepository** - Practice-domain repository built on the
  generic persistence boundary. Practice views do not perform saves directly.

### Playback navigation policy

- Changing a top-level tab/sidebar section stops all playback.
- Changing the compact metronome/polyrhythm mode stops the mode being hidden.
- Navigation-stack pushes and sheets within the Library or Playlist section do
  not stop playback; transport continues until the user stops it or leaves the
  top-level section.
- Presenting editing, picker, or Focus Mode UI does not implicitly stop audio.

### Background and lock-screen policy

- Active metronome or polyrhythm playback continues when BeatClikr enters the
  background or the device locks. The `audio` background mode owns that
  behavior; the separate `remote-notification` mode belongs to CloudKit
  synchronization. Entering the background does not start audio.
- Returning to the foreground preserves the current playback state. Normal
  audio interruptions and unavailable output routes still stop playback and
  require the user to press Play again.
- During playback, BeatClikr publishes minimal Now Playing metadata and enables
  the lock-screen and Control Center Pause/Stop commands. Both commands stop
  the active mode and return its UI to idle. The static app display image is
  supplied as Now Playing artwork without an asynchronous image provider.
  Stop-capable commands are enabled for each playback session and disabled
  again on stop, so repeated
  start-lock-stop cycles do not leave stale controls. If iOS presents a
  Play-shaped button in the transport slot, it also stops current playback; it
  never restarts audio. Seeking, skipping, playback-rate changes, and track
  navigation remain disabled because they are not meaningful for a metronome.
- “Keep Awake” remains an optional visual-performance preference for users who
  want the beat display to remain visible. Background audio does not depend on
  it, and the idle-timer override is removed whenever the scene is not active.
- A custom Live Activity remains a possible future replacement for the
  system-owned Now Playing presentation. The current media control favors
  reliable stop access over a guaranteed transport glyph.

- **FlashlightService** - Controls device flashlight for visual beat accessibility

- **VibrationService** - Manages haptic feedback via `UIImpactFeedbackGenerator`

- **UserDefaultsService** - Persists user preferences to both `UserDefaults.standard` and `NSUbiquitousKeyValueStore` for cross-device sync. Observes `didChangeExternallyNotification` to pull in changes from other devices. Exposes an `onSendRemindersEnabled` callback that fires when `sendReminders` transitions `false → true` via cloud sync, so `SettingsViewModel` can respond without coupling the two layers with Combine

- **ReminderNotificationService** - Manages `UNUserNotificationCenter` authorization and deterministic scheduling. `ReminderPlan` describes 7 concrete future occurrences with explicit identifiers, dates, personalized bodies, and the current-local-time-zone policy. Replacing a schedule awaits every add and verifies that the notification center retained the complete plan; partial or failed plans are removed and surfaced to the settings UI. Plans are rebuilt from current settings and practice history instead of relying on hidden cached bodies.

---

## About Keeping Time

Sample-accurate timing is critical for a metronome. The current implementation uses `AVAudioEngine` with scheduled `AVAudioPlayerNode` buffers so audio timing is handled on the audio render timeline rather than by main-thread timers.

### How it works

For stable tempos, `ScheduledMetronomeEngine` renders complete musical blocks into a reusable audio-buffer pool and pre-schedules those blocks with matching delegate events:

```
First Beat Delay:   67ms (gives the scheduler time to queue initial buffers)
Schedule Ahead:     4 short blocks, or 2 blocks when a block exceeds 1 second
Clock Source:       One absolute sample origin on the engine output sample rate
```

**Example with 100 BPM, 8th note subdivisions:**
- Subdivision duration: 60 / (100 BPM × 2 subdivisions) = 300 ms
- The engine independently rounds every event and block boundary from the absolute origin
- Complete quarter-note/odd-meter blocks are mixed before scheduling
- Delegate callbacks are scheduled against the same sample-time positions as playback and carry playback-generation identity
- A `.dataRendered` completion callback returns an entire rendered block—not an individual click—to the pool
- A pool slot is never changed while `AVAudioPlayerNode` may still own it

This approach provides:
- **Hardware-timeline timing** — beats are scheduled on the audio engine sample clock
- **No main-thread polling jitter** — playback does not depend on a 1 ms timer
- **No drift** — fractional samples are distributed through independently rounded absolute boundaries instead of cumulative truncation
- **Onset-aligned events** — callbacks are timed to the scheduled beat position rather than the end of a buffer; visuals then evolve from rendered playback time, while haptic and flashlight effects remain best effort
- **Bounded rendering work** — stable playback refills once per musical block and allocates no buffers after preparing the pool
- **Ramp fallback** — changing-tempo ramps retain the immutable per-click scheduler because a static musical block cannot encode a changing BPM
- **Simulator & device support** — works reliably on all platforms

The block timeline always uses the current engine output sample rate. If loaded
samples no longer match that format, playback fails safely. Route,
configuration, and media-service changes invalidate the engine graph; the next
explicit user start rebuilds it and reloads/reconverts the selected sounds.

### Delegate Pattern

`MetronomePlaybackViewModel` implements `MetronomeAudioEngineDelegate` to receive beat callbacks:
- Anchors visual beat phase; a `CADisplayLink` reads rendered playback time to update icon scale and transport pulse without accumulating a separate clock
- Fires haptic feedback via `VibrationService`
- Controls flashlight via `FlashlightService`
- Applies ramped BPM updates when `metronomeRampStepped(newBpm:)` fires
- Discards stale callbacks by playback generation

`PolyrhythmViewModel` implements `PolyrhythmAudioEngineDelegate` through `AudioPlayerService.polyrhythmDelegate`. The service keeps this separate from `metronomeDelegate` so metronome and polyrhythm screens do not overwrite each other's callback target.

---

## About Audio Playback

BeatClikrNative.iOS uses **AVFoundation** for sound playback. WAV files are read into `AVAudioPCMBuffer`s and played through `AVAudioPlayerNode`s connected to an `AVAudioEngine` mixer. The metronome and polyrhythm engines are separate instances, but both use the same scheduled-buffer approach.

### Sound Architecture
- WAV files are loaded as `AVAudioFile`s and converted into reusable `AVAudioPCMBuffer`s
- Loaded sample buffers are immutable. When a click is longer than its scheduling interval, `AudioBufferClipCache` creates and reuses a separate immutable clip for that frame length; scheduled buffers are never shortened in place. Each source uses least-recently-used eviction with a 2 MiB derived-buffer budget and a secondary 16-entry limit, so repeated tempo changes cannot grow memory without bound
- Stable beat and rhythm sounds are mixed into rolling musical blocks; the ramp fallback schedules immutable click clips
- Beat vs. rhythm samples are selected based on absolute event indices and the accent pattern
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

`MetronomePlaybackViewModel` uses `beatInterval` to define the group’s visual phase, but elapsed phase comes from the engine’s rendered playback position. This keeps the icon and pulse aligned to differently sized groups without accumulating callback or cycle drift.

---

## About Polyrhythm

Polyrhythm mode layers two independent rhythms at the same tempo: **M beats against N** (each 1–15). Both complete one cycle in the same total duration — N quarter notes.

### Shared-cycle rendering

`ScheduledPolyrhythmEngine` renders beat and rhythm events into one cycle block from a shared first-beat origin:

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

The engine schedules `polyrhythmBeatFired(beatFired:rhythmFired:beatIndex:rhythmIndex:)` from the same absolute sample positions used to mix the audio block. Each cycle boundary is independently rounded from the origin, so fractional cycle lengths alternate by one sample when necessary instead of accumulating phase error. Beat and rhythm downbeats therefore reunite at every cycle boundary.

### Visual dot rows

`PolyrhythmView` shows three rows, each spanning the full cycle width as a proportional timeline:
- **Beat row** — N dots spaced proportionally; the active dot lights up when the beat fires
- **Rhythm row** — M dots spaced proportionally; the active dot lights up when the rhythm fires
- **Playhead row** — a single orange dot that traverses the full cycle from left to right, restarting at each downbeat

Each dot row uses `HStack(spacing: 0)` with `Spacer(minLength: 0)` between dots so positions are proportional to their time in the cycle. Each dot sits centered on a `Capsule` background line to form a unified timeline metaphor.

Callbacks anchor each pulse and cycle boundary. A `CADisplayLink` evaluates elapsed phase from rendered playback time; when playback time is temporarily unavailable, it extrapolates from the last valid audio position rather than starting an unrelated long-running clock. Pulse values (`beatPulse` / `rhythmPulse`) fade linearly:
- Beat pulse fades over one quarter note: `60 / bpm`
- Rhythm pulse fades over one rhythm interval: `against × (60 / bpm) / beats`

The active dot indices, pulses, and `cycleProgress` are published by `PolyrhythmViewModel`. Reduce Motion suppresses pulse and traversing-cycle animation without changing the audio timeline.

---

## Audio lifecycle policy

`AudioSessionCoordinator` owns audio-session activation and observes interruptions, output-route disconnection, engine configuration changes, and media-services loss/reset.

BeatClikr never resumes playback automatically after a lifecycle event. It stops both engines, clears the active playback mode, stops visual/effect activity, and reports the active view model as `interrupted`. The user must press Play to begin a new session. Engine configuration and media-service events also discard both engine graphs; the next user-initiated start rebuilds the engines and reloads the selected immutable sounds.

This conservative policy prevents unexpected playback after a call, Siri interaction, device unplug, or output-route change.

### Mixing and output-route policy

- BeatClikr uses the `.playback` audio-session category with `.mixWithOthers`.
  Music, videos, and backing tracks from other apps therefore continue playing
  when the metronome starts. BeatClikr does not duck their volume.
- Mixing is the sole supported policy; there is no exclusive-audio setting.
- The active output route is written to the AudioSession system log when the
  session activates and when an old output becomes unavailable.
- Bluetooth output adds device-, codec-, and route-dependent latency. The
  metronome remains internally sample-accurate, but its audible click can lag
  visuals, haptics, or flashlight feedback by the route’s transport latency.
  Built-in speakers or wired audio are recommended when audiovisual alignment
  matters.
- Haptic and flashlight feedback are foreground-only, best-effort effects.
  Their callbacks are tied to a playback generation and are discarded after a
  stop, restart, interruption, failure, or background transition. They are not
  sample-accurate and must not be used to judge audio timing.

## Tap Tempo

The Instant Metronome includes a **Tap Tempo** button displayed as a circle to the right of the BPM display. Tapping it calculates BPM from the average interval of the last several taps. The result is rounded to one decimal place and clamped to the app's min/max BPM range. If more than 2 seconds pass between taps, the tap history is cleared so the user can start a new tempo.
