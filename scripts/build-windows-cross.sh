#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-windows-x64}"
GENERATOR="${GENERATOR:-Ninja}"
USE_FFMPEG="${USE_FFMPEG:-ON}"

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
EOF
  exit 1
fi

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" -G "$GENERATOR" \
  -DCMAKE_TOOLCHAIN_FILE="$ROOT_DIR/cmake/Toolchains/mingw-w64-x86_64.cmake" \
  -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}" \
  -DUSE_FFMPEG="$USE_FFMPEG" \
  -DUSE_SYSTEM_LIBSDL2=OFF \
  "$@"

cmake --build "$BUILD_DIR" -j"$(nproc)"
