# FluentLyrics

A desktop lyrics viewer built with Flutter, displays and syncs song lyrics from multiple providers.

## Lyrics Providers 
- Musixmatch
- Netease Music
- lrclib

## Features
- Synchronized lyrics support.
- Multiple lyrics providers with configurable priority.
- Local lyrics cache using Isar.
- Per-track and global lyrics offset support.

## Screenshots
![The main interface](https://raw.githubusercontent.com/kobe-koto/FluentLyrics/refs/heads/main/previews/main.jpg)
The main interface.

## Supports
- Linux (get track metadata via MPRIS D-Bus Interface)
- ~~Android~~ (Planned)
- no other platform support planned 

## Quick start (developer)
Requirements:
- Flutter SDK with desktop support enabled
- Dart

Common commands:
- flutter pub get
- flutter run -d <device>
- flutter build linux
- please refer to fastforge for packaging

## Disclaimer
this project is vibe coded, I think I only produced the 5% of codebase, so don't expect any quality and experience from this.
Non-AI Coded Up To 5%!
