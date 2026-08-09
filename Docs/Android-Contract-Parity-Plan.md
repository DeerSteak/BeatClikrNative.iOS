# Android Contract Parity Plan for iOS

**Status:** Proposed weekly execution plan  
**Created:** 2026-08-08  
**Source of truth:** Android musical contracts MT-001 through MT-032 and timing budgets TB-001 through TB-018

## Objective

Make iOS playback as explicit, deterministic, observable, and qualified as Android without copying Android platform mechanics into AVFoundation. The first release gate is tempo trust: unchanged playback must not accumulate drift, and live changes or stalls must not cause missing, doubled, bunched, or out-of-order clicks.

This work extends the existing iOS absolute-sample rolling-buffer design. It does not assume that the current design is wrong, but it requires every product promise to have a named contract, deterministic test, production-path diagnostic, and appropriately scoped physical measurement.

## Findings that set the order

- Static iOS playback already derives rolling blocks from an absolute sample origin and has useful offline tests for fractional periods, accents, polyrhythm coincidence, and multi-hour playback.
- `AbsoluteAudioTimeline` stores a `Double` period rather than the Android exact normalized rational representation.
- Tempo changes in `ScheduledMetronomeEngine` currently stop both player nodes and restart with a new delayed origin. The existing action plan records extra clicks during rapid slider movement and leaves transition-boundary behavior deferred.
- Buffer planning, mixing, delegate scheduling, and refill dispatch are main-actor work. Failed block planning and capacity failures can return without a typed terminal outcome.
- iOS does not yet expose intended, rendered, scheduled, and estimated-presented frame records; deadline misses; dropped events; stale events; duplicate frames; or mixed-configuration counters from production playback.
- The coordinator enforces one active mode, but commands are not immutable, sequenced, session-tagged publications with stale-result rejection comparable to Android.
- The current iOS performance matrix is largely unmeasured, and there is no iPhone acoustic baseline equivalent to Android Phase 8.

## Porting rule

Reuse Android contract IDs and fixture meanings so parity stays reviewable. Copy product behavior and validation intent, not `AudioTrack` implementation details.

- `MT-*` clauses are shared unless a short iOS ADR records a deliberate product or platform divergence.
- `TB-001` through `TB-015` and `TB-018` retain their metric meanings, with iOS-native instrumentation and hardware facts.
- `TB-016` uses iOS thermal state rather than Android thermal status.
- `TB-017` must receive an iPhone-specific battery threshold after a baseline; Android's percentage-point limit is not adopted without evidence.
- Bluetooth has application-frame correctness gates but no deterministic acoustic-latency promise.
- Android's approved phase-preserving behavior for MT-019, MT-020, and MT-028 is the proposed cross-platform target. If iOS intentionally retains restart behavior, approve and document that divergence before implementation.

## Phase 0 — Freeze scope and capture the suspected fluctuation

**Purpose:** preserve evidence before changing the scheduler and distinguish application timing defects from route or recording artifacts.

- [x] Record the Android source commit and copy MT-001 through MT-032 and TB-001 through TB-018 into an iOS clause-to-evidence register without paraphrasing away their meaning.
- [ ] Record the iOS source commit, Xcode and Swift versions, iPhone model, iOS build, route, sample rate, I/O buffer duration, app settings, and exact measurement commands.
- [ ] Choose one supported physical iPhone and built-in speaker as the initial reference environment.
- [ ] Capture at least 20 minutes each at 30 BPM quarter notes, 120 BPM eighth notes, and 240 BPM sixteenth notes.
- [ ] Capture 15:14 and representative equal/shared-factor polyrhythms.
- [ ] Run a focused live-change capture with slow and rapid tempo, groove, meter, sound, ramp, and mode changes.
- [ ] Classify each perceived fluctuation as intended-frame error, render/schedule discontinuity, presentation/route variance, measurement artifact, or unknown.
- [ ] Preserve raw audio, onset data, application logs, screen recordings when relevant, and a concise baseline summary.

**Exit gate**

- [ ] The reported fluctuation has a reproducible scenario or is explicitly recorded as not yet reproduced.
- [ ] No implementation work begins without a pinned comparator and unchanged baseline artifacts.

