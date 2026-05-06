# BeatClikrNative.iOS
BeatClikr's reimplementation for iOS 18+ with SwiftUI, SwiftData, AudioKit, and iCloud sync. Available on the App Store.

## What's New

### Streak Sharing
The Practice History tab now has a **Share** button in the navigation bar. Tapping it renders a `SharableStreakCard` — a 360×360 image showing the current streak count, the BeatClikr app icon, and a gradient background — and opens the system share sheet with pre-written text. The share text adapts based on whether the user has an active current streak, a past longest streak, or neither.

### Liquid Glass App Icon (iOS 26+)
The app now includes `BeatClikrAppIcon.icon`, a multilayer Icon Composer file that provides a Liquid Glass app icon for iOS 26 and later. The icon has a blue gradient background in light mode and automatically adapts to a dark background in dark mode. Xcode generates a static fallback from the same file for iOS 18–25 at build time.

Note: This project relies on a series of .WAV files that are not in git. You will need to add these yourself:

- WAV files go with their correct names in Resources/Sounds
- See Constants/FileConstants for the correct WAV filenames

The WAV files are proprietary and I recorded them myself. You're free to use this code, but you'll need your own media files. :D 

## Architecture Overview

BeatClikr follows an MVVM architecture with a clean separation of concerns:

### Models
- **Song** - SwiftData model for song storage (title, artist, BPM, time signature, groove)
- **Playlist** - SwiftData model for a named playlist
- **PlaylistEntry** - SwiftData model for ordered playlist entries (linked to Song, with sequence index)
- **PracticeSession** - SwiftData model for a single day's practice session; owns a list of `PracticedSong` records
- **PracticedSong** - SwiftData model recording a song's title, BPM, groove, and play count within a session
- **Groove** - Enum defining subdivision types: `quarter` (1), `eighth` (2), `triplet` (3), `sixteenth` (4), `oddMeterQuarter` (1 subdivision, accent-driven), `oddMeterEighth` (2 subdivisions, accent-driven). The `isOddMeter` property is true for the last two; `subdivisions` returns the number of ticks per beat used by the audio engine
- **BeatPattern** - Enum encoding odd-meter accent groups as a comma-separated string raw value (e.g. `"3,2,2"` for 7/8). The `accentArray` computed property converts this to `[Bool]` where `true` marks the first tick of each group and `false` fills the remaining ticks — e.g. `"3,2,2"` → `[true, false, false, true, false, true, false]`. Patterns cover 5/8 through 15/8
- **ClickerType** - Enum distinguishing instant vs. playlist metronome modes

### ViewModels (EnvironmentObjects)
- **MetronomePlaybackViewModel** - Orchestrates metronome playback, coordinates services, handles UI state (`iconScale`, `beatPulse`, `isPlaying`). Receives `metronomeBeatFired(isBeat:beatInterval:)` callbacks and animates the metronome icon and beat pulse over exactly `beatInterval` seconds — the engine-computed time to the next accented beat — so animations stay in sync with the actual rhythmic group length rather than always using a fixed quarter-note duration
- **PolyrhythmViewModel** - Manages polyrhythm mode state: the M:N ratio (`beats` and `against`, each 1–9), BPM (persisted to `UserDefaults` and synced via iCloud KV store), sound selection, and per-row dot animations (`beatPulse`/`rhythmPulse`, `activeBeatIndex`/`activeRhythmIndex`). Receives `polyrhythmBeatFired` callbacks and fades each row's pulse over the appropriate interval: quarter-note duration for the beat row, rhythmInterval (`against × quarterNote / beats`) for the rhythm row. Also publishes `cycleProgress` (0→1 animated over each full cycle) for the playhead row
- **SettingsViewModel** - Manages user preferences and notification permission state. Maintains three separate permission states: `notificationsBlockedLocally` (system denied), `notificationsDeferredLocally` (user tapped "Not Now" on the cross-device pre-prompt), and `showCrossDeviceReminderPrompt` (undetermined, needs to ask). Delegates all scheduling to `ReminderNotificationService`; see *Cross-Device Notification Permissions* below
- **SongLibraryViewModel** - Handles song library CRUD operations and playback
- **PlaylistListViewModel** - Manages the list of playlists (create, delete)
- **PlaylistDetailViewModel** - Manages playlist sequencing (next/previous/play), edit, reorder, and delete operations for a single playlist
- **PracticeHistoryViewModel** - Records songs played per day (`recordSongPlayed`); publishes `practiceDates` (`Set<Date>`) and `selectedDateSongs` (`[PracticedSong]`) as observable state; exposes computed properties for current/longest streak values, subtitles, reminder flag, and share text so views contain no streak logic; generates personalized notification bodies projected across future days; exposes an `onPracticeRecorded` callback invoked after each save so the app can immediately reschedule notifications

