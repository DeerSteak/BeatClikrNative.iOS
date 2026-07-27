#!/bin/bash

set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/beatclikr.xcodeproj"
SCHEME="beatclikr"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-${RUNNER_TEMP:-/tmp}/BeatClikrValidationDerivedData}"

run_format_check() {
    command -v swiftformat >/dev/null || {
        echo "error: SwiftFormat 0.62.1 or newer is required. Run: brew bundle"
        return 1
    }
    swiftformat "$PROJECT_ROOT" \
        --config "$PROJECT_ROOT/.swiftformat" \
        --lint \
        --cache ignore
    git -C "$PROJECT_ROOT" diff --check
}

run_sound_check() {
    "$SCRIPT_DIRECTORY/validate-sounds.sh"
}

run_build() {
    local configuration="$1"
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$configuration" \
        -destination "generic/platform=iOS Simulator" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        CODE_SIGNING_ALLOWED=NO \
        build
}

find_simulator_id() {
    if [[ -n "${SIMULATOR_ID:-}" ]]; then
        printf '%s\n' "$SIMULATOR_ID"
        return
    fi

    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -showdestinations |
        sed -n '/platform:iOS Simulator/ {
            /placeholder/! {
                s/.*id:\([^,}]*\).*/\1/p
            }
        }' |
        head -n 1 |
        xargs
}

run_unit_tests() {
    local simulator_id
    simulator_id="$(find_simulator_id)"
    if [[ -z "$simulator_id" ]]; then
        echo "error: No available iOS Simulator destination was found."
        return 1
    fi

    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration Debug \
        -destination "platform=iOS Simulator,id=$simulator_id" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -parallel-testing-enabled NO \
        -only-testing:beatclikrTests \
        test
}

run_archive_check() {
    if [[ "${ARCHIVE_VALIDATION:-0}" != "1" ]]; then
        echo "Archive validation skipped; set ARCHIVE_VALIDATION=1 when signing is configured."
        return
    fi

    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        archive
}

usage() {
    echo "Usage: scripts/validate.sh [all|format|sounds|debug|release|unit|archive]"
}

cd "$PROJECT_ROOT"

case "${1:-all}" in
    all)
        run_format_check
        run_sound_check
        run_build Debug
        run_build Release
        run_unit_tests
        run_archive_check
        ;;
    format)
        run_format_check
        ;;
    sounds)
        run_sound_check
        ;;
    debug)
        run_build Debug
        ;;
    release)
        run_build Release
        ;;
    unit)
        run_unit_tests
        ;;
    archive)
        run_archive_check
        ;;
    *)
        usage
        exit 64
        ;;
esac
