# ViewModels

App-scoped ViewModels are created once by `beatclikrApp`, retained as
`StateObject`s, and injected as `EnvironmentObject`s through the view hierarchy.

## EnvironmentObjects

- **MetronomePlaybackViewModel** - Orchestrates metronome playback, coordinates services, and publishes truthful `PlaybackState` (`idle`, `preparing`, `playing`, `interrupted`, or `failed`). `isPlaying` is derived from that state, and the view model enters `playing` only after sound loading and engine start succeed. Recoverable failures are exposed as `PlaybackError`. Beat callbacks anchor a `MetronomeVisualAnimator`; its `CADisplayLink` derives elapsed phase from the engine’s rendered playback position and respects Reduce Motion. The view model also manages **Tempo Ramp**: when enabled, BPM increases by `rampIncrement` every `rampInterval` accent beats, capped at `MetronomeConstants.maxBPM`; stopping restores the captured starting BPM.

- **PolyrhythmViewModel** - Manages polyrhythm mode state and uses the same truthful `PlaybackState`/`PlaybackError` contract as the metronome. It owns the M:N ratio (`beats` and `against`, each 1–15), BPM, sound selection, and per-row visual state. Beat callbacks anchor `PolyrhythmVisualAnimator`; its `CADisplayLink` derives both pulse phases and cycle progress from rendered playback time and suppresses motion under Reduce Motion.

- **SettingsViewModel** - Manages user preferences, notification permission state, and reminder reconciliation. Maintains separate blocked, deferred, prompt, and scheduling-failure states. Every authorized reconciliation obtains a new complete `ReminderPlan` from current settings and practice history, then delegates its verified replacement to `ReminderNotificationService`; see [SongLibrary.md](SongLibrary.md) for the full cross-device notification flow

- **SongLibraryViewModel** - Handles song library CRUD operations and playlist-style playback for the flat song list

- **PlaylistListViewModel** - Manages the list of playlists (create, delete)

- **PlaylistDetailViewModel** - Manages playlist sequencing (next/previous/play), edit, reorder, and delete operations for a single playlist

- **PracticeHistoryViewModel** - Tracks active playback periods using a
  monotonic clock, checkpoints duration every 10 seconds and on lifecycle
  transitions, and attributes switches to the correct stable song/mode ID.
  It repairs legacy/duplicate day records before lookup and publishes
  `practiceDates` (`Set<Date>`) and
  `selectedDateSongs` (`[PracticedSong]`) as observable state; exposes computed
  properties for current/longest streak values, subtitles, reminder flag, and
  share text so views contain no streak logic; generates personalized
  notification bodies projected across future days; exposes an
  `onPracticeRecorded` callback invoked only when an item first crosses the
  30-second qualification threshold

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
        .environmentObject(polyrhythmViewModel)
        .environmentObject(settingsViewModel)
}
.modelContainer(container)
```

This ensures one shared instance of each app-level model, one playback
coordinator, and consistent state throughout the app. These are app-scoped
objects, not process-global static singletons.
