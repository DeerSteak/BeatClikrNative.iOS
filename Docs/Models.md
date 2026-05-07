# Models

SwiftData persistent models and supporting value types.

## SwiftData Models

- **Song** - Persistent store for a song (title, artist, BPM, time signature, groove, beat pattern)
- **Playlist** - A named collection of songs
- **PlaylistEntry** - An ordered entry in a playlist (linked to `Song`, carries a `sequence` index)
- **PracticeSession** - One day's practice record; owns a list of `PracticedSong` children
- **PracticedSong** - Snapshot of a song's title, BPM, groove, and play count within a session

## Enums

- **Groove** - Subdivision type: `quarter` (1), `eighth` (2), `triplet` (3), `sixteenth` (4), `oddMeterQuarter` (1 subdivision, accent-driven), `oddMeterEighth` (2 subdivisions, accent-driven). The `isOddMeter` property is true for the last two; `subdivisions` returns the number of ticks per beat used by the audio engine

- **BeatPattern** - Encodes odd-meter accent groups as a comma-separated string raw value (e.g. `"3,2,2"` for 7/8). The `accentArray` computed property converts this to `[Bool]` where `true` marks the first tick of each group and `false` fills the remaining ticks:
  ```
  "3,2,2"  →  [true, false, false, true, false, true, false]
  ```
  Patterns cover 5/8 through 15/8.

- **ClickerType** - Distinguishes instant vs. playlist metronome modes