## Phase 1 — Adopt the contracts and shared fixtures

**Purpose:** decide behavior before tests accidentally preserve the current implementation.

### 1.1 Create iOS ADRs and the evidence register

- [ ] Add an iOS musical-time ADR containing MT-001 through MT-032 and the approved iOS divergences, if any.
- [ ] Resolve MT-019, MT-020, and MT-028 explicitly: phase-preserving standard updates are preferred for parity; a restart requires product approval and its own boundary budget.
- [ ] Define the audible boundary for sound and bank changes, mute, rapid coalesced commands, and static/ramp transitions.
- [ ] Define stall recovery: expired events are counted and dropped, the origin is preserved, and catch-up bursts are prohibited.
- [ ] Add an iOS timing-budget document mapping every TB metric to pure, render, application, acoustic, visual, haptic, flash, resource, or lifecycle evidence.
- [ ] Add a clause-to-test/evidence table with `Missing`, `Partial`, `Pass`, `Physical pending`, and `Intentional divergence` statuses.

### 1.2 Port reusable fixtures

- [ ] Port Android's resource-independent standard, accent, polyrhythm, and ramp fixtures into Swift test support.
- [ ] Preserve contract IDs in test names or metadata.
- [ ] Cover 30–240 BPM, valid decimal tempos, all subdivisions, all odd-meter patterns, alternate sixteenths, mute continuity, tick-zero starts, and stop/reset.
- [ ] Cover every M:N pair from 1 through 15, including equal, coprime, and shared-factor ratios.
- [ ] Cover ramp increments 1, 2, 5, and 10 and intervals 4, 8, 16, 32, 48, and 64.

**Exit gate**

- [ ] Every MT clause and TB validation point has an owner, planned evidence layer, and test or artifact destination.
- [ ] Fixture tests characterize behavior without changing production audio.

## Phase 2 — Build an AVFoundation-free musical core

**Purpose:** make the hard timing promises executable without devices, audio engines, wall-clock sleeps, or main-actor scheduling.

### 2.1 Exact models and event vocabulary

- [ ] Introduce an exact normalized rational tempo/frame-period type with checked overflow and canonical equality.
- [ ] Define immutable standard and polyrhythm configurations independent of AVFoundation, SwiftUI, persistence, user defaults, and resource names.
- [ ] Define a frame event with session ID, event sequence, intended absolute frame, role, sound role, accent/beat identity, cycle position, and mute state.
- [ ] Define immutable typed commands with session ID, command sequence, submission time, and complete payload.
- [ ] Add an architecture test preventing the pure module from importing AVFoundation, UIKit, SwiftUI, persistence, or singleton services.

### 2.2 Pure timelines and boundaries

- [ ] Generate standard events intersecting arbitrary absolute frame ranges using independently rounded exact positions.
- [ ] Generate both polyrhythm voices from one cycle origin and represent coincident events at one exact frame.
- [ ] Preserve event identity and phase across adjacent render ranges.
- [ ] Implement the approved MT-019/MT-020 boundary while retaining the pending next event and event index.
- [ ] Restart polyrhythm changes at one new shared cycle origin per MT-021.
- [ ] Publish prepared sound snapshots and mute changes atomically without resetting phase or cutting existing tails.
- [ ] Make ramp steps deterministic musical commands and prove the static/ramp transition boundary.

### 2.3 Deadline recovery

- [ ] Select the first future event arithmetically after a stall rather than enumerating every missed event.
- [ ] Count expired and dropped events without emitting a catch-up burst.
- [ ] Prove recovery cannot duplicate a frame, move the session origin, revive a stale session, or retain an invalid waveform tail.

### 2.4 Permanent pure qualification

- [ ] Add one named qualification suite analogous to Android `PureCoreQualificationTest`.
- [ ] Simulate at least 12 hours at minimum, awkward fractional, typical, maximum-density, and dense-polyrhythm settings at 44.1 and 48 kHz plus every sample rate the production boundary accepts.
- [ ] Inject multi-event stalls at every event position.
- [ ] Run reproducible randomized command sequences and assert configuration atomicity.
- [ ] Assert MT-001 through MT-032 and TB-001 through TB-003, TB-009, and TB-010.

