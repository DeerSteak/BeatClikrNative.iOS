#!/bin/bash

set -euo pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
SOUNDS_ROOT="$PROJECT_ROOT/beatclikr/Resources/Sounds"
MANIFEST="$SOUNDS_ROOT/manifest.txt"
REQUIRE_SOUND_ASSETS="${REQUIRE_SOUND_ASSETS:-0}"

if [[ ! -f "$MANIFEST" ]]; then
    echo "error: Sound manifest is missing: $MANIFEST"
    exit 1
fi

mapfile_compatible_read() {
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        printf '%s\n' "$line"
    done < "$MANIFEST"
}

expected_files=()
while IFS= read -r relative_path; do
    expected_files+=("$relative_path")
done < <(mapfile_compatible_read)

if [[ "${#expected_files[@]}" -eq 0 ]]; then
    echo "error: Sound manifest contains no assets."
    exit 1
fi

present_count=0
missing_files=()
for relative_path in "${expected_files[@]}"; do
    asset_path="$SOUNDS_ROOT/$relative_path"
    if [[ -f "$asset_path" ]]; then
        present_count=$((present_count + 1))
        if [[ ! -s "$asset_path" ]]; then
            echo "error: Sound asset is empty: $relative_path"
            exit 1
        fi
        if command -v afinfo >/dev/null && ! afinfo "$asset_path" >/dev/null 2>&1; then
            echo "error: Sound asset is not readable audio: $relative_path"
            exit 1
        fi
    else
        missing_files+=("$relative_path")
    fi
done

if [[ "$present_count" -eq 0 && "$REQUIRE_SOUND_ASSETS" != "1" ]]; then
    echo "Sound manifest valid (${#expected_files[@]} expected files); binary presence skipped for the public checkout."
    exit 0
fi

if [[ "${#missing_files[@]}" -gt 0 ]]; then
    echo "error: ${#missing_files[@]} required sound asset(s) are missing:"
    printf '  %s\n' "${missing_files[@]}"
    exit 1
fi

echo "Validated ${#expected_files[@]} required sound assets."
