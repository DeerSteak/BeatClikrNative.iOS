# Phase 0 Live-Change Recording Run Sheet

Use this operator script for the single uninterrupted Phase 0 live-change audio capture and screen recording. The target duration is approximately five minutes. Action times are targets, not evidence; copy the actual screen-recording timestamps into the manifest after the run.

## Before recording

- Install the signed Release build whose commit is recorded in the manifest.
- Use the reference iPhone's built-in speaker with no other media app playing.
- Set a fixed speaker volume and recording-interface gain; record both values.
- Set Acoustic bank, Beat `Click Hi`, Rhythm `Click Lo`, 120 BPM, Quarter Note, ramp off, mute off, alternate sixteenths off, haptic off, and flashlight off.
- Set the polyrhythm page to 3:2 at 120 BPM, but leave it stopped.
- Start the external unedited PCM WAV recording, then start the iPhone screen recording.
- Do not speak, clap, or play a reference click into the audio recording. The screen recording provides action markers.

If a control takes longer than the allotted action window, finish it accurately and continue. Never rush a selection merely to match the target timestamp.

## Timed operator script

| Target time | Action | Hold/observation |
| --- | --- | --- |
| `00:00` | Begin both recordings with BeatClikr stopped on the Metronome page. | Capture 10 seconds of room/interface noise. |
| `00:10` | Press Play at 120 BPM, Quarter Note. | Establish 10 seconds of stable playback. |
| `00:20` | Set 121 BPM. | Hold 10 seconds. |
| `00:30` | Set 122 BPM. | Hold 10 seconds. |
| `00:40` | Set 123 BPM. | Hold 10 seconds. |
| `00:50` | Set 124 BPM. | Hold 10 seconds. |
| `01:00` | Scrub the tempo repeatedly between approximately 80 and 200 BPM. | Continue for 10 seconds; do not stop playback. |
| `01:10` | Set exactly 120 BPM. | Hold 20 seconds. |
| `01:30` | Select Eighth Note. | Hold 10 seconds. |
| `01:40` | Select Triplet 6/8. | Hold 10 seconds. |
| `01:50` | Select Sixteenth Note. | Hold 10 seconds. |
| `02:00` | Select Quarter Note. | Hold 10 seconds. |
| `02:10` | Select Odd Quarter and pattern `7 (3+2+2)`. | Hold 20 seconds. |
| `02:30` | Select Odd Eighth, retaining pattern `7 (3+2+2)`. | Hold 20 seconds. |
| `02:50` | Change Beat from `Click Hi` to `Cowbell`. | Hold 10 seconds after the selection completes. |
| `03:00` | Change Rhythm from `Click Lo` to `Snare`. | Hold 10 seconds after the selection completes. |
| `03:10` | Change sound bank from Acoustic to Synth. | Hold 10 seconds after the selection completes. |
| `03:20` | Return to Acoustic bank, Beat `Click Hi`, Rhythm `Click Lo`, Quarter Note, and exactly 120 BPM. | Hold 10 seconds after the final selection. Record each individual selection time. |
| `03:30` | Set ramp to +2 BPM every 8 beats, then enable it. | Watch the displayed tempo. Do not touch other controls. |
| Event-driven | After the fourth increment reaches 128 BPM, disable ramp. | Record the timestamp at 124, 126, and 128 BPM if visible; then hold unchanged playback for 20 seconds. |
| Event-driven | Press Pause after the 20-second post-ramp hold. | Verify that no later click occurs. Leave at least 5 seconds before changing mode. |
| Event-driven | Open Polyrhythm, confirm 3:2 at 120 BPM, and press Play. | Hold for four complete 1-second cycles. |
| Event-driven | Change the playing ratio from 3:2 to 5:4 using the on-screen controls. | Record every tap timestamp; hold 5:4 for four complete 2-second cycles. |
| Event-driven | Change the playing ratio from 5:4 to 15:14 using the on-screen controls. | Record every tap timestamp; hold 15:14 for two complete 7-second cycles. |
| Event-driven | Press Pause. | Capture at least 10 seconds with no later click, then stop both recordings. |

The expected cycle duration is `N × 60 / BPM`: 3:2 is 1 second, 5:4 is 2 seconds, and 15:14 is 7 seconds at 120 BPM.

## Abort and repeat conditions

Repeat the entire run if any of these occur:

- a call, alarm, Siri response, notification sound, or another app produces audio;
- the route leaves the built-in speaker;
- the recorder clips, drops out, changes sample rate, or includes a reference metronome;
- either recording stops before the final silence;
- the app build or starting settings cannot be confirmed;
- the operator accidentally stops playback during a transition that should remain live.

Do not repeat merely because BeatClikr audibly fluctuates. Preserve that run as evidence and repeat only to determine reproducibility.

## Action manifest

Copy this table into the run manifest and replace every `pending` value with the actual screen-recording timestamp. Add rows for every rapid scrub change and every ratio-selector tap.

| Action | Actual timestamp | Value before | Value after | Notes |
| --- | --- | --- | --- | --- |
| Standard Play accepted | pending | stopped | 120/Quarter | |
| Slow tempo change | pending | 120 | 121 | |
| Slow tempo change | pending | 121 | 122 | |
| Slow tempo change | pending | 122 | 123 | |
| Slow tempo change | pending | 123 | 124 | |
| Rapid scrub begins | pending | 124 | variable | |
| Rapid scrub ends | pending | variable | 120 | |
| Groove change | pending | Quarter | Eighth | |
| Groove change | pending | Eighth | Triplet | |
| Groove change | pending | Triplet | Sixteenth | |
| Groove change | pending | Sixteenth | Quarter | |
| Odd-meter change | pending | Quarter | Odd Quarter 7 (3+2+2) | |
| Odd-meter change | pending | Odd Quarter | Odd Eighth 7 (3+2+2) | |
| Beat sound change | pending | Click Hi | Cowbell | |
| Rhythm sound change | pending | Click Lo | Snare | |
| Bank change | pending | Acoustic | Synth | |
| Baseline settings restored | pending | changed | baseline | Record individual changes above this row if separated. |
| Ramp enabled | pending | off | +2 every 8 | |
| Ramp increment observed | pending | 120 | 122 | |
| Ramp increment observed | pending | 122 | 124 | |
| Ramp increment observed | pending | 124 | 126 | |
| Ramp increment observed | pending | 126 | 128 | |
| Ramp disabled | pending | on | off | |
| Standard Pause accepted | pending | playing | stopped | |
| Polyrhythm Play accepted | pending | stopped | 3:2 at 120 | |
| Ratio transition begins | pending | 3:2 | intermediate | Add one row per tap. |
| Ratio transition settles | pending | intermediate | 5:4 | |
| Ratio transition begins | pending | 5:4 | intermediate | Add one row per tap. |
| Ratio transition settles | pending | intermediate | 15:14 | |
| Polyrhythm Pause accepted | pending | playing | stopped | |

## Handoff

Provide the unedited WAV, original screen recording, completed manifest, and BeatClikr log together. Do not trim them to matching start times; clock alignment is part of the analysis.
