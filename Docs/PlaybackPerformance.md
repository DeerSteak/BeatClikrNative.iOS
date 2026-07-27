# Playback Performance Validation

Playback performance has two separate gates:

1. Deterministic tests protect sample-timeline correctness and bounded cache
   behavior.
2. Instruments and Activity Monitor measurements protect real CPU, allocation,
   and resident-memory behavior.

Synthetic tests cannot establish a device CPU budget. Measurements must use an
unchanged build, scenario, duration, and hardware description so later results
are comparable.

## Automated invariants

`AbsoluteAudioTimelineTests` verifies:

- rendered onset samples for normal, accented, alternate-sixteenth, odd-meter,
  and polyrhythm playback;
- exact cycle boundaries and simultaneous polyrhythm reunions;
- click-tail behavior at adjacent rolling-block boundaries;
- eight-hour metronome and polyrhythm timelines without wall-clock waiting;
- no new derived click buffers after a stable tempo has been prewarmed.

`AudioBufferClipCacheTests` enforces the secondary-cache limits:

- at most 16 derived buffers per loaded source;
- at most 2 MiB of derived audio per loaded source;
- least-recently-used eviction under aggressive frame-length changes.

These limits do not include the immutable source buffer or the small rolling
render-buffer pool owned by each active engine.

## Measurement matrix

Measure each row for 15 minutes in both Catalyst Debug and Release builds.
Repeat the Release matrix on a physical iPhone through TestFlight.

| Scenario | Configuration |
| --- | --- |
| Idle | App foregrounded, playback stopped |
| Static | 120 BPM, quarter notes |
| Maximum rate | 240 BPM, sixteenth notes, animation visible |
| Odd meter | Longest supported odd pattern at 240 BPM |
| Polyrhythm | 15:14 at 240 BPM |
| Change stress | Repeated tempo, groove, meter, sound, and mode changes |

For each run, record:

- hardware model, OS version, app version/commit, and Debug or Release;
- average and peak CPU after the first minute;
- resident memory at 1, 5, and 15 minutes;
- whether CPU and memory reach a stable plateau;
- audio glitches, missing/doubled clicks, or visible timing jumps.

Use Time Profiler for the maximum-rate and polyrhythm rows. Attribute samples
separately to audio rendering/scheduling, `CADisplayLink`, and SwiftUI work. Use
Allocations for the static and change-stress rows; a stable static run must not
show continuing `AVAudioPCMBuffer` growth.

## Observations

| Date | Hardware | Build | Scenario | Result | Status |
| --- | --- | --- | --- | --- | --- |
| 2026-07-27 | M4 Pro Mac mini | Catalyst Debug | Maximum-tempo odd meter and polyrhythm | Approximately 55% CPU in Activity Monitor; observed work remained on efficiency cores | Informational; duration, memory, OS, and commit were not recorded |

## Release thresholds

Numeric CPU and memory thresholds remain intentionally unset until the complete
Catalyst Release and physical-iPhone matrix has been recorded. The nonnumeric
release requirements are:

- no audible glitch or missing/doubled onset;
- CPU and resident memory plateau during unchanged playback;
- no continuing audio-buffer allocation during unchanged playback;
- timing tests remain green with performance optimizations enabled.
