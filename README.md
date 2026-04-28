# BeatClikrNative.iOS
BeatClikr's reimplementation for iOS 17+ with SwiftUI, SwiftData, AudioKit, and iCloud sync. Available on the App Store.

Note: This project relies on a series of .WAV files that are not in git. You will need to add these yourself:

- WAV files go with their correct names in Resources/Sounds
- See Constants/FileConstants for the correct WAV filenames

The WAV files are proprietary and I recorded them myself. You're free to use this code, but you'll need your own media files. :D 

## Architecture Overview

BeatClikr follows an MVVM architecture with a clean separation of concerns:

### Models
- **Song** - SwiftData model for song storage (title, artist, BPM, time signature, groove)
- **PlaylistEntry** - SwiftData model for ordered playlist entries (linked to Song, with sequence index)
- **Groove** - Enum defining subdivision types (quarter notes, eighth notes, triplets, sixteenths)
- **ClickerType** - Enum distinguishing instant vs. playlist metronome modes

### ViewModels (EnvironmentObjects)
- **MetronomePlaybackViewModel** - Orchestrates metronome playback, coordinates services, handles UI state (beat pulse, isPlaying)
- **SettingsViewModel** - Manages user preferences
- **SongLibraryViewModel** - Handles song library CRUD operations and playback
- **PlaylistModeViewModel** - Manages playlist sequencing (next/previous/play), edit, reorder, and delete operations

### Views
- **HomeView** - Root container; uses `TabView` on iPhone and `NavigationSplitView` on iPad/Mac
- **InstantMetronomeView** - Standalone metronome with live BPM/groove controls and tap tempo
- **SongLibraryView** - Browsable song list; tap to play, swipe or edit to delete, + to add
- **PlaylistModeView** - Ordered playlist with inline edit/reorder; shows transport bar when playing
- **SongDetailsView** - Add or edit a song's metadata
- **SettingsView** - App-wide preferences (sounds, haptics, flashlight, keep-awake)

### Custom Views
- **PlaylistTransportView** - Floating Previous / Stop / Next transport bar shown at the bottom of Playlist mode while a song is active; pulses with the beat
- **SongPickerView** - Sheet for picking a library song to add to the playlist
- **SongListItemView** - Reusable list row showing title, artist, BPM, and groove
- **MetronomePlayerView** - Compact animated metronome indicator used in toolbars

### Services Layer
- **AudioKitMetronomeEngine** - Sample-accurate metronome using AudioKit's AppleSampler
- **AudioPlayerService** - Wrapper for audio engine, manages sound loading and playback
- **FlashlightService** - Controls device flashlight for visual accessibility
- **VibrationService** - Manages haptic feedback (UIImpactFeedbackGenerator)
- **UserDefaultsService** - Persists user preferences and instant metronome settings

### Helpers
- **PreviewContainer** - SwiftData `ModelContainer` wrapper for Xcode previews; provides `addMockSongs()` and `addMockPlaylistEntries(for:)` so previews across views share consistent sample data

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

### Playlist Mode

Songs from the library can be added to the playlist in any order. The playlist supports:
- Drag-to-reorder and swipe-to-delete (via Edit mode)
- Inline edit of any song's details
- A transport bar (Previous / Stop / Next) that appears while a song is active and pulses with the beat
- Auto-scroll to the currently playing song

### iCloud Sync

The song library syncs automatically across devices via **CloudKit** (private database). SwiftData handles the sync transparently — no user action required. Settings sync via iCloud Key-Value Store.

## Environment & Dependency Injection

ViewModels are injected as `EnvironmentObject`s at the app level in `beatclikrApp`:
```swift
WindowGroup {
    HomeView()
        .environmentObject(songLibraryViewModel)
        .environmentObject(playlistModeViewModel)
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