### Views
- **HomeView** - Root container; uses `TabView` on iPhone and `NavigationSplitView` on iPad/Mac; sections: Instant, Library, Playlists, History, Settings. Hosts root-level alerts for notification permission flows (`showPermissionDeniedAlert`, `showCrossDeviceReminderPrompt`) so they surface regardless of which tab is active
- **MetronomeContainerView** - iPhone-only container that hosts Instant and Polyrhythm as a segmented-control top tab inside a single `NavigationStack`, so both modes share one bottom tab
- **InstantMetronomeView** - Standalone metronome with live BPM/groove controls and tap tempo; when an odd meter groove is selected, also shows a `BeatPattern` picker
- **SongLibraryView** - Browsable song list; tap to play, swipe or edit to delete, + to add
- **PlaylistListView** - List of all named playlists; tap to open, swipe to delete, + to create
- **PlaylistDetailView** - Ordered playlist with inline edit/reorder; shows transport bar when playing
- **PracticeHistoryView** - Calendar showing days on which practice was recorded; tap a day to see details; share button renders a `SharableStreakCard` and opens the system share sheet
- **SongDetailsView** - Add or edit a song's metadata
- **SettingsView** - App-wide preferences (sounds, haptics, flashlight, keep-awake, practice reminders). Shows an inline warning below the reminders toggle when notifications are blocked or deferred on this device, with context-appropriate actions: "Open Settings" for denied permissions, "Enable" to trigger the system prompt when previously deferred

### Custom Views
- **CalendarView** - Monthly calendar grid with marked-date dots and tap-to-select; accepts a `Set<Date>` of marked days and a `Binding<Date?>` for the selected date
- **PlaylistTransportView** - Floating Previous / Stop / Next transport bar shown at the bottom of Playlist mode while a song is active; pulses with the beat
- **SongPickerView** - Sheet for picking a library song to add to the playlist
- **SongListItemView** - Reusable list row showing title, artist, BPM, and groove
- **MetronomePlayerView** - Compact animated metronome indicator used in toolbars
- **SharableStreakCard** - 360×360 shareable image card showing the streak count with the app icon and a black-to-blue gradient; rendered off-screen via `ImageRenderer` for the share sheet

### Services Layer
- **AudioKitMetronomeEngine** - Sample-accurate metronome using AudioKit's AppleSampler. For odd meter grooves, steps through a `[Bool]` accent pattern on every subdivision tick and computes `beatInterval` (time to the next `true` entry) so the delegate can animate each group correctly
- **AudioKitPolyrhythmEngine** - Polyrhythm engine using a least-common-multiple grid. For M beats against N: cycle = N quarter notes; grid = LCM(M, N) equal steps; beat fires every LCM/N steps; rhythm fires every LCM/M steps. Step duration = N × (60/bpm) / LCM. Fires `polyrhythmBeatFired` with `beatFired`, `rhythmFired`, `beatIndex` (0..<N), and `rhythmIndex` (0..<M) so the view can animate individual dots independently
- **AudioPlayerService** - Singleton wrapper that owns both `AudioKitMetronomeEngine` and `AudioKitPolyrhythmEngine` (they share the same `AppleSampler`). Forwards delegate callbacks to `MetronomePlaybackViewModel` (via `delegate`) and `PolyrhythmViewModel` (via `polyrhythmDelegate`)
- **FlashlightService** - Controls device flashlight for visual accessibility
- **VibrationService** - Manages haptic feedback (UIImpactFeedbackGenerator)
- **UserDefaultsService** - Persists user preferences to both `UserDefaults.standard` and `NSUbiquitousKeyValueStore` for cross-device sync. Observes `didChangeExternallyNotification` to pull in changes from other devices. Exposes an `onSendRemindersEnabled` callback that fires when `sendReminders` transitions `false → true` via cloud sync, so `SettingsViewModel` can respond without coupling the two layers with Combine
- **ReminderNotificationService** - Manages `UNUserNotificationCenter` authorization and scheduling; schedules 7 individual ahead-of-time notifications (one per upcoming day) with pre-computed personalized bodies; caches the last set of bodies so time-change reschedules don't require a new body computation; exposes `currentAuthorizationStatus()` for non-prompting status checks

