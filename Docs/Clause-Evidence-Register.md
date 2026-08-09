# iOS Clause-to-Evidence Register

**Status:** Phase 0 baseline  
**Android comparator:** `bc1f85b4e08803aa4749c1555adf5ae0d61092c2`  
**iOS baseline:** `38c6f3c5723bc7bcab0ce5c8560f9e8ed8bc4553`  
**Contract source:** Android `Docs/Decisions/0001-Musical-Time.md` and `Docs/Timing-Budgets.md`

This register copies the comparator's normative clauses and budget meanings verbatim. Status describes iOS evidence at the pinned baseline, not Android qualification. `Partial` means relevant iOS evidence exists but does not yet prove the complete clause. `Missing` means no accepted iOS evidence has been assigned.

## Musical-time clauses

| ID | Normative clause | iOS baseline status | Planned evidence destination |
| --- | --- | --- | --- |
| MT-001 | BPM always means quarter notes per minute. | Partial | Pure standard and polyrhythm fixtures |
| MT-002 | The supported tempo range is 30 through 240 BPM inclusive. | Partial | Constants and boundary tests |
| MT-003 | Scheduling and persistence accept decimal BPM values without rounding. Direct slider and increment controls select whole BPM values, matching iOS; imported decimal values remain valid and may be displayed with up to two fractional digits. | Missing | Configuration, persistence, and UI tests |
| MT-004 | Quarter, eighth, triplet, and sixteenth grooves divide each quarter note into one, two, three, or four scheduler ticks. | Partial | Pure standard fixtures |
| MT-005 | An odd-quarter pattern uses quarter-note pattern steps. An odd-eighth pattern uses eighth-note pattern steps. | Partial | Odd-meter fixtures |
| MT-006 | The first step of an odd-meter pattern is always accented. Every subsequent step is accented or unaccented according to its value in the selected pattern. | Partial | Odd-meter fixture matrix |
| MT-007 | Standard playback repeats one sound pattern per quarter note. Tick zero is a beat event and any remaining ticks in that quarter note are subdivision events; the engine does not create a separate measure-level downbeat class. | Partial | Pure event-vocabulary tests |
| MT-008 | In standard playback, tick zero uses the selected beat sound and the remaining ticks use the selected rhythm sound. In odd-meter playback, each `true` pattern step uses the selected beat sound and each `false` step uses the selected rhythm sound. | Partial | Pure sound-role and render tests |
| MT-009 | When alternate sixteenths are enabled, ticks zero and two use the selected beat sound while ticks one and three use the selected rhythm sound. Visual, haptic, and flash feedback still pulse only on tick zero. | Partial | Pure role fixtures and feedback tests |
| MT-010 | The global metronome mute suppresses audio without removing musical events, phase, diagnostics, or enabled secondary-output events. | Missing | Pure mute-continuity and render tests |
| MT-011 | A new standard-metronome session starts at tick zero and its first audible event uses the selected beat sound. | Partial | Pure start and render tests |
| MT-012 | A new polyrhythm session starts both streams at the same cycle origin. | Partial | Pure polyrhythm fixtures |
| MT-013 | Start has no implicit count-in. A future count-in is a separate explicit mode and is not part of the recorded practice duration. | Partial | Coordinator and practice-history tests |
| MT-014 | Stop prevents all not-yet-presented events, ends the current phase, and does not preserve a resumable cursor. | Partial | Lifecycle and render-boundary tests |
| MT-015 | A displayed ratio `M:N` means the rhythm stream emits `M` evenly spaced events while the reference beat stream emits `N` evenly spaced quarter-note events in one cycle. | Partial | Pure 1:1 through 15:15 fixtures |
| MT-016 | A polyrhythm cycle lasts `N` quarter notes. The reference interval is `60 / BPM` seconds and the rhythm interval is `N × 60 / (BPM × M)` seconds. | Partial | Exact polyrhythm fixtures |
| MT-017 | `M` and `N` are independently selectable from 1 through 15 inclusive. | Partial | Model and UI boundary tests |
| MT-018 | Coincident stream events share the same intended sample frame and are mixed once at that frame without serial timing displacement. | Partial | Pure coincidence and render tests |
| MT-019 | A user tempo change during standard playback preserves the pending next event and pattern phase; the new tempo governs subsequent intervals without ending the logical playback period. | Missing | Boundary ADR and pure transition fixtures |
| MT-020 | A groove or odd-meter pattern change during playback preserves the pending next event and current event index; the new complete configuration governs that event and subsequent phase without ending the logical playback period. | Missing | Boundary ADR and pure transition fixtures |
| MT-021 | A polyrhythm tempo or ratio change during playback restarts both streams together at a new shared cycle origin without ending the logical playback period. | Partial | Pure transition and coordinator tests |
| MT-022 | A beat sound, rhythm sound, or sound-bank change prepares the replacement off the render thread and publishes it atomically for subsequently created voices without ending the logical playback period or cutting an active waveform tail. Global mute changes only the renderer's audible gate and does not change musical phase. | Missing | Sound-boundary ADR, concurrency, and render tests |
| MT-023 | Playback commands are serialized in submission order. Every accepted configuration publication is complete, and commands coalesced before one render boundary publish only the final valid configuration. | Missing | Command sequencing and randomized tests |
| MT-024 | Tempo ramp is available only for the instant metronome. It is not applied to song, playlist, or polyrhythm playback. | Partial | View-model and configuration tests |
| MT-025 | The supported ramp increments are 1, 2, 5, and 10 BPM, and the supported intervals are 4, 8, 16, 32, 48, and 64 beat events. | Partial | Constant and fixture matrix |
| MT-026 | Starting playback resets the ramp counter. The initial beat establishes the counter at zero; each subsequent selected interval of beat events raises tempo by the selected increment, capped at 240 BPM. | Partial | Pure ramp fixtures |
| MT-027 | A beat event for ramp counting is tick zero in a standard groove and every accented step in an odd-meter pattern. Subdivision events and alternate-sixteenth offbeats do not advance the counter. | Partial | Pure ramp and odd-meter fixtures |
| MT-028 | Each ramp increment follows the phase-preserving standard tempo update in MT-019 without ending the logical playback period. | Missing | Boundary ADR and pure ramp-transition fixtures |
| MT-029 | Stopping a ramped session restores the tempo captured when that session started. | Partial | View-model lifecycle tests |
| MT-030 | A delayed callback never moves the musical time base and never emits a catch-up burst. | Missing | Exhaustive stall-recovery tests |
| MT-031 | Events whose presentation deadlines have passed are counted and dropped. Phase advances directly to the first future event derived from the original session origin. | Missing | Pure recovery and production diagnostics |
| MT-032 | Integer or rational sample-frame arithmetic carries fractional remainder so that quantization cannot accumulate long-run drift. | Partial | Exact arithmetic and 12-hour qualification |

