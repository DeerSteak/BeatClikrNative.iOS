# BeatClikrNative.iOS
BeatClikr's reimplementation for iOS 18+ with SwiftUI, SwiftData, AVFoundation audio scheduling, and iCloud sync. Available on the App Store.

## New for version 4.0

### Tempo Ramp
The Metronome now includes an optional **Tempo Ramp** card. When enabled, BPM automatically increases by a configurable increment (default 1 BPM) every N beats. The starting BPM is restored when playback stops, so the next session begins at the original tempo. Settings persist via `UserDefaults`.

### Focus Mode
Playlist playback now has a **Focus Mode** sheet (`PlaylistFocusView`): a full-screen always-dark overlay with a large pulsing circle synchronized to the beat, the current song title, and Previous / Play-Pause / Next transport controls. Designed for distraction-free practice sessions.

### Custom metronome tab icon
The generic SF Symbol `metronome` has been replaced with a custom SVG icon (`MetronomeTabIcon`) derived from the BeatClikr app icon artwork — the same trapezoid body, pendulum rod, and weight seen in `BeatClikrAppIcon.icon`. The SVG lives in `Assets.xcassets` as a template image with `preserves-vector-representation: true` so it scales cleanly at all sizes and respects system tint in both tab bar and sidebar contexts.

### Polyrhythm
A new **Polyrhythm** mode layers two independent rhythms at the same tempo: M beats against N (each 1–9, selectable via steppers). Both complete one cycle in N quarter notes. The view shows three proportional timeline rows — beat, rhythm, and a traversing playhead dot — so you can see and hear exactly how the two patterns align. BPM persists across launches and syncs via iCloud KV store.
- Beat and rhythm playback uses independent scheduled audio tracks with a shared cycle origin
- Each dot row is laid out as a proportional timeline (piano-roll style) with a `Capsule` background line
- A third **playhead row** shows a single dot traversing the full cycle

### Odd Meter grooves
Two new groove types — **Odd Quarter** and **Odd Eighth** — support asymmetric meters from 5/8 through 15/8 via a `BeatPattern` accent picker. The audio engine steps through the accent array tick by tick and computes a per-group `beatInterval` so animations stretch to match each rhythmic group (e.g. the 3-beat group in a 3+2+2 pattern animates longer than the 2-beat groups).

### Practice History
A new **Practice History** tab records every song played per day and shows:
- A monthly calendar with dots on practiced days; tap any day to see which songs were played
- Current and longest streak counts with start/end dates
- A reminder banner when you have an active streak but haven't practiced today

After each session the app reschedules 7 ahead-of-time daily notifications with content that reflects the projected streak state for each upcoming day (keep it alive, broken, or generic). Notifications also reschedule when the app becomes active or the reminder time changes in Settings.

### Streak Sharing
The Practice History tab has a **Share** button that renders a `SharableStreakCard` — a 360×360 image with the streak count, app icon, and a gradient background — and opens the system share sheet with pre-written adaptive text.

### Playlist renaming
Playlists can now be renamed inline from the playlist list view.

### Cross-device practice reminders
Practice reminder settings sync via iCloud KV store, so enabling reminders on one device propagates to all signed-in devices. The app handles three distinct cases when `sendReminders` arrives via sync:
- **Authorized** — schedules immediately
- **Denied** — shows an inline Settings warning without disabling the setting on other devices
- **Not determined** — shows a pre-prompt alert before requesting system permission; "Not Now" suppresses re-prompting until the user taps "Enable" in Settings

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
