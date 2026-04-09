#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

NATIVE_PACKAGES=(
  build-essential
  cmake
  ninja-build
  ccache
  pkg-config
  python3
  libsdl2-dev
  libsdl2-ttf-dev
  libfontconfig1-dev
  libgl1-mesa-dev
  libglu1-mesa-dev
)

WINDOWS_PACKAGES=(
  mingw-w64
  g++-mingw-w64-x86-64
  binutils-mingw-w64-x86-64
  wine64
)

ALL_PACKAGES=("${NATIVE_PACKAGES[@]}" "${WINDOWS_PACKAGES[@]}")

print_install_command() {
  printf 'sudo apt-get update && sudo apt-get install -y'
  for pkg in "${ALL_PACKAGES[@]}"; do
    printf ' %s' "$pkg"
  done
  printf '\n'
}

if [[ "${1:-}" == "--print-only" ]]; then
  print_install_command
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
  echo "Run this with sudo, or copy/paste:"
  print_install_command
  exit 1
fi

apt-get update
apt-get install -y "${ALL_PACKAGES[@]}"

cat <<EOF

Native Linux build:
  cd "$ROOT_DIR"
  git submodule update --init --recursive
  ./b.sh

Windows x64 cross-build:
  cd "$ROOT_DIR"
  git submodule update --init --recursive
  export FFMPEG_DIR=/path/to/mingw-ffmpeg-prefix
  ./scripts/build-windows-cross.sh
EOF
