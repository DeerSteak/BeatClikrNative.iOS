# Validation

BeatClikr keeps its local and CI validation gates in `scripts/validate.sh`.
UI automation is intentionally excluded from the default workflow.

## Prerequisites

Install the repository tools:

```sh
brew bundle
```

SwiftFormat 0.62.1 is the minimum supported version. Newer compatible
versions are allowed; formatting behavior is controlled by `.swiftformat`.

## Commands

Run every gate:

```sh
scripts/validate.sh all
```

Run one gate:

```sh
scripts/validate.sh format
scripts/validate.sh sounds
scripts/validate.sh debug
scripts/validate.sh release
scripts/validate.sh unit
scripts/validate.sh archive
```

The unit command selects an available iOS simulator automatically. Set
`SIMULATOR_ID` to use a particular device. Set `DERIVED_DATA_PATH` to choose
another build directory. Simulator discovery uses `simctl` JSON and prefers an
available iPhone. CI explicitly selects the latest stable installed Xcode so
the selected developer directory and installed simulator runtimes agree.

## Sound assets

The proprietary WAV files are intentionally excluded from git.
`beatclikr/Resources/Sounds/manifest.txt` is the tracked source of truth.

- A public checkout with no WAV files validates the manifest and skips binary
  presence.
- A partial asset set fails validation.
- Set `REQUIRE_SOUND_ASSETS=1` to require the complete set.
- Present files must be readable, contain at least one audio frame, and match
  the manifest's sample-rate, channel-count, bit-depth, and layout contract.

Release/archive automation that has access to the proprietary files must set
`REQUIRE_SOUND_ASSETS=1`.

Release builds enforce `REQUIRE_SOUND_ASSETS=1` by default, including local
archives intended for App Store submission. The public GitHub workflow sets it
to `0` because the proprietary binaries are intentionally absent; that workflow
still validates the complete machine-readable manifest. A partial sound set
always fails, even in the public-checkout mode.

Archive validation is conditional because it requires signing credentials. Set
`ARCHIVE_VALIDATION=1` in a trusted CI environment with signing configured.
The `all` command reports the gate as skipped when credentials are unavailable.

## Build-time formatting and sandboxing

The Xcode build phase intentionally formats Swift source. It references the
tracked `.swiftformat` configuration. Xcode user-script sandboxing remains
disabled because a source-rewriting build phase must write throughout the
source tree; this is a documented exception rather than an unreviewed default.

CI runs SwiftFormat in lint mode before building, so pull requests fail without
rewriting the checkout.

## Playback performance

Deterministic timing and cache limits run with the unit suite. The manual
Catalyst, Instruments, and TestFlight measurement matrix is documented in
`Docs/PlaybackPerformance.md`.
