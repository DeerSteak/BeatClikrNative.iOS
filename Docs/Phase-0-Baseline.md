# Phase 0 Timing Baseline

**Status:** Capture pending  
**Android comparator:** `bc1f85b4e08803aa4749c1555adf5ae0d61092c2`  
**Unchanged iOS baseline:** `38c6f3c5723bc7bcab0ce5c8560f9e8ed8bc4553`

## Reference environment

| Field | Pinned value |
| --- | --- |
| Reference device | Ben's iPhone, iPhone 16 Pro (`iPhone17,1`, 256 GB) |
| Device identifier | `00008140-0009701A3C33001C` |
| iOS | 26.5.2 (`23F84`) |
| Physical route | Built-in speaker |
| Xcode | 26.6 (`17F113`) |
| Swift | 6.3.3 (`swiftlang-6.3.3.1.3`) |
| Host | macOS 26.6.1 (`25G76`) |
| Build configuration | Signed Release, built from the unchanged baseline code |
| Session category | `.playback`, `.default`, `.mixWithOthers` |
| Session sample rate | Pending capture from the `AudioSession` activation log |
| Output, mixer, player, and buffer rates | Pending capture from `AudioRenderFormat` start and pool logs |
| Session I/O buffer duration | Pending capture from the `AudioSession` activation log |
| Recording path | AudioBox into GarageBand unless the capture manifest names a replacement |
| Recorder clock calibration | Uncalibrated; fitted physical drift is observational |

The physical reference is limited to this iPhone and its built-in speaker. Results do not qualify Bluetooth, USB, AirPlay, another iPhone model, or another recording chain.

## Controlled app and device settings

Record the exact value used in each run manifest. Unless a row says otherwise, use acoustic sound bank, `ClickHi` for beat, `ClickLo` for rhythm, mute off, alternate sixteenths off, ramp off, haptic off, flashlight off, Keep Awake on, no backing audio, and no other active media app. Fix speaker volume, screen brightness, Low Power Mode, Focus, network state, thermal state, battery state, device orientation, microphone/interface gain, GarageBand project sample rate, and microphone/interface placement for the complete matched population.

Do not normalize, trim, time-stretch, resample, quantize, or add a reference click to a raw capture. Export unedited PCM WAV. A processing operation creates a derived file and must leave the raw recording unchanged.

## Static capture matrix

| Run ID | Mode | Configuration | Minimum duration | Expected event interval | Expected events in 20 minutes |
| --- | --- | --- | --- | --- | --- |
| `standard-030-quarter` | Standard | 30 BPM, quarter notes | 20 minutes | 2000 ms | 600 |
| `standard-120-eighth` | Standard | 120 BPM, eighth notes | 20 minutes | 250 ms | 4,800 |
| `standard-240-sixteenth` | Standard | 240 BPM, sixteenth notes | 20 minutes | 62.5 ms | 19,200 |
| `poly-15-14` | Polyrhythm | 15:14 at 120 BPM | 20 complete cycles | Role-dependent | 300 rhythm and 280 reference events |
| `poly-04-04` | Polyrhythm | Equal 4:4 at 120 BPM | 20 complete cycles | 500 ms coincident frames | 80 coincident frames |
| `poly-06-04` | Polyrhythm | Shared-factor 6:4 at 120 BPM | 20 complete cycles | Rhythm 333.333… ms; reference 500 ms | 120 rhythm and 80 reference events |

Record at least five seconds of silence before Play and after Stop. Note the accepted Play time and Stop time without trimming the file. The equal-ratio population validates coincidence; do not classify its two logical roles as doubled acoustic events.

## Live-change capture

Run one uninterrupted screen recording and audio capture. Allow 10 seconds of stable playback before the first action and after the last action.

