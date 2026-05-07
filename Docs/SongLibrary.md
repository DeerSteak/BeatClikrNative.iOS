# Song Library, Playlists & Practice History

## Song Library

The song library uses **SwiftData** for local persistence. Each `Song` stores:
- Title and artist
- BPM and beats per measure
- Groove/subdivision type and optional `BeatPattern` for odd meters

Songs are displayed in `SongLibraryView`, sorted alphabetically by title then artist. Tapping a song plays it immediately; the current song is highlighted with a play indicator. Edit mode enables swipe-to-delete and inline editing via `SongDetailsView`.

## Playlists

The app supports multiple named playlists. Each `Playlist` owns an ordered list of `PlaylistEntry` records that link back to library songs.

Within `PlaylistDetailView`:
- Drag-to-reorder and delete via Edit mode
- Inline edit of any song's details
- A transport bar (Previous / Stop / Next) at the bottom while a song is active, pulsing with the beat
- Auto-scroll to the currently playing song

## Practice History

Every time a song is played, `PracticeHistoryViewModel.recordSongPlayed` increments that song's play count in today's `PracticeSession`. The History tab shows:
- A monthly calendar where days with practice are marked with a dot; tap any day to see which songs were played
- Current and longest streak counts with start/end dates
- A reminder banner when the user has an active streak but hasn't practiced today

Streaks are consecutive calendar days ending on today or yesterday. Practicing yesterday keeps the streak alive — missing today breaks it only after today ends.

After each save, the app reschedules 7 ahead-of-time daily notifications with content that reflects the projected streak state for each upcoming day (keep streak alive, streak broken, or generic). Notifications also reschedule when the app becomes active or the reminder time changes in Settings.

## iCloud Sync

The song library syncs automatically across devices via **CloudKit** (private database). SwiftData handles the sync transparently — no user action required.

Settings (instrument choices, practice reminder toggle and time, polyrhythm BPM) sync via **iCloud Key-Value Store** (`NSUbiquitousKeyValueStore`).

### Migration flag pattern

Because CloudKit sync can deliver model changes at any time, schema migrations use a persisted flag in `UserDefaults` to ensure one-time migrations run exactly once per device even if the model container is rebuilt. See `UserDefaultsService` for the flag pattern.

## Cross-Device Notification Permissions

Because the reminder setting syncs across devices, a device can receive `sendReminders = true` without ever having been asked for notification permission. The app handles this with two distinct permission paths:

**User-initiated** (`sendReminders` toggled on in the UI): the system permission prompt is shown immediately. If denied, the toggle flips back off and an alert explains how to re-enable in Settings. If the user dismisses without allowing, the toggle also flips off.

**External trigger** (app launch with `sendReminders` already on, or live cloud sync): the current authorization status is checked first without prompting:
- **Authorized** — schedules notifications normally
- **Denied** — shows an inline warning in Settings with an "Open Settings" link; does *not* flip `sendReminders` off (that would sync back and disable reminders on other devices)
- **Not determined** — shows a pre-prompt alert: *"Practice reminders are enabled on another device. Allow BeatClikr to send them on this device too?"* with "Allow Notifications" / "Not Now"

Tapping **"Not Now"** saves the deferral date to local-only `UserDefaults` (`RemindersDeferredDate`) so the pre-prompt is suppressed on subsequent launches. The Settings screen instead shows a `bell.slash` inline warning with an "Enable" button that re-triggers the system prompt when the user is ready.

Alerts (`showPermissionDeniedAlert`, `showCrossDeviceReminderPrompt`) are attached to `HomeView` rather than `SettingsView` so they surface from any tab.
