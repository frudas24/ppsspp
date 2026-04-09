#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-windows-x64}"
GENERATOR="${GENERATOR:-Ninja}"
USE_FFMPEG="${USE_FFMPEG:-ON}"
DEFAULT_FFMPEG_DIR="$ROOT_DIR/build-ffmpeg-mingw-x64/prefix"
SHIM_DIR="${SHIM_DIR:-$BUILD_DIR/mingw-include-shim}"

if [[ "$USE_FFMPEG" != "OFF" && -z "${FFMPEG_DIR:-}" && -f "$DEFAULT_FFMPEG_DIR/include/libavcodec/avcodec.h" ]]; then
  FFMPEG_DIR="$DEFAULT_FFMPEG_DIR"
fi

mkdir -p "$BUILD_DIR"
"$ROOT_DIR/scripts/create-mingw-include-shim.sh" "$SHIM_DIR" >/dev/null

if [[ "$USE_FFMPEG" != "OFF" && -z "${FFMPEG_DIR:-}" ]]; then
  cat <<'EOF'
FFMPEG is enabled for the Windows cross-build, but FFMPEG_DIR is not set.

Export FFMPEG_DIR to a MinGW-w64-compatible FFmpeg prefix that contains:
  include/libavcodec/avcodec.h
  lib/libavcodec.a
  lib/libavformat.a
  lib/libavutil.a
  lib/libswresample.a
  lib/libswscale.a

Example:
  export FFMPEG_DIR=/opt/ffmpeg-mingw/x86_64-w64-mingw32

Or build it locally with:
  ./scripts/build-ffmpeg-mingw-x64.sh
EOF
  exit 1
fi

CMAKE_ARGS=(
  -S "$ROOT_DIR"
  -B "$BUILD_DIR"
  -G "$GENERATOR"
  -DCMAKE_TOOLCHAIN_FILE="$ROOT_DIR/cmake/Toolchains/mingw-w64-x86_64.cmake"
  -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
  -DUSE_FFMPEG="$USE_FFMPEG"
  -DUSE_SYSTEM_LIBSDL2=OFF
  -DCMAKE_C_FLAGS="-I$SHIM_DIR"
  -DCMAKE_CXX_FLAGS="-I$SHIM_DIR"
)

if [[ -n "${FFMPEG_DIR:-}" ]]; then
  CMAKE_ARGS+=(-DFFMPEG_DIR="$FFMPEG_DIR")
fi

cmake "${CMAKE_ARGS[@]}" "$@"

cmake --build "$BUILD_DIR" -j"$(nproc)"
