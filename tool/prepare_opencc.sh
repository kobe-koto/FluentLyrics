#!/bin/sh
set -eu

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

# OpenCC is vendored as a git submodule (third_party/opencc) pinned to a tag.
# This script fetches it and trims the working tree to the sources the Flutter
# build actually compiles: the Jieba plugin, tests, benchmarks, docs and the
# unused bundled dependencies are checked out only if you ask for them.
#
# Usage: tool/prepare_opencc.sh [tag]     (default: ver.1.4.2)
VERSION="${1:-ver.1.4.2}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SUBMODULE_PATH="third_party/opencc"
SUBMODULE_DIR="$ROOT_DIR/$SUBMODULE_PATH"

# Directories required to configure and build libopencc. Keep in sync with the
# flags used by tool/build_opencc.sh (and the equivalent native-assets hook).
# `src/tools` (tclap) and DartsDict (darts-clone headers) are built
# unconditionally by OpenCC's CMake, so both dependencies stay checked out even
# though the app only needs the converter library.
SPARSE_PATHS="src data cmake deps/darts-clone-0.32h deps/marisa-0.3.1 deps/rapidjson-1.1.0 deps/tclap-1.2.5"

# Paths that must exist once the checkout is trimmed, checked below so a
# partial checkout fails here instead of inside CMake or the compiler.
REQUIRED_PATHS="src/CMakeLists.txt data/config data/dictionary deps/darts-clone-0.32h/include deps/marisa-0.3.1/include deps/rapidjson-1.1.0 deps/tclap-1.2.5/tclap/CmdLine.h"

require_command git

if [ ! -e "$SUBMODULE_DIR/CMakeLists.txt" ]; then
  echo "Fetching $SUBMODULE_PATH..."
  git -C "$ROOT_DIR" submodule update --init --depth 1 "$SUBMODULE_PATH"
fi

current_version="$(git -C "$SUBMODULE_DIR" describe --tags 2>/dev/null || true)"
if [ "$current_version" != "$VERSION" ]; then
  echo "Pinning $SUBMODULE_PATH to $VERSION..."
  git -C "$SUBMODULE_DIR" fetch --depth 1 origin tag "$VERSION"
  git -C "$SUBMODULE_DIR" checkout --detach "$VERSION"
fi

# `sparse-checkout set` is idempotent and cheap, so it runs unconditionally:
# a plain `git submodule update` (or an existing non-trimmed clone) is trimmed
# here too.
git -C "$SUBMODULE_DIR" sparse-checkout set --cone $SPARSE_PATHS

for path in $REQUIRED_PATHS; do
  if [ ! -e "$SUBMODULE_DIR/$path" ]; then
    echo "error: $SUBMODULE_PATH/$path is missing after checkout" >&2
    exit 1
  fi
done

echo "Prepared OpenCC $(git -C "$SUBMODULE_DIR" describe --tags) ($(git -C "$SUBMODULE_DIR" rev-parse --short HEAD)) in $SUBMODULE_PATH"
