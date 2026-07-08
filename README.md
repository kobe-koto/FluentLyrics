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

## Supported platforms
- Linux x86_64
   - retrieve now-playing metadata via the MPRIS D‑Bus interface.
- Android

## Limited support
- macOS
   - obtain now-playing metadata via the [MediaRemote adapter](https://github.com/ungive/mediaremote-adapter)
   - HUGE thanks to [@watchdogexd](https://github.com/watchdogexd) for testing and contributing.
   - I don't have a macOS device, so I can't test it, expect limited support.
- No other platform support is planned
- PR welcome

## Cannot support
- Windows

   we dun want to :3

- iOS
   
   theoretically impossible to obtain now‑playing metadata without jailbreaking.
   
- Linux arm64
   
   official support for building a Linux arm64 Flutter app requires a native Linux arm64 machine
   
   but I don't own a physical one...
   
   that means additional time and effort for an architecture I cannot test
   
   PR welcome (if that comes with consistent test and feedback).

- Other platforms/architectures not natively supported by Flutter, PRs for them are no-op.

## Installations

### Linux

1. Arch Linux (x86_64)

```bash
paru -Sy fluent-lyrics-bin
```

2. Other Linux Distros

Please use the AppImage or kindly package it yourself :3

### Android

You can download it from the [GitHub Releases](https://github.com/kobe-koto/FluentLyrics/releases) or from Fluent Lyrics custom F-Droid repo as below:

1. [Click to add the Fluent Lyrics custom F-Droid repo](https://kobe-koto.github.io/FluentLyrics/fdroid/repo?fingerprint=5ACD3280EC11CDD98DB5AC85640664B81DFCBFBFBA2F1074163C7B754F6BE799) or scan this QR Code: 

   <details>
   <summary>Click to expand the QR code</summary>
   <img src="https://kobe-koto.github.io/FluentLyrics/fdroid/repo/index.png" alt="QR: Fluent Lyrics custom F-Droid repo">
   </details>


2. Sync the repos

3. Search for "Fluent Lyrics"

### Others

see Releases

## Quick start (developer)

Requirements:
- Flutter SDK
- Dart
- Android toolchain (for android)
- Linux toolchain (for linux)
- Xcode tools (for macOS)

Common commands:

```bash
flutter pub get # get deps
flutter run -d <device> --[debug|profile|release] # run the app
dart run build_runner build --delete-conflicting-outputs  # after modifying Isar @Collection 
dart run slang # after modifying i18n datasets
dart pub global activate fastforge # Install Fastforge (refer to fastforge for packaging)
./tool/macos_prepare_mediaremote_adapter.sh [version] # macOS only, prepared media remote adapter is required before building, defaults to v0.7.6
```

## Disclaimer

this project is vibe coded, I think I only produced the 5% of codebase, so don't expect any quality and experience from this.

Non-AI Coded Up To 5%!
