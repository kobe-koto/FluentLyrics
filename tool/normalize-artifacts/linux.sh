#!/bin/bash

# generic
source "$(dirname "$0")/generic.sh"

# Linux
if command -v rename.ul >/dev/null 2>&1; then
    RENAME_CMD="rename.ul"
elif command -v rename >/dev/null 2>&1 && rename --version 2>&1 | grep -q 'util-linux'; then
    RENAME_CMD="rename"
fi

if [ -n "${RENAME_CMD:-}" ]; then
    $RENAME_CMD -- "$VERSION_STRING" "$VERSION_NAME" "$DIST_DIR"/* 2>/dev/null || true
    $RENAME_CMD -- "$(basename "$DIST_DIR")" "$VERSION_NAME" "$DIST_DIR"/* 2>/dev/null || true
    $RENAME_CMD -- "-release" "" "$DIST_DIR"/* 2>/dev/null || true
fi

: "${TARGET_ARCH:?TARGET_ARCH must be set to x64 or arm64}"
case "$TARGET_ARCH" in
    x64|arm64) ;;
    *)
        echo "Unsupported Linux architecture: $TARGET_ARCH" >&2
        exit 1
        ;;
esac

for artifact in "$DIST_DIR"/*; do
    [ -f "$artifact" ] || continue
    filename="$(basename "$artifact")"
    target="$(printf '%s' "$filename" | sed -E "s/-linux(\\.[^.]+)$/-linux-${TARGET_ARCH}\\1/")"
    if [ "$target" != "$filename" ]; then
        mv "$artifact" "$DIST_DIR/$target"
    fi
done
