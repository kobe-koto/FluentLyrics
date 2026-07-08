#!/bin/bash

# generic
source "$(dirname "$0")/generic.sh"

# Android
rm -f "$DIST_DIR"/*.apk

for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
    [ -e "$apk" ] || continue
    abi="${apk##*/app-}"
    abi="${abi%-release.apk}"
    cp "$apk" "$DIST_DIR/fluent_lyrics-$VERSION_NAME-$abi-android.apk"
done