**Exit gate**

- [ ] Twelve-hour drift is at most one frame, intended frames have no unintended duplicates, and stalls produce no catch-up events.
- [ ] The permanent suite runs in the ordinary local and CI unit-test gate.

## Phase 3 — Make one production render path authoritative

**Purpose:** render the pure frame timeline through AVFoundation without handing musical time to callbacks or the main thread.

### 3.1 Define the render boundary

- [ ] Introduce a narrow backend port for opening, starting, scheduling/rendering frame ranges, stopping, timestamping, route facts, and typed failures.
- [ ] Move planning and PCM mixing off the main actor; keep UI publication and control serialization outside the real-time or refill-critical section.
- [ ] Request pure events for each output range and mix at exact frame offsets.
- [ ] Carry click tails across render blocks and define saturating mix behavior for overlap and coincidence.
- [ ] Predecode, convert, validate, and publish complete immutable sound banks off the render path.
- [ ] Eliminate silent `try?`/early-return scheduling failures; translate them to typed session-tagged failures.

### 3.2 Replace restart-on-change safely

- [ ] Build configuration replacements away from active playback and publish them at the approved frame boundary.
- [ ] Preserve the running engine and pending next event for standard tempo, groove, pattern, and ramp changes if MT-019/MT-020/MT-028 are adopted.
- [ ] Cancel or coalesce obsolete rapid-change commands by sequence while publishing only complete configurations.
- [ ] Keep one logical session through valid changes and reject stale completion handlers from older generations.
- [ ] Prove rapid slider movement cannot double, omit, reorder, or leak old-configuration clicks.

### 3.3 Correlate production timing

- [ ] Record intended, rendered, scheduled, and estimated-presented frames in bounded preallocated storage.
- [ ] Correlate AVAudio node/player time and host time only through a documented consistent snapshot.
- [ ] Record obtained sample rate, channel layout, I/O buffer duration, presentation latency, route, route changes, render/refill duration percentiles, stale callbacks, deadline misses, drops, duplicates, and discontinuities.
- [ ] Export diagnostics off the audio path with bounded memory and privacy-safe content.
- [ ] Verify diagnostics do not create glitches or continuing allocations.

**Exit gate**

- [ ] Static and live-change playback use the pure frame timeline as their only musical-time authority.
- [ ] Production diagnostics can distinguish scheduler, render/schedule, and estimated-presentation behavior.
- [ ] No main-thread callback or completion handler determines the next musical event's intended frame.

## Phase 4 — Port authoritative playback and lifecycle contracts

**Purpose:** ensure timing correctness survives commands, navigation, interruptions, routes, and process lifecycle.

- [ ] Serialize start, stop, mode replacement, configuration, sound, mute, and ramp intents on one control executor.
- [ ] Expand transport state to immutable `idle`, `preparing`, `starting`, `playing`, `stopping`, `interrupted`, and `failed` states with legal transitions.
- [ ] Enter `playing` only after sounds, route/session, engine, and first authoritative frame are committed.
- [ ] Tag engine callbacks, route events, interruption events, preparation completions, and stop acknowledgements with session identity and reject stale work.
- [ ] Make start and stop idempotent and mode replacement atomic without two active engines.
- [ ] Publish one replayable transport stream and one ordered committed-event stream for UI, practice accounting, effects, and diagnostics.
- [ ] Derive visual, haptic, and flashlight events from committed audio events; make secondary failures nonfatal to audio.
- [ ] Preserve the approved iOS mixing, background, lock-screen, interruption, route-loss, and explicit-restart policies.
- [ ] Test rapid start/stop/start, replacement during preparation, interruption during start, media-services reset, route change/loss, background/foreground, lock, and stale cross-thread callbacks.

**Exit gate**

- [ ] At most one physical playback session and one mode exist after every serialized command sequence.
- [ ] UI and practice accounting never infer playback authority from a request or view lifecycle.
- [ ] Lifecycle changes cannot revive old audio, leak queued clicks, or leave false `playing` state.

