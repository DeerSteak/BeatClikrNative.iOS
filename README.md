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
- **SettingsViewModel** - Manages user preferences; delegates all notification scheduling to `ReminderNotificationService`
- **SongLibraryViewModel** - Handles song library CRUD operations and playback
- **PlaylistListViewModel** - Manages the list of playlists (create, delete)
- **PlaylistDetailViewModel** - Manages playlist sequencing (next/previous/play), edit, reorder, and delete operations for a single playlist
- **PracticeHistoryViewModel** - Records songs played per day (`recordSongPlayed`); computes current and longest streaks; generates personalized notification bodies projected across future days; exposes an `onPracticeRecorded` callback invoked after each save so the app can immediately reschedule notifications

### Views
- **HomeView** - Root container; uses `TabView` on iPhone and `NavigationSplitView` on iPad/Mac; sections: Instant, Library, Playlists, History, Settings
- **InstantMetronomeView** - Standalone metronome with live BPM/groove controls and tap tempo
- **SongLibraryView** - Browsable song list; tap to play, swipe or edit to delete, + to add
- **PlaylistListView** - List of all named playlists; tap to open, swipe to delete, + to create
- **PlaylistDetailView** - Ordered playlist with inline edit/reorder; shows transport bar when playing
- **PracticeHistoryView** - Calendar showing days on which practice was recorded; tap a day to see details; share button renders a `SharableStreakCard` and opens the system share sheet
- **SongDetailsView** - Add or edit a song's metadata
- **SettingsView** - App-wide preferences (sounds, haptics, flashlight, keep-awake)

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
- **UserDefaultsService** - Persists user preferences and instant metronome settings
- **ReminderNotificationService** - Manages `UNUserNotificationCenter` authorization and scheduling; schedules 7 individual ahead-of-time notifications (one per upcoming day) with pre-computed personalized bodies; caches the last set of bodies so time-change reschedules don't require a new body computation

### Helpers
- **PreviewContainer** - SwiftData `ModelContainer` wrapper for Xcode previews; provides `addMockSongs()`, `addMockPlaylistEntries(for:)`, and `addMockPracticeHistory()` so previews across views share consistent sample data

### Constants
- **MetronomeConstants** - Timing parameters, BPM ranges, animation values, tolerance thresholds
- **ImageConstants** - Asset references for UI elements
- **PreferenceKeys** - SwiftUI preference key definitions
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

The song library syncs automatically across devices via **CloudKit** (private database). SwiftData handles the sync transparently — no user action required. Settings sync via iCloud Key-Value Store.

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
