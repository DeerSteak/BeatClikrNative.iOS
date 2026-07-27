# ViewModels

All ViewModels are injected as `EnvironmentObject`s from `beatclikrApp` and shared across the view hierarchy as singletons.

## EnvironmentObjects

- **MetronomePlaybackViewModel** - Orchestrates metronome playback, coordinates services, and publishes truthful `PlaybackState` (`idle`, `preparing`, `playing`, `interrupted`, or `failed`). `isPlaying` is derived from that state, and the view model enters `playing` only after sound loading and engine start succeed. Recoverable failures are exposed to the view as `PlaybackError`. Receives `metronomeBeatFired(isBeat:beatInterval:)` callbacks and animates the metronome icon and beat pulse over exactly `beatInterval` seconds — the engine-computed time to the next accented beat — so animations stay in sync with the actual rhythmic group length rather than always using a fixed quarter-note duration. Also manages **Tempo Ramp**: when `rampEnabled` is true, `beatsPerMinute` is incremented by `rampIncrement` BPM every `rampInterval` accent beats. BPM is capped at `MetronomeConstants.maxBPM`. The starting BPM is captured in `activeBpm` at `start()` and restored when `stop()` is called.

- **PolyrhythmViewModel** - Manages polyrhythm mode state and uses the same truthful `PlaybackState`/`PlaybackError` contract as the metronome. It owns the M:N ratio (`beats` and `against`, each 1–9), BPM, sound selection, and per-row dot animations (`beatPulse`/`rhythmPulse`, `activeBeatIndex`/`activeRhythmIndex`). Receives `polyrhythmBeatFired` callbacks and fades each row's pulse over the appropriate interval.

- **SettingsViewModel** - Manages user preferences and notification permission state. Maintains three separate permission states: `notificationsBlockedLocally` (system denied), `notificationsDeferredLocally` (user tapped "Not Now" on the cross-device pre-prompt), and `showCrossDeviceReminderPrompt` (undetermined, needs to ask). Delegates all scheduling to `ReminderNotificationService`; see [SongLibrary.md](SongLibrary.md) for the full cross-device notification flow

- **SongLibraryViewModel** - Handles song library CRUD operations and playlist-style playback for the flat song list

- **PlaylistListViewModel** - Manages the list of playlists (create, delete)

- **PlaylistDetailViewModel** - Manages playlist sequencing (next/previous/play), edit, reorder, and delete operations for a single playlist

- **PracticeHistoryViewModel** - Records songs played per day (`recordSongPlayed`); publishes `practiceDates` (`Set<Date>`) and `selectedDateSongs` (`[PracticedSong]`) as observable state; exposes computed properties for current/longest streak values, subtitles, reminder flag, and share text so views contain no streak logic; generates personalized notification bodies projected across future days; exposes an `onPracticeRecorded` callback invoked after each save so the app can immediately reschedule notifications

## Base Class

- **SongNavigationViewModel** - Shared base for `SongLibraryViewModel` and `PlaylistDetailViewModel`; owns the current song index, playback state, and next/previous/play logic

## Environment & Dependency Injection

ViewModels are instantiated once and injected at the app level in `beatclikrApp`:

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

This ensures a single shared instance across all views, no duplicate metronome instances, and consistent state throughout the app.