### Helpers
- **PreviewContainer** - SwiftData `ModelContainer` wrapper for Xcode previews; provides `addMockSongs()`, `addMockPlaylistEntries(for:)`, and `addMockPracticeHistory()` so previews across views share consistent sample data

### Constants
- **MetronomeConstants** - Timing parameters, BPM ranges, animation values, tolerance thresholds
- **ImageConstants** - Asset references for UI elements
- **PreferenceKeys** - String constants for all `UserDefaults` and `NSUbiquitousKeyValueStore` keys, divided into two groups: *Synced* (written to both stores) and *Local only* (never synced to cloud)
- **FileConstants** - Enum mapping sound file names to their audio files and MIDI notes — your files need to match these names

## About Keeping Time

Sample-accurate timing is critical for a metronome. The current implementation uses **AudioKit's AppleSampler** with **CFAbsoluteTime** for high-precision beat scheduling.

### How it works:

The `AudioKitMetronomeEngine` uses a polling approach with extremely tight tolerances:

```
Check Interval: 1ms (0.001s)
First Beat Delay: 67ms (ensures timer is running before first beat)
Lookahead Tolerance: 2ms (fires beat slightly early to account for processing)
```

**Example with 100 BPM, 8th note subdivisions:**
- Subdivision duration: 60 / (100 BPM × 2 subdivisions) = 300 milliseconds
- Timer checks every 1ms to see if it's within 2ms of the next beat
- When threshold is met, plays the appropriate sound (beat or rhythm) and notifies delegate

This approach provides:
- **<5ms jitter** - beats stay locked to the tempo
- **No drift** - uses absolute time rather than cumulative intervals
- **Real-time tempo changes** - can update BPM/subdivisions while playing
- **Simulator & device support** - works reliably on all platforms

### Delegate Pattern

The `MetronomePlaybackViewModel` implements `MetronomeAudioEngineDelegate` to receive beat callbacks:
- Triggers visual animations (icon scale transitions, beat pulse for transport bar)
- Fires haptic feedback via VibrationService
- Controls flashlight via FlashlightService
- All synchronized to the audio engine's timing

## About Audio Playback

BeatClikrNative.iOS relies on **AudioKit** for sound playback. It provides a high-level interface to **AVAudioUnitSampler** (same basic technology as GarageBand's soft instruments and Logic's EXS24 sampler).

### Sound Architecture:
- WAV files are loaded into the AppleSampler at startup
- Each sound is mapped to a MIDI note number
- Beat vs. rhythm (subdivision) sounds are played based on subdivision counter
- Supports instant sound switching without interrupting playback (Instant Metronome only)

### Alternate Sixteenth Notes

When the **Alternate Sixteenth Notes** setting is enabled and the sixteenth note groove is selected, the beat and rhythm sounds alternate across each group of four subdivisions:

| Position | Counted as | Sound |
|----------|-----------|-------|
| 1st (counter 0) | Downbeat | Beat |
| 2nd (counter 1) | "e" | Rhythm |
| 3rd (counter 2) | "and" | Beat |
| 4th (counter 3) | "ah" | Rhythm |

This gives an eighth-note pulse within the sixteenth pattern — useful for feeling the strong subdivisions at both the downbeat and the "and". When the setting is off, only the downbeat plays the beat sound and the remaining three subdivisions play the rhythm sound (the default behavior for all other grooves).

The visual circle animation, haptic feedback, and flashlight always pulse only on the downbeat (counter 0) regardless of this setting.

The `AudioPlayerService` manages:
- Loading audio files from the bundle
- Configuring the audio engine
- Mapping user preferences (beat/rhythm selection) to the correct MIDI notes
- Starting/stopping the metronome
- Real-time tempo and subdivision updates

## About Odd Meter (Accented Patterns)

The **Odd Quarter** and **Odd Eighth** grooves let the user play in asymmetric meters like 5/8, 7/8, 9/8, 11/8, 13/8, and 15/8. The meter is defined by a `BeatPattern` that describes how the total subdivisions are grouped.

