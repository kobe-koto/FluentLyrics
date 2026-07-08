#!/bin/bash
set -euo pipefail

VERSION_STRING=$(echo "$RELEASE_VERSION" | sed 's/^v//')
IFS='+'
read -r -a parts <<< "$VERSION_STRING"
unset IFS

VERSION_NAME="${parts[0]}"
VERSION_CODE="${parts[1]:-}"

DIST_DIR="dist/$VERSION_STRING"
if [ ! -d "$DIST_DIR" ] && [ -n "$VERSION_CODE" ] && [ -d "dist/$VERSION_NAME+$VERSION_CODE" ]; then
    DIST_DIR="dist/$VERSION_NAME+$VERSION_CODE"
fi

if [ ! -d "$DIST_DIR" ]; then
    for dir in dist/*; do
        [ -d "$dir" ] || continue
        DIST_DIR="$dir"
        break
    done
fi

mkdir -p "$DIST_DIR"
