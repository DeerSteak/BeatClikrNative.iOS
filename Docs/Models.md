# Models

SwiftData persistent models and supporting value types.

## SwiftData Models

- **Song** - Persistent store for a song (title, artist, BPM, time signature, groove, beat pattern)
- **Playlist** - A named collection of songs
- **PlaylistEntry** - An ordered entry in a playlist (linked to `Song`, carries a `sequence` index)
- **PracticeSession** - One day's practice record; owns a list of
  `PracticedSong` children. Its stable identity is a Gregorian local civil-day
  key (`yyyy-MM-dd`) captured in the device time zone when practice is recorded.
  The original timestamp, time-zone identifier, and calendar identifier are
  retained as metadata. Changing time zones never reclassifies an existing
  session.
- **PracticedSong** - One daily item per stable song/mode, containing snapshot metadata, accumulated active-playback duration, and playback-period count

## Practice-day merge policy

Practice belongs to the local civil day on which it was recorded. The day key
does not include a time-zone suffix, so offline devices that record the same
local calendar date converge to one logical session after CloudKit sync.

Because CloudKit does not enforce SwiftData uniqueness constraints, startup,
backgrounding, and practice-history reads run an idempotent repair:

- legacy records without a day key are assigned one using the device time zone
  at migration;
- duplicate sessions with the same key merge into one deterministic session;
- different practiced-song IDs are preserved;
- duration and playback-period counts for the same stable song ID are added;
- the built-in metronome and polyrhythm retain one credit per day;
- repaired duplicates are deleted only after their song snapshots are rebuilt.

Historical legacy timestamps do not contain their original time zone. Their
first migration therefore preserves the interpretation used by the device
performing that migration; subsequent travel cannot rewrite it.

Legacy practiced items without duration migrate to 30 seconds so previously
earned history and streaks remain qualified. Partial CloudKit records are
normalized centrally before use.

## Enums

- **Groove** - Subdivision type: `quarter` (1), `eighth` (2), `triplet` (3), `sixteenth` (4), `oddMeterQuarter` (1 subdivision, accent-driven), `oddMeterEighth` (2 subdivisions, accent-driven). The `isOddMeter` property is true for the last two; `subdivisions` returns the number of ticks per beat used by the audio engine

- **BeatPattern** - Encodes odd-meter accent groups as a comma-separated string raw value (e.g. `"3,2,2"` for 7/8). The `accentArray` computed property converts this to `[Bool]` where `true` marks the first tick of each group and `false` fills the remaining ticks:
  ```
  "3,2,2"  →  [true, false, false, true, false, true, false]
  ```
  Patterns cover 5/8 through 15/8.

- **ClickerType** - Distinguishes instant vs. playlist metronome modes
