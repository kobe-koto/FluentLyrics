#!/bin/sh
set -eu

# Builds libopencc for the host platform (Linux/macOS dev machines) so that
# `flutter test` and local runs can use it. App builds for Android/Linux/macOS
# go through the platform build systems or the native-assets hook, which reuse
# the same CMake flags.
#
# Usage: tool/build_opencc.sh
# Env:
#   OPENCC_DICT_FORMAT  text (default) | ocd2
#   OPENCC_BUILD_TYPE   Release (default) | Debug
#
# Output: build/opencc/out/{lib,share/opencc}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="$ROOT_DIR/third_party/opencc"
BUILD_DIR="$ROOT_DIR/build/opencc/build"
OUT_DIR="$ROOT_DIR/build/opencc/out"

DICT_FORMAT="${OPENCC_DICT_FORMAT:-text}"
BUILD_TYPE="${OPENCC_BUILD_TYPE:-Release}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

require_command cmake

# Make sure the pinned sources are checked out and trimmed.
"$ROOT_DIR/tool/prepare_opencc.sh"

GENERATOR=""
if command -v ninja >/dev/null 2>&1; then
  GENERATOR="-G Ninja"
fi

# shellcheck disable=SC2086
cmake -S "$SRC_DIR" -B "$BUILD_DIR" $GENERATOR \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DBUILD_SHARED_LIBS=ON \
  -DOPENCC_ENABLE_INSTALL=ON \
  -DCMAKE_INSTALL_PREFIX="$OUT_DIR" \
  -DOPENCC_DICT_FORMAT="$DICT_FORMAT" \
  -DENABLE_GTEST=OFF \
  -DENABLE_BENCHMARK=OFF \
  -DBUILD_DOCUMENTATION=OFF \
  -DBUILD_PYTHON=OFF \
  -DBUILD_OPENCC_JIEBA_PLUGIN=OFF

cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --target install

echo "Built libopencc ($DICT_FORMAT dictionaries) into ${OUT_DIR#$ROOT_DIR/}"
