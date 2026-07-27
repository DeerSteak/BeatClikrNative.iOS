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

Successful audio playback opens a monotonic playback period. Active time is
checkpointed every 10 seconds and on lifecycle changes, and accumulated into
one daily item per stable song or built-in mode. Background audio counts;
paused, stopped, failed, and interrupted time does not. An item qualifies at
30 accumulated seconds; shorter activity is retained for later accumulation
but remains hidden and does not earn a calendar dot or streak day.

The History tab shows:
- A monthly calendar where qualifying days are marked with a dot
- Metronome and Polyrhythm first, followed by songs sorted by title, artist, and stable identity
- Total daily duration and playback-period count for each item
- Current and longest streak counts with start/end dates
- A reminder banner when the user has an active streak but hasn't practiced today

Streaks are consecutive calendar days ending on today or yesterday. Practicing yesterday keeps the streak alive — missing today breaks it only after today ends.

When an item first qualifies, the app reschedules 7 ahead-of-time daily notifications with content that reflects the projected streak state for each upcoming day. Routine duration checkpoints do not repeatedly reschedule reminders.

## iCloud Sync

The song library syncs automatically across devices via **CloudKit** (private database). SwiftData handles the sync transparently — no user action required.

Settings (instrument choices, practice reminder toggle and time, polyrhythm BPM) sync via **iCloud Key-Value Store** (`NSUbiquitousKeyValueStore`).

### Migration and repair policy

The legacy single-playlist migration uses the local
`DidMigrateToMultiplePlaylists` flag because it is a one-time structural
conversion on each device. Practice-day migration and duplicate repair do not
depend on a one-shot flag: `PracticeDayRepair` is idempotent and runs during
startup, background maintenance, and history access so later CloudKit arrivals
are normalized too.

## Cross-Device Notification Permissions

Because the reminder setting syncs across devices, a device can receive `sendReminders = true` without ever having been asked for notification permission. The app handles this with two distinct permission paths:

**User-initiated** (`sendReminders` toggled on in the UI): the system permission prompt is shown immediately. If denied, the toggle flips back off and an alert explains how to re-enable in Settings. If the user dismisses without allowing, the toggle also flips off.

**External trigger** (app launch with `sendReminders` already on, or live cloud sync): the current authorization status is checked first without prompting:
- **Authorized** — schedules notifications normally
- **Denied** — shows an inline warning in Settings with an "Open Settings" link; does *not* flip `sendReminders` off (that would sync back and disable reminders on other devices)
- **Not determined** — shows a pre-prompt alert: *"Practice reminders are enabled on another device. Allow BeatClikr to send them on this device too?"* with "Allow Notifications" / "Not Now"

Tapping **"Not Now"** saves the deferral date to local-only `UserDefaults` (`RemindersDeferredDate`) so the pre-prompt is suppressed on subsequent launches. The Settings screen instead shows a `bell.slash` inline warning with an "Enable" button that re-triggers the system prompt when the user is ready.

Alerts (`showPermissionDeniedAlert`, `showCrossDeviceReminderPrompt`) are attached to `HomeView` rather than `SettingsView` so they surface from any tab.
