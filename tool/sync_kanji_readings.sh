#!/bin/sh
set -eu

# Regenerates the kanji-reading dictionary shipped as a Flutter asset
# (assets/kanji_readings). The data is a trimmed, reformatted subset of
# KANJIDIC2 (readings only), used to split a compound's whole-run reading onto
# each kanji for the "Per-Kanji Reading Split" setting.
#
# KANJIDIC2 is distributed by the EDRDG under CC BY-SA 4.0. It is downloaded
# here and converted; nothing from it is committed to the repository. The
# conversion keeps only the Japanese on/kun readings (kun readings are cut at
# the okurigana "." marker) keyed by kanji. CI runs this once per workflow run
# in .github/workflows/prepare-kanji-readings.yml and shares the result as an
# artifact with the test and platform build jobs.
#
# Usage: tool/sync_kanji_readings.sh

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$ROOT_DIR/assets/kanji_readings"
WORK_DIR="$ROOT_DIR/build/kanji_readings"
# Everything is written here first and moved over DEST_DIR only once complete,
# so a failed download leaves the previous assets/kanji_readings untouched.
STAGE_DIR="$WORK_DIR/out"

# Pin the KANJIDIC2 release. EDRDG serves the current file at a stable URL; the
# version is recorded from the file's own <date_of_creation> after parsing.
# Keep this URL in sync with KanjiReadingDictionary.kanjidic2Url.
KANJIDIC2_URL="https://www.edrdg.org/kanjidic/kanjidic2.xml.gz"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

require_command curl
require_command gunzip
require_command dart

# EDRDG is occasionally slow or unreachable from CI runners. Retry transient
# failures and cap each connection attempt instead of hanging for minutes.
fetch() {
  curl -fsSL --retry 4 --retry-all-errors --retry-delay 10 \
    --connect-timeout 30 "$1" -o "$2"
}

mkdir -p "$WORK_DIR"
GZ_FILE="$WORK_DIR/kanjidic2.xml.gz"
XML_FILE="$WORK_DIR/kanjidic2.xml"

echo "Downloading KANJIDIC2..."
fetch "$KANJIDIC2_URL" "$GZ_FILE"
gunzip -kf "$GZ_FILE"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

# Convert with the same logic the app uses at runtime
# (lib/utils/kanji_readings_converter.dart), so the bundled asset and an in-app
# EDRDG download produce identical data. flutter pub get must have run first.
dart "$ROOT_DIR/tool/kanji_readings_convert.dart" \
  --input "$XML_FILE" \
  --out-json "$STAGE_DIR/kanji_readings.json" \
  --out-version "$STAGE_DIR/version.txt"

VERSION="$(cat "$STAGE_DIR/version.txt")"

# EDRDG requires attribution to the group and a statement that the material was
# changed (CC BY-SA 4.0 §3(a)). The LICENSE is the CC BY-SA 4.0 legalcode; the
# NOTICE names the source, the attribution, and the modifications made.
cat > "$STAGE_DIR/NOTICE" <<NOTICE
KANJIDIC2
https://www.edrdg.org/wiki/index.php/KANJIDIC_Project

This file is a trimmed, reformatted subset of KANJIDIC2 ($VERSION), the kanji
dictionary data maintained by the Electronic Dictionary Research and
Development Group (EDRDG), Monash University.

Copyright (C) The Electronic Dictionary Research and Development Group.
Licensed under the Creative Commons Attribution-ShareAlike 4.0 International
License (CC BY-SA 4.0, see LICENSE).

Changes from the original: all fields except the kanji character and its
Japanese on/kun readings have been removed; kun readings are cut at the
okurigana "." marker; the result is reserialized as a JSON object mapping each
kanji to its list of hiragana/katakana readings. No readings were otherwise
altered.
NOTICE

echo "Downloading CC BY-SA 4.0 legalcode..."
fetch "https://creativecommons.org/licenses/by-sa/4.0/legalcode.txt" \
  "$STAGE_DIR/LICENSE"

rm -rf "$DEST_DIR"
mkdir -p "$(dirname "$DEST_DIR")"
mv "$STAGE_DIR" "$DEST_DIR"

echo "Synced KANJIDIC2 $VERSION readings into assets/kanji_readings"
