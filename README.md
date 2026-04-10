# BeatClikrNative.iOS
BeatClikr's reimplementation for iOS 17+ with SwiftUI, SwiftData, AudioKit, and iCloud backup. 

Note: This project relies on a series of .WAV files that are not in git. You will need to add these yourself:

- WAV files go with their correct names in Resources/Sounds
- See Constants/FileConstants for the correct WAV filenames

The WAV files are proprietary and I recorded them myself. You're free to use this code, but you'll need your own media files. :D 

## Architecture Overview

BeatClikr follows an MVVM architecture with a clean separation of concerns:

### Models
- **Song** - SwiftData model for song storage 
- **Groove** - Enum defining subdivision types (quarter notes, eighth notes, triplets, sixteenths)

### ViewModels (EnvironmentObjects)
- **MetronomePlaybackViewModel** - Orchestrates metronome playback, coordinates services, handles UI state
- **SettingsViewModel** - Manages user preferences and iCloud backup/restore operations
- **SongLibraryViewModel** - Handles song library CRUD operations and playlist management
- **PlaylistViewModel** - COMING SOON - playlists

### Services Layer
- **AudioKitMetronomeEngine** - Sample-accurate metronome using AudioKit's AppleSampler
- **AudioPlayerService** - Wrapper for audio engine, manages sound loading and playback
- **FlashlightService** - Controls device flashlight for visual accessibility
- **VibrationService** - Manages haptic feedback (UIImpactFeedbackGenerator)
- **UserDefaultsService** - Persists user preferences and instant metronome settings
- **iCloudBackupService** - Handles backup/restore of settings and songs to iCloud Drive

### Constants
- **MetronomeConstants** - Timing parameters, BPM ranges, animation values, tolerance thresholds
- **ImageConstants** - Asset references for UI elements
- **PreferenceKeys** - SwiftUI preference key definitions
- **FileConstants** - Enum mapping sound file names to their audio files and MIDI notes - your files need to match these names

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
- Triggers visual animations (icon scale transitions)
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

The `AudioPlayerService` manages:
- Loading audio files from the bundle
- Configuring the audio engine
- Mapping user preferences (beat/rhythm selection) to the correct MIDI notes
- Starting/stopping the metronome
- Real-time tempo and subdivision updates

## About the Song Library

The song library uses **SwiftData** for local persistence (iOS 17+ requirement). Songs include:
- Title and artist metadata
- BPM and time signature
- Groove/subdivision settings
- Optional live and rehearsal sequence numbers for playlist ordering

### iCloud Backup & Sync

**Now Implemented!** The app includes full iCloud backup and restore functionality:

- **iCloudBackupService** creates JSON backups of all settings and songs
- Backups are stored in the user's iCloud Drive container
- One-tap backup and restore from Settings
- Includes versioning and timestamp metadata
- Handles settings: playback preferences, instrument selections, metronome settings
- Handles songs: full library with all metadata preserved

Users can back up their library on one device and restore it on another, providing seamless multi-device support without custom cloud infrastructure.

## Environment & Dependency Injection

ViewModels are injected as `EnvironmentObject`s at the app level in `beatclikrApp`:
```swift
WindowGroup {
    HomeView()
        .environmentObject(SongLibraryViewModel())
        .environmentObject(MetronomePlaybackViewModel())      
        .environmentObject(SettingsViewModel())
}
```

This ensures:
- Single shared instance across all views
- No background metronome instances
- Consistent state throughout the app
- Proper cleanup on app termination 