## Phase 5 — Qualify on simulator, Catalyst, and physical iPhone

**Purpose:** turn contracts into release evidence while keeping platform and measurement claims honest.

### 5.1 Automated and offline gates

- [ ] Run the pure qualification suite, render/mix tests, command-race tests, lifecycle tests, asset tests, full unit suite, format check, Debug build, and Release build in CI.
- [ ] Add offline onset detection for standard, accents, odd meters, alternate sixteenths, all polyrhythm ratios, click tails, ramps, live changes, and stall recovery.
- [ ] Add a short physical smoke test for ordinary timing changes and a five-minute stress test for the major scheduler integration.

### 5.2 Physical timing qualification

- [ ] Run at least 20 minutes each at low, typical, and maximum density on the reference iPhone built-in speaker.
- [ ] Run a clean one-hour maximum-density render/diagnostic test and representative polyrhythm test.
- [ ] Measure 30 cold and 30 warm starts using one clock domain.
- [ ] Run randomized UI/control stress while verifying one session, no premature physical stop, no mixed configurations, and exact event accounting.
- [ ] Record acoustic onset populations, missed/doubled classifications, inter-onset error percentiles, fitted drift, and recorder-clock limitations.
- [ ] Measure visual, haptic, and flash alignment separately and label them observational unless calibrated.
- [ ] Exercise speaker, wired/USB when available, AirPods/Bluetooth, silent switch, background, lock, interruption, route loss/change, and media-services reset without generalizing unavailable routes.

### 5.3 Resource and regression qualification

- [ ] Record one-hour CPU mean/p95, resident-memory growth after warm-up, `ProcessInfo.thermalState`, allocation behavior, and audio continuity with low-overhead collection.
- [ ] Run one controlled unplugged battery baseline with brightness, volume, route, radios, battery health, and settings recorded and restored afterward.
- [ ] Set iOS TB-014 through TB-017 thresholds only after reviewing the baseline; record approved differences from Android.
- [ ] Establish the completed iOS run as the TB-018 matched baseline for future timing-sensitive changes.

**Exit gate**

- [ ] MT-001 through MT-032 and TB-001 through TB-018 are `Pass`, `Observational pass`, or approved `Intentional divergence`; none remain silently untested.
- [ ] No classified application miss, double, catch-up burst, mixed configuration, incorrect recovery, or long-run drift failure remains.
- [ ] Raw artifacts and a concise qualification summary are versioned or stored at a documented durable location.

## Proposed week sequence

### Day 1 — Contracts and baseline

- [ ] Complete Phase 0 environment capture and reproduce the tempo fluctuation.
- [ ] Create the clause-to-evidence register and decide MT-019, MT-020, and MT-028.
- [ ] Pin the Android comparator and port fixture representations.

### Day 2 — Pure musical core

- [ ] Implement exact tempo/configuration/event types and standard/polyrhythm frame timelines.
- [ ] Port standard, accent, and polyrhythm fixture tests.

### Day 3 — Recovery, ramp, and qualification

- [ ] Implement deadline recovery, ramp state, boundary commands, and randomized tests.
- [ ] Land the permanent 12-hour pure qualification gate.

### Day 4 — Production integration

- [ ] Feed the pure timeline into one AVFoundation render/schedule path.
- [ ] Add session-tagged command serialization, stale rejection, and bounded frame diagnostics.
- [ ] Run the targeted five-minute physical scheduler stress test.

### Day 5 — Qualification and decision

- [ ] Run the focused acoustic populations and live-change stress on the reference iPhone.
- [ ] Compare against the pinned baseline and Android budgets at the correct measurement layer.
- [ ] Document passes, failures, deferred route evidence, and the next implementation slice.

The week is successful if the pure contract and production observability foundations are complete and the suspected fluctuation is classified. Full one-hour acoustic, resource, battery, and route qualification may continue after the week; it must not be compressed into weak evidence to satisfy the calendar.

## First implementation slice

Start with Phase 0 and Phase 1 only. Do not change `ScheduledMetronomeEngine` until the baseline is captured, the boundary ADR is approved, shared fixtures fail for the intended reasons, and every timing result can name its clock and measurement layer.
