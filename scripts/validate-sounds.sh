#!/bin/bash

set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
SOUNDS_ROOT="${SOUNDS_ROOT:-$PROJECT_ROOT/beatclikr/Resources/Sounds}"
MANIFEST="${SOUND_MANIFEST:-$SOUNDS_ROOT/manifest.txt}"
REQUIRE_SOUND_ASSETS="${REQUIRE_SOUND_ASSETS:-0}"

if [[ ! -f "$MANIFEST" ]]; then
    echo "error: Sound manifest is missing: $MANIFEST"
    exit 1
fi

expected_count=0
present_count=0
missing_files=()
declared_paths=()

while IFS=$'\t' read -r relative_path expected_rate expected_channels expected_depth expected_layout extra || [[ -n "${relative_path:-}" ]]; do
    [[ -z "${relative_path:-}" || "$relative_path" == \#* ]] && continue

    if [[ -n "${extra:-}" || -z "$expected_rate" || -z "$expected_channels" || -z "$expected_depth" || -z "$expected_layout" ]]; then
        echo "error: Malformed sound manifest row for: $relative_path"
        exit 1
    fi
    if [[ "$relative_path" == /* || "$relative_path" == *".."* || "$relative_path" != *.wav ]]; then
        echo "error: Invalid sound manifest path: $relative_path"
        exit 1
    fi
    for declared_path in "${declared_paths[@]:-}"; do
        if [[ "$declared_path" == "$relative_path" ]]; then
            echo "error: Duplicate sound manifest path: $relative_path"
            exit 1
        fi
    done
    declared_paths+=("$relative_path")
    expected_count=$((expected_count + 1))

    asset_path="$SOUNDS_ROOT/$relative_path"
    if [[ ! -f "$asset_path" ]]; then
        missing_files+=("$relative_path")
        continue
    fi

    present_count=$((present_count + 1))
    if [[ ! -s "$asset_path" ]]; then
        echo "error: Sound asset is empty: $relative_path"
        exit 1
    fi

    info="$(afinfo "$asset_path" 2>/dev/null)" || {
        echo "error: Sound asset is not readable audio: $relative_path"
        exit 1
    }

    actual_channels="$(sed -n 's/.*Data format:[[:space:]]*\([0-9][0-9]*\) ch,.*/\1/p' <<< "$info" | head -n 1)"
    actual_rate="$(sed -n 's/.*Data format:.*,[[:space:]]*\([0-9][0-9]*\) Hz,.*/\1/p' <<< "$info" | head -n 1)"
    actual_depth="$(sed -n 's/.*source bit depth:[[:space:]]*I\([0-9][0-9]*\).*/\1/p' <<< "$info" | head -n 1)"
    actual_frames="$(sed -n 's/.*audio packets:[[:space:]]*\([0-9][0-9]*\).*/\1/p' <<< "$info" | head -n 1)"

    if [[ -z "$actual_channels" || -z "$actual_rate" || -z "$actual_depth" || -z "$actual_frames" ]]; then
        echo "error: Could not read the audio contract for: $relative_path"
        exit 1
    fi
    if [[ "$actual_frames" -le 0 ]]; then
        echo "error: Sound asset contains no audio frames: $relative_path"
        exit 1
    fi
    if [[ "$actual_rate" != "$expected_rate" ]]; then
        echo "error: $relative_path has sample rate $actual_rate Hz; expected $expected_rate Hz."
        exit 1
    fi
    if [[ "$actual_channels" != "$expected_channels" ]]; then
        echo "error: $relative_path has $actual_channels channel(s); expected $expected_channels."
        exit 1
    fi
    if [[ "$actual_depth" != "$expected_depth" ]]; then
        echo "error: $relative_path has $actual_depth-bit audio; expected $expected_depth-bit."
        exit 1
    fi
    if [[ "$expected_layout" == "mono" && "$actual_channels" != "1" ]] ||
        [[ "$expected_layout" == "stereo" && "$actual_channels" != "2" ]]; then
        echo "error: $relative_path does not match its declared $expected_layout layout."
        exit 1
    fi
done < "$MANIFEST"

if [[ "$expected_count" -eq 0 ]]; then
    echo "error: Sound manifest contains no assets."
    exit 1
fi

if [[ "$present_count" -eq 0 && "$REQUIRE_SOUND_ASSETS" != "1" ]]; then
    echo "Sound manifest contract valid ($expected_count expected files); binary presence skipped for the public checkout."
    exit 0
fi

if [[ "${#missing_files[@]}" -gt 0 ]]; then
    echo "error: ${#missing_files[@]} required sound asset(s) are missing:"
    printf '  %s\n' "${missing_files[@]}"
    exit 1
fi

echo "Validated $expected_count required sound assets (readable, nonempty, 44.1 kHz, 16-bit stereo)."