## Timing and resource budgets

The iOS plan retains Android's metric meanings. Platform-specific thresholds or evidence differences are recorded in the planned destination and must not silently alter the copied budget.

| ID | Metric | Local-route budget | Bluetooth budget | Minimum evidence | iOS baseline status | Planned evidence destination |
| --- | --- | --- | --- | --- | --- | --- |
| TB-001 | Long-run scheduler drift | At most one output sample after 12 simulated hours | Same | Pure scheduler test at every supported sample rate and representative fractional periods | Partial | Permanent pure qualification suite |
| TB-002 | Duplicate intended event frames | Zero, except deliberate coincident polyrhythm events represented as one mixed frame | Same | Property and long-run scheduler tests | Partial | Pure property and coincidence tests |
| TB-003 | Catch-up events after a stall | Zero | Same | Multi-event stall tests | Missing | Exhaustive stall-recovery tests |
| TB-004 | Missed or doubled acoustic events | Zero classified misses or doubles over at least 20 minutes each at low, typical, and maximum density | Application-generated misses or doubles: zero; transport artifacts recorded separately | Automated onset classification and manual anomaly review, backed by a clean one-hour maximum-density render run | Physical pending | Phase 0 recordings and Phase 5 qualification |
| TB-005 | Absolute acoustic inter-onset error | p50 ≤ 1 ms, p95 ≤ 3 ms, p99 ≤ 5 ms, maximum ≤ 10 ms | No end-to-end percentile promise | At least one hour across low, typical, and maximum supported event density | Physical pending | iPhone acoustic qualification |
| TB-006 | Fitted acoustic drift | Application frame drift must meet TB-001; physical fitted drift is observational without a calibrated reference clock | Same | Regression against intended onset series with recorder clock and calibration status disclosed | Partial | Pure drift gate and observational acoustic reports |
| TB-007 | Start latency | p50 ≤ 250 ms, p95 ≤ 300 ms, maximum ≤ 500 ms from accepted play intent to predicted local-route presentation | Report distribution without a fixed gate | At least 30 cold and 30 warm starts per route | Missing | Same-clock production diagnostics and physical qualification |
| TB-008 | Render continuity | Zero application deadline misses, dropped or duplicate events, mixed configurations, or incorrect recovery. Platform-reported underruns must not be repeatable under controlled normal use, cause a detectable acoustic timing defect, or materially regress against matched evidence. | Same application invariants; transport underruns recorded separately | Android stream counters, app diagnostics, repeated runs, and acoustic review when an underrun occurs | Missing | iOS render counters, OS diagnostics, stress runs, and acoustic review |
| TB-009 | Tempo-change boundary | The pending next event remains on the pre-change boundary; subsequent event frames use the new tempo with ≤ one-sample application error | Same application-frame requirement | Boundary fixtures across every groove and odd-meter mode | Missing | Boundary ADR and fixture suite |
| TB-010 | Configuration atomicity | Zero mixed old/new configurations at one boundary | Same | Randomized command-sequence tests | Missing | Pure and production command tests |
| TB-011 | Visual alignment | p95 onset within one display refresh interval of predicted audio presentation | Observational only unless route calibration is available | High-speed video or synchronized instrumentation | Physical pending | iPhone high-speed video qualification |
| TB-012 | Haptic alignment | p95 onset within 25 ms of predicted audio presentation on the reference device | Observational only | External sensor or synchronized recording | Physical pending | iPhone sensor or synchronized observation |
| TB-013 | Flash alignment | p95 onset within 35 ms of predicted audio presentation on the reference device | Observational only | Photodiode or high-speed video | Physical pending | iPhone photodiode or high-speed video qualification |
| TB-014 | Sustained CPU | Mean ≤ 25% and p95 ≤ 35% of one performance core during maximum-density audio-only playback | Same | One-hour low-overhead aggregate profile for the mean, corroborated by sampled diagnostic percentile populations; intrusive populations cannot qualify continuity | Missing | Instruments and low-overhead device metrics |
| TB-015 | Memory stability | Proportional set size growth ≤ 10 MiB over one hour after warm-up | Same | Start, warm-up, periodic, and final samples | Missing | iOS physical resource qualification |
| TB-016 | Thermal behavior | Android thermal status remains below moderate during the one-hour audio-only reference run | Same | Platform thermal status log | Missing | iOS thermal-state log; threshold requires iOS wording approval |
| TB-017 | Battery consumption | ≤ 6 percentage points per hour at documented reference settings | Report separately | One one-hour release sniff check with brightness, route, volume, radio state, and battery health recorded | Missing | iPhone baseline; threshold requires approval after measurement |
| TB-018 | Matched-baseline regression | The qualified Phase 8 release is the current baseline. A future timing- or resource-sensitive change receives one matched sniff check; repeat only an anomaly, near-budget result, or suspected operational regression. | Same application metrics; transport latency remains observational | Identical settings and workloads against the latest qualified baseline; fixed-budget violations or confirmed regressions block release | Missing | Completed iOS qualification baseline and future sniff protocol |

## Reporting rules

Every result records commit, build variant, device, OS build, audio route, sample rate, buffer configuration, tempo, groove or ratio, duration, measurement method, commands, and raw-artifact location. A percentile claim names its population and measurement layer. No application-frame or callback statistic is described as acoustic onset, and no built-in-speaker result is generalized to Bluetooth, USB, or analog output.
