#!/bin/bash

if command -v rename.ul >/dev/null 2>&1; then
    RENAME_CMD="rename.ul"
elif command -v rename >/dev/null 2>&1 && rename --version 2>&1 | grep -q 'util-linux'; then
    RENAME_CMD="rename"
fi
# generic
source "$(dirname "$0")/generic.sh"

rm -f "$DIST_DIR"/*.apk

for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
    [ -e "$apk" ] || continue
    abi="${apk##*/app-}"
    abi="${abi%-release.apk}"
    cp "$apk" "$DIST_DIR/fluent_lyrics-$VERSION_NAME-$abi-android.apk"
done

if [ -n "${RENAME_CMD:-}" ]; then
    $RENAME_CMD -- "$VERSION_STRING" "$VERSION_NAME" "$DIST_DIR"/* 2>/dev/null || true
    $RENAME_CMD -- "$(basename "$DIST_DIR")" "$VERSION_NAME" "$DIST_DIR"/* 2>/dev/null || true
    $RENAME_CMD -- "-release" "" "$DIST_DIR"/* 2>/dev/null || true
fi
