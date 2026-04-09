#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT_DIR/ffmpeg"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-ffmpeg-mingw-x64}"
PREFIX_DIR="${PREFIX_DIR:-$BUILD_DIR/prefix}"
TARGET_PREFIX="${TARGET_PREFIX:-x86_64-w64-mingw32-}"
JOBS="${JOBS:-$(nproc)}"

CONFIGURE_ONLY=0
CLEAN_FIRST=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Build a MinGW-w64 FFmpeg prefix for PPSSPP Windows x64 cross-builds.

Options:
  --configure-only   stop after configure succeeds
  --clean            remove the build directory before configuring
  --build-dir PATH   override the build directory
  --prefix-dir PATH  override the install prefix
  -j, --jobs N       set parallel build jobs
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --configure-only)
      CONFIGURE_ONLY=1
      ;;
    --clean)
      CLEAN_FIRST=1
      ;;
    --build-dir)
      BUILD_DIR="$2"
      shift
      ;;
    --prefix-dir)
      PREFIX_DIR="$2"
      shift
      ;;
    -j|--jobs)
      JOBS="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd make
require_cmd "${TARGET_PREFIX}gcc"
require_cmd "${TARGET_PREFIX}g++"
require_cmd "${TARGET_PREFIX}ar"
require_cmd "${TARGET_PREFIX}ranlib"
require_cmd "${TARGET_PREFIX}nm"
require_cmd "${TARGET_PREFIX}windres"

if [[ ! -x "$SRC_DIR/configure" ]]; then
  echo "FFmpeg source tree is missing or not initialized: $SRC_DIR" >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 1
fi

if [[ "$CLEAN_FIRST" == "1" ]]; then
  rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR" "$PREFIX_DIR"

ABS_SRC_DIR="$(cd "$SRC_DIR" && pwd)"
ABS_PREFIX_DIR="$(mkdir -p "$PREFIX_DIR" && cd "$PREFIX_DIR" && pwd)"

CONFIGURE_ARGS=(
  "--prefix=$ABS_PREFIX_DIR"
  "--arch=x86_64"
  "--target-os=mingw32"
  "--enable-cross-compile"
  "--cross-prefix=$TARGET_PREFIX"
  "--cc=${TARGET_PREFIX}gcc"
  "--cxx=${TARGET_PREFIX}g++"
  "--ar=${TARGET_PREFIX}ar"
  "--ranlib=${TARGET_PREFIX}ranlib"
  "--nm=${TARGET_PREFIX}nm"
  "--pkg-config=/bin/false"
  "--enable-static"
  "--disable-shared"
  "--disable-doc"
  "--disable-programs"
  "--disable-avdevice"
  "--disable-avfilter"
  "--disable-postproc"
  "--disable-pthreads"
  "--enable-w32threads"
  "--disable-network"
  "--disable-bzlib"
  "--disable-iconv"
  "--disable-lzma"
  "--disable-sdl"
  "--disable-xlib"
  "--disable-zlib"
  "--disable-asm"
  "--disable-everything"
  "--disable-encoders"
  "--disable-muxers"
  "--disable-hwaccels"
  "--disable-parsers"
  "--disable-protocols"
  "--enable-dxva2"
  "--enable-decoder=aac"
  "--enable-decoder=aac_latm"
  "--enable-decoder=atrac3"
  "--enable-decoder=atrac3p"
  "--enable-decoder=mp3"
  "--enable-decoder=pcm_s16le"
  "--enable-decoder=pcm_s8"
  "--enable-decoder=h264"
  "--enable-decoder=mpeg4"
  "--enable-decoder=mpeg2video"
  "--enable-decoder=mjpeg"
  "--enable-decoder=mjpegb"
  "--enable-encoder=pcm_s16le"
  "--enable-encoder=ffv1"
  "--enable-encoder=mpeg4"
  "--enable-hwaccel=h264_dxva2"
  "--enable-muxer=avi"
  "--enable-demuxer=h264"
  "--enable-demuxer=m4v"
  "--enable-demuxer=mp3"
  "--enable-demuxer=mpegvideo"
  "--enable-demuxer=mpegps"
  "--enable-demuxer=mjpeg"
  "--enable-demuxer=avi"
  "--enable-demuxer=aac"
  "--enable-demuxer=pmp"
  "--enable-demuxer=oma"
  "--enable-demuxer=pcm_s16le"
  "--enable-demuxer=pcm_s8"
  "--enable-demuxer=wav"
  "--enable-parser=h264"
  "--enable-parser=mpeg4video"
  "--enable-parser=mpegaudio"
  "--enable-parser=mpegvideo"
  "--enable-parser=mjpeg"
  "--enable-parser=aac"
  "--enable-parser=aac_latm"
  "--enable-protocol=file"
)

pushd "$BUILD_DIR" >/dev/null
echo "Configuring FFmpeg in $BUILD_DIR"
"$ABS_SRC_DIR/configure" "${CONFIGURE_ARGS[@]}" | tee "$BUILD_DIR/configure.log"

if [[ "$CONFIGURE_ONLY" == "1" ]]; then
  popd >/dev/null
  echo
  echo "Configure succeeded."
  echo "FFMPEG_DIR=$ABS_PREFIX_DIR"
  exit 0
fi

echo "Building FFmpeg with $JOBS jobs"
make -j"$JOBS" | tee "$BUILD_DIR/make.log"

echo "Installing FFmpeg into $ABS_PREFIX_DIR"
make install | tee "$BUILD_DIR/install.log"
popd >/dev/null

cat <<EOF

FFmpeg MinGW prefix ready:
  $ABS_PREFIX_DIR

Use it like this:
  export FFMPEG_DIR="$ABS_PREFIX_DIR"
  ./scripts/build-windows-cross.sh
EOF
