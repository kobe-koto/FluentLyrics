#!/bin/bash

VERSION_NO_V=$(echo $RELEASE_VERSION | sed 's/^v//')
DIST_DIR="dist/$VERSION_NO_V"

if command -v rename.ul >/dev/null 2>&1; then
    RENAME_CMD="rename.ul"
elif command -v rename >/dev/null 2>&1 && rename --version 2>&1 | grep -q 'util-linux'; then
    RENAME_CMD="rename"
else
    echo "Error: util-linux 'rename' utility not found."
    exit 1
fi

rm $DIST_DIR/*.apk
cp build/app/outputs/flutter-apk/*.apk $DIST_DIR/
$RENAME_CMD -- "app" "fluent_lyrics-$VERSION_NO_V" $DIST_DIR/*.apk
$RENAME_CMD -- ".apk" "-android.apk" $DIST_DIR/*.apk

$RENAME_CMD -- "-profile" "" $DIST_DIR/*
