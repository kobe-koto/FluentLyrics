# FluentLyrics

A desktop lyrics viewer built with Flutter, displays and syncs song lyrics from multiple providers.

## Lyrics Providers 
- Musixmatch
- Netease Music
- QQ Music
- lrclib

## Features
- (Rich) Synchronized lyrics support.
- Multiple lyrics providers with configurable priority.
- Local lyrics cache using Isar.
- Per-track and global lyrics offset support.
- Lyric translations support, incl LLM translate

## Screenshots

![The main interface](https://raw.githubusercontent.com/kobe-koto/FluentLyrics/refs/heads/main/previews/main.png)

The main interface.

## Supports
- Linux (get track metadata via MPRIS D-Bus Interface)
- Android
- no other platform support planned
- PR welcome

## Installations

### Linux

1. Arch Linux (x86_64)

```bash
paru -Sy fluent-lyrics-bin
```

2. Other Linux Distros

Please use the AppImage or kindly package it yourself :3

### Android

see Releases

### macOS

see Release, 

HUGE thanks to [@watchdogexd](https://github.com/watchdogexd) and https://gist.github.com/SKaplanOfficial/f9f5bdd6455436203d0d318c078358de

## Quick start (developer)

Requirements:
- Flutter SDK
- Dart
- Android toolchain (for android)
- Linux toolchain (for linux)

Common commands:
- flutter pub get
- flutter run -d <device>
- please refer to fastforge for packaging

## Disclaimer

this project is vibe coded, I think I only produced the 5% of codebase, so don't expect any quality and experience from this.

Non-AI Coded Up To 5%!
