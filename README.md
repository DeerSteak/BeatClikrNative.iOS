# BeatClikrNative.iOS
BeatClikr's reimplementation for iOS 18+ with SwiftUI, SwiftData, AudioKit, and iCloud sync. Available on the App Store.

## What's New

### Tempo Ramp
The Metronome now includes an optional **Tempo Ramp** card. When enabled, BPM automatically increases by a configurable increment (default 1 BPM) every N beats. The starting BPM is restored when playback stops, so the next session begins at the original tempo. Settings persist via `UserDefaults`.

### Focus Mode
Playlist playback now has a **Focus Mode** sheet (`PlaylistFocusView`): a full-screen always-dark overlay with a large pulsing circle synchronized to the beat, the current song title, and Previous / Play-Pause / Next transport controls. Designed for distraction-free practice sessions.

### Custom metronome tab icon
The generic SF Symbol `metronome` has been replaced with a custom SVG icon (`MetronomeTabIcon`) derived from the BeatClikr app icon artwork — the same trapezoid body, pendulum rod, and weight seen in `BeatClikrAppIcon.icon`. The SVG lives in `Assets.xcassets` as a template image with `preserves-vector-representation: true` so it scales cleanly at all sizes and respects system tint in both tab bar and sidebar contexts.

### Polyrhythm improvements
- BPM is now persisted across launches and synced via iCloud KV store
- The dot rows are laid out as a proportional timeline (piano-roll style) with a `Capsule` background line
- A third **playhead row** shows a single orange dot traversing the full cycle, so the listener can see exactly where in the group they are

### Streak Sharing
The Practice History tab has a **Share** button that renders a `SharableStreakCard` — a 360×360 image with the streak count, app icon, and a gradient background — and opens the system share sheet with pre-written adaptive text.

### Liquid Glass App Icon (iOS 26+)
`BeatClikrAppIcon.icon` is a multilayer Icon Composer file that provides a Liquid Glass icon for iOS 26+. The icon has a blue gradient background in light mode and adapts to dark mode automatically. Xcode generates a static fallback for iOS 18–25 at build time.

## Setup

This project relies on WAV files that are not in git. You will need to supply your own:

- Place files with the correct names in `beatclikr/Resources/Sounds/`
- See `Constants/FileConstants.swift` for the required filenames and MIDI note mappings

The WAV files are proprietary recordings. You're free to use this code, but you'll need your own media files.

## Documentation

| File | Contents |
|------|----------|
| [Docs/Models.md](Docs/Models.md) | SwiftData models and supporting enums |
| [Docs/ViewModels.md](Docs/ViewModels.md) | ViewModels, dependency injection |
| [Docs/Views.md](Docs/Views.md) | Main views and custom view components |
| [Docs/Services.md](Docs/Services.md) | Services, timing, audio, odd meter, polyrhythm, tap tempo |
| [Docs/Constants.md](Docs/Constants.md) | Constants and preview helpers |
| [Docs/SongLibrary.md](Docs/SongLibrary.md) | Song library, playlists, practice history, iCloud sync, notifications |