1. Start standard playback at 120 BPM quarter notes.
2. Change slowly through 121, 122, 123, and 124 BPM, holding each value for 10 seconds.
3. Scrub rapidly between 80 and 200 BPM for 10 seconds, then settle at 120 BPM for 20 seconds.
4. Change quarter → eighth → triplet → sixteenth → quarter, holding each groove for 10 seconds.
5. Select a representative odd-quarter pattern, then a representative odd-eighth pattern, holding each for 20 seconds.
6. Change beat sound, rhythm sound, and sound bank separately, with 10 seconds between changes.
7. Enable ramp at +2 BPM every 8 beat events for four increments, disable it, and hold for 20 seconds.
8. Stop standard playback, start 3:2 polyrhythm at 120 BPM, change to 5:4, then 15:14, holding each ratio for two complete cycles.
9. Stop polyrhythm playback and confirm no later event is audible.

The capture manifest records action timestamps from the screen recording. Analysis must inspect transition windows separately from stable populations.

## Required artifacts

Each run has a directory named `YYYY-MM-DD_run-id` outside Git containing:

- the unedited WAV;
- exported onset frames and timestamps;
- analysis output and threshold/sensitivity results;
- BeatClikr unified log covering activation through stop;
- the run manifest with environment, route, settings, commands, and file hashes;
- screen recording for live changes or any ambiguous interaction;
- concise manual anomaly notes.

Record the durable artifact root in the baseline summary. Proprietary WAV files remain untracked.

## Exact environment commands

Run these from the iOS repository and save their complete output in the capture manifest:

```bash
git rev-parse HEAD
git -C ../BeatClikr.Android rev-parse HEAD
xcodebuild -version
xcrun swift --version
sw_vers
xcrun devicectl device info details --device 'Ben’s iPhone'
shasum -a 256 /absolute/path/to/capture.wav
afinfo /absolute/path/to/capture.wav
python3 tools/analyze_acoustic_onsets.py /absolute/path/to/capture.wav --interval-ms 250 --grouping 4
```

Set `--interval-ms` to the expected event interval. Use `--grouping` to compare a musically meaningful span and reduce sensitivity to individual acoustic-onset placement; record the value in the run manifest. The example analyzes 120 BPM eighth notes over four-event groups. Preserve the complete output. Tune `--threshold`, `--minimum-distance-ms`, or `--window-ms` only through a documented sensitivity analysis, never solely to obtain a passing classification.

Build the unchanged code for the physical reference device with:

```bash
xcodebuild build -project beatclikr.xcodeproj -scheme beatclikr -configuration Release -destination 'platform=iOS,id=00008140-0009701A3C33001C'
```

The installed app and exact commit must match the manifest. Building alone does not prove which app binary is installed.

## Classification vocabulary

| Classification | Meaning |
| --- | --- |
| Intended-frame error | The application's intended musical frame is incorrect, duplicated, missing, stale, or out of order. |
| Render/schedule discontinuity | Intended musical frames are correct, but rendering or scheduling loses continuity or publishes a mixed configuration. |
| Presentation/route variance | Application frames are correct and the difference appears after the application boundary in the device, route, air path, or recorder. |
| Measurement artifact | Recording, export, reference audio, onset detection, clock mismatch, or analysis introduced the apparent anomaly. |
| Unknown | Available evidence cannot distinguish the layers; list the missing observation needed to classify it. |

Every perceived fluctuation receives exactly one current classification plus supporting artifact paths. `Unknown` is acceptable evidence; silently discarding an anomaly is not.

## Known pre-baseline evidence

The earlier physical smoke captures measured 120 BPM at approximately 119.9988 BPM and 137 BPM triplets at approximately 136.9986 BPM after the render-format correction, with no detected missing or doubled events in those short populations. They demonstrate that the prior 48 kHz/44.1 kHz slowdown signature was removed, but their duration and capture manifest do not satisfy this Phase 0 baseline.

## Exit record

Phase 0 exits only when the static matrix, polyrhythm matrix, and live-change capture are classified and their raw artifacts are preserved. If the original fluctuation is not reproduced, the summary states that explicitly and names the completed scenarios. Scheduler behavior remains unchanged until this baseline and its comparator are accepted.