### How BeatPattern works

A `BeatPattern` raw value is a comma-separated list of group sizes, e.g. `"3,2,2"` for 7/8. Its `accentArray` property converts this into a flat `[Bool]` array where `true` marks the first tick of each group:

```
"3,2,2"  →  [true, false, false, true, false, true, false]
```

This array is passed directly to `AudioKitMetronomeEngine` as the `accentPattern`. The engine steps through it on every subdivision tick: a `true` entry triggers the beat sound and fires `isBeat: true` to the delegate; a `false` entry triggers the rhythm (subdivision) sound and fires `isBeat: false`.

### Subdivision rate

- **Odd Quarter** (`subdivisions = 1`): one tick per quarter note. Accent groups are counted in quarter notes. Use this for meters where the quarter note is the pulse (e.g. 7/4 felt as 3+2+2 quarters).
- **Odd Eighth** (`subdivisions = 2`): two ticks per quarter note (eighth-note grid). Accent groups are counted in eighth notes. Use this for meters where the eighth note is the pulse (e.g. 7/8 felt as 3+2+2 eighths).

### Beat interval and animation

When the engine fires an accented beat (`isBeat: true`), it looks ahead in the pattern to count how many subdivision ticks remain until the *next* accented beat, then passes that duration as `beatInterval` to the delegate:

```
beatInterval = ticksToNextBeat × subdivisionDuration
```

For a 7/8 (3+2+2) pattern at 120 BPM with Odd Eighth:
- Subdivision duration = 60 / (120 × 2) = 250 ms
- Beat 1 (group of 3): beatInterval = 3 × 250 ms = **750 ms**
- Beat 2 (group of 2): beatInterval = 2 × 250 ms = **500 ms**
- Beat 3 (group of 2): beatInterval = 2 × 250 ms = **500 ms**

`MetronomePlaybackViewModel` uses `beatInterval` as the animation duration for both `iconScale` and `beatPulse`, so the metronome icon and any pulsing views expand at each beat and fade out over exactly the time until the next beat — matching the feel of the rhythmic group rather than a fixed quarter note.

For regular grooves (no accent pattern), `beatInterval` is always `60 / bpm` (one quarter note), so the behavior is identical to before.

## About Polyrhythm

The Polyrhythm mode lets the user layer two independent rhythms at the same tempo: **M beats against N** (each 1–9). Both rhythms complete one cycle in the same total duration — N quarter notes.

### LCM grid approach

`AudioKitPolyrhythmEngine` computes the least common multiple of M and N to create a fine grid of equal time steps that aligns both rhythms exactly:

```
Grid steps per cycle  = LCM(M, N)
Beat fires every      = LCM / N  steps  (fires N times per cycle)
Rhythm fires every    = LCM / M  steps  (fires M times per cycle)
Step duration         = N × (60 / bpm) / LCM
```

**Example — 3 against 2 at 60 BPM:**
- LCM(3, 2) = 6 grid steps
- Beat fires every 3 steps → 2 times per cycle (against = 2)
- Rhythm fires every 2 steps → 3 times per cycle (beats = 3)
- Cycle = 2 × 1.0 s = 2.0 s; step duration = 2.0 / 6 ≈ 333 ms

The engine fires `polyrhythmBeatFired(beatFired:rhythmFired:beatIndex:rhythmIndex:)` at every grid step where at least one rhythm lands. Both can fire simultaneously on a shared step (e.g. the downbeat at step 0).

### Visual dot rows

`PolyrhythmView` shows three rows, each spanning the full cycle width as a proportional timeline:
- **Beat row** — N dots spaced proportionally; the active dot lights up when the beat fires
- **Rhythm row** — M dots spaced proportionally; the active dot lights up when the rhythm fires
- **Playhead row** — a single orange dot that traverses the full cycle length from left to right, restarting at each downbeat, so the listener can see exactly where in the cycle they are

Each dot row uses `HStack(spacing: 0)` with `Spacer(minLength: 0)` between dots (not after the last) so dot positions are proportional to their time in the cycle rather than equally spaced. Each dot sits centered on a `Capsule` background line to form a unified timeline metaphor.

