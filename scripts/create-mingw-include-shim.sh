#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-$ROOT_DIR/build-windows-x64/mingw-include-shim}"
MINGW_INCLUDE_DIR="${MINGW_INCLUDE_DIR:-/usr/x86_64-w64-mingw32/include}"

if [[ ! -d "$MINGW_INCLUDE_DIR" ]]; then
  echo "Missing MinGW include directory: $MINGW_INCLUDE_DIR" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

mapfile -t HEADERS < <(
  rg -o '#include <[^>]+>' \
    "$ROOT_DIR/Common" \
    "$ROOT_DIR/Core" \
    "$ROOT_DIR/GPU" \
    "$ROOT_DIR/UI" \
    "$ROOT_DIR/Windows" \
    "$ROOT_DIR/SDL" \
    "$ROOT_DIR/Qt" \
    "$ROOT_DIR/android" \
    "$ROOT_DIR/ios" \
    "$ROOT_DIR/headless" \
    "$ROOT_DIR/unittest" \
    "$ROOT_DIR/Tools" \
    -g '!build/**' \
    -g '!SDL/macOS/**' \
  | sed -E 's#^[^:]+:##; s/#include <//; s/>//' \
  | rg '^[^/]*[A-Z][^/]*\.h$' \
  | sort -u
)

for header in "${HEADERS[@]}"; do
  exact_path="$MINGW_INCLUDE_DIR/$header"
  lower_name="$(printf '%s' "$header" | tr 'A-Z' 'a-z')"
  lower_path="$MINGW_INCLUDE_DIR/$lower_name"
  shim_path="$OUTPUT_DIR/$header"

  if [[ -f "$exact_path" ]]; then
    continue
  fi

  if [[ ! -f "$lower_path" ]]; then
    continue
  fi

  ln -sfn "$lower_path" "$shim_path"
done

echo "$OUTPUT_DIR"
