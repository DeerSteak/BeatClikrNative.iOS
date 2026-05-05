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
- **Groove** - Enum defining subdivision types (quarter notes, eighth notes, triplets, sixteenths)
- **ClickerType** - Enum distinguishing instant vs. playlist metronome modes

### ViewModels (EnvironmentObjects)
- **MetronomePlaybackViewModel** - Orchestrates metronome playback, coordinates services, handles UI state (beat pulse, isPlaying)
- **SettingsViewModel** - Manages user preferences and notification permission state. Maintains three separate permission states: `notificationsBlockedLocally` (system denied), `notificationsDeferredLocally` (user tapped "Not Now" on the cross-device pre-prompt), and `showCrossDeviceReminderPrompt` (undetermined, needs to ask). Delegates all scheduling to `ReminderNotificationService`; see *Cross-Device Notification Permissions* below
- **SongLibraryViewModel** - Handles song library CRUD operations and playback
- **PlaylistListViewModel** - Manages the list of playlists (create, delete)
- **PlaylistDetailViewModel** - Manages playlist sequencing (next/previous/play), edit, reorder, and delete operations for a single playlist
- **PracticeHistoryViewModel** - Records songs played per day (`recordSongPlayed`); computes current and longest streaks; generates personalized notification bodies projected across future days; exposes an `onPracticeRecorded` callback invoked after each save so the app can immediately reschedule notifications

### Views
- **HomeView** - Root container; uses `TabView` on iPhone and `NavigationSplitView` on iPad/Mac; sections: Instant, Library, Playlists, History, Settings. Hosts root-level alerts for notification permission flows (`showPermissionDeniedAlert`, `showCrossDeviceReminderPrompt`) so they surface regardless of which tab is active
- **InstantMetronomeView** - Standalone metronome with live BPM/groove controls and tap tempo
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
- **AudioKitMetronomeEngine** - Sample-accurate metronome using AudioKit's AppleSampler
- **AudioPlayerService** - Wrapper for audio engine, manages sound loading and playback
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