Each of the beat and rhythm rows has a single pulse value (`beatPulse` / `rhythmPulse`) that snaps to 1.0 on a firing and fades linearly to 0.0 over the interval to the next firing in that row:
- Beat pulse fades over one quarter note: `60 / bpm`
- Rhythm pulse fades over one rhythm interval: `against × (60 / bpm) / beats`

The active dot index, shared pulses, and `cycleProgress` are all stored in `PolyrhythmViewModel` and observed by the view.

## Tap Tempo

The Instant Metronome includes a **Tap Tempo** button displayed as a circle to the right of the BPM display. Tapping it calculates BPM from the average interval of the last several taps. The result is rounded to one decimal place and clamped to the app's min/max BPM range. If more than 2 seconds pass between taps, the tap history is cleared so you can set a new tempo.

## About the Song Library

The song library uses **SwiftData** for local persistence (iOS 17+ requirement). Songs include:
- Title and artist metadata
- BPM and time signature
- Groove/subdivision settings

### Playlists

The app supports multiple named playlists. Each playlist can be independently configured and played. Within a playlist:
- Drag-to-reorder and swipe-to-delete (via Edit mode)
- Inline edit of any song's details
- A transport bar (Previous / Stop / Next) that appears while a song is active and pulses with the beat
- Auto-scroll to the currently playing song

### Practice History

Every time a song is played, `PracticeHistoryViewModel.recordSongPlayed` increments that song's play count in today's `PracticeSession`. The History tab shows:
- A monthly calendar where days with practice are marked with a dot; tap any day to see the songs played
- Current and longest streak counts with start dates
- A reminder banner when the user has an active streak but hasn't practiced today

Streaks are calculated as consecutive calendar days ending on today or yesterday. Practicing yesterday counts as an active streak — missing today breaks it only after today ends.

After each practice session is saved, the app reschedules 7 ahead-of-time daily notifications with content that reflects the projected streak state for each upcoming day (keep streak alive, streak broken, or generic). Notifications also reschedule when the app becomes active or when the reminder time changes in Settings.

### iCloud Sync

The song library syncs automatically across devices via **CloudKit** (private database). SwiftData handles the sync transparently — no user action required. Settings (including the practice reminder toggle and time) sync via **iCloud Key-Value Store** (`NSUbiquitousKeyValueStore`).

### Cross-Device Notification Permissions

Because the reminder setting syncs across devices, a device can receive `sendReminders = true` without ever having been asked for notification permission. The app handles this with two distinct permission paths:

**User-initiated** (`sendReminders` toggled on in the UI): the system permission prompt is shown immediately. If denied, the toggle flips back off and an alert explains how to re-enable in Settings. If the user dismisses the prompt without allowing, the toggle also flips off.

**External trigger** (app launch with `sendReminders` already on, or live cloud sync): the current authorization status is checked first without prompting:
- **Authorized** — schedules notifications normally
- **Denied** — shows an inline warning in Settings with an "Open Settings" link; does *not* flip `sendReminders` off (that would sync back and disable reminders on other devices)
- **Not determined** — shows a pre-prompt alert: *"Practice reminders are enabled on another device. Allow BeatClikr to send them on this device too?"* with "Allow Notifications" / "Not Now"

Tapping **"Not Now"** saves the deferral date to local-only `UserDefaults` (`RemindersDeferredDate`) so the pre-prompt is suppressed on subsequent launches. The Settings screen instead shows a `bell.slash` inline warning with an "Enable" button that re-triggers the system prompt when the user is ready. The deferral date is retained even after the choice is resolved, in case it's useful for future logic (e.g. re-prompting after a long period).

Alerts (`showPermissionDeniedAlert`, `showCrossDeviceReminderPrompt`) are attached to `HomeView` rather than `SettingsView` so they surface from any tab.

## Environment & Dependency Injection

ViewModels are injected as `EnvironmentObject`s at the app level in `beatclikrApp`:
```swift
WindowGroup {
    HomeView()
        .environmentObject(songLibraryViewModel)
        .environmentObject(playlistListViewModel)
        .environmentObject(practiceHistoryViewModel)
        .environmentObject(metronomeViewModel)
        .environmentObject(settingsViewModel)
}
.modelContainer(container)
```

This ensures:
- Single shared instance across all views
- No background metronome instances
- Consistent state throughout the app
- Proper cleanup on app termination
