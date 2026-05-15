# Constants & Helpers

## Constants

- **MetronomeConstants** - Timing parameters, BPM ranges, animation values, and lookahead tolerance thresholds used by the audio engine and ViewModels

- **ImageConstants** - String constants for SF Symbol names and asset catalog image keys used throughout the UI. Note: `tabMetronome` references a custom SVG asset (`MetronomeTabIcon`) rather than an SF Symbol; all other tab icon constants are SF Symbol names

- **PreferenceKeys** - String constants for all `UserDefaults` and `NSUbiquitousKeyValueStore` keys, divided into two groups:
  - *Synced* — written to both `UserDefaults.standard` and `NSUbiquitousKeyValueStore` (e.g. instrument choices, reminder settings)
  - *Local only* — never synced to cloud (e.g. `RemindersDeferredDate`)

- **SoundBank** - Enum for the available sound folders under `Resources/Sounds/`; currently `Acoustic` and `Synth`

- **FileConstants** - Enum mapping sound names to WAV filenames and MIDI note numbers. Each sound bank folder under `Resources/Sounds/` uses the same filenames

- **InstrumentLists** - Filtered lists of `FileConstants` cases for beat and rhythm instrument pickers in Settings

## Helpers

- **PreviewContainer** - SwiftData `ModelContainer` wrapper for Xcode previews; provides `addMockSongs()`, `addMockPlaylist(named:songs:)`, and `addMockPracticeHistory()` so previews across views share consistent sample data without duplicating setup code

- **FormatterHelper** - Utility for formatting BPM doubles for display (e.g. suppresses the decimal when the value is a whole number)
