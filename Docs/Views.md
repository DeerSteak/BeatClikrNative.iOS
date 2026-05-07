# Views

## Main Views

- **HomeView** - Root container; uses `TabView` on iPhone and `NavigationSplitView` on iPad/Mac. iPhone sections: Metronome (contains both Metronome and Polyrhythm), Library, Playlists, History, Settings. iPad/Mac sidebar adds Polyrhythm as its own top-level section. Hosts root-level alerts for notification permission flows (`showPermissionDeniedAlert`, `showCrossDeviceReminderPrompt`) so they surface regardless of which tab is active

- **MetronomeContainerView** - iPhone-only container that hosts `MetronomeView` and `PolyrhythmView` side by side inside a single `NavigationStack`; a segmented control in the navigation bar slides between them horizontally. Switching modes stops the other mode's playback automatically

- **MetronomeView** - Standalone metronome with live BPM/groove controls and tap tempo; when an odd meter groove is selected, also shows a `BeatPattern` picker; includes the Tempo Ramp card

- **PolyrhythmView** - Polyrhythm mode showing the M:N ratio controls, BPM slider, and three timeline dot rows (beat, rhythm, playhead); see [Services.md](Services.md) for how the engine drives the view

- **SongLibraryView** - Browsable song list; tap to play, swipe or edit to delete, + to add

- **PlaylistListView** - List of all named playlists; tap to open, swipe to delete, + to create

- **PlaylistDetailView** - Ordered playlist with inline edit/reorder; shows transport bar when playing

- **PracticeHistoryView** - Calendar showing days on which practice was recorded; tap a day to see details; share button renders a `SharableStreakCard` and opens the system share sheet

- **SongDetailsView** - Add or edit a song's metadata (title, artist, BPM, time signature, groove)

- **SettingsView** - App-wide preferences (sounds, haptics, flashlight, keep-awake, practice reminders). Shows an inline warning below the reminders toggle when notifications are blocked or deferred on this device, with context-appropriate actions: "Open Settings" for denied permissions, "Enable" to trigger the system prompt when previously deferred

## Custom Views

- **CalendarView** - Monthly calendar grid with marked-date dots and tap-to-select; accepts a `Set<Date>` of marked days and a `Binding<Date?>` for the selected date

- **PlaylistTransportView** - Floating Previous / Stop / Next transport bar shown at the bottom of Playlist and Library while a song is active; pulses with the beat

- **SongPickerView** - Sheet for picking a library song to add to a playlist

- **SongListItemView** - Reusable list row showing title, artist, BPM, and groove; works for both `Song` and `PracticedSong`

- **MetronomePlayerView** - Compact animated metronome indicator used in toolbars

- **SharableStreakCard** - 360×360 shareable image card showing the streak count with the app icon and a black-to-blue gradient; rendered off-screen via `ImageRenderer` for the share sheet

- **BpmSliderControl** - Custom BPM slider with fine/coarse drag behavior

- **TapTempoButton** - Circle button that derives BPM from average tap intervals; resets history after 2 seconds of silence

- **GrooveSelectorView** - Segmented picker for groove/subdivision selection; shows `BeatPattern` picker when an odd meter groove is active

- **PlaylistFocusView** - Immersive full-screen playback overlay for playlists; always-black background with a large pulsing circle that scales and brightens on each beat, a "Now Playing" label showing the current song title, and Previous / Play-Pause / Next transport controls. Presented as a sheet from `PlaylistDetailView`

- **SettingsCard** - Styled card container used throughout `SettingsView`

- **CardContainer** - Generic rounded card container for grouped content
