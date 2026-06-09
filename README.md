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
- Linux x86_64 (retrieve now-playing metadata via the MPRIS D‑Bus interface)
- Android
- macOS (see https://gist.github.com/SKaplanOfficial/f9f5bdd6455436203d0d318c078358de, HUGE thanks to [@watchdogexd](https://github.com/watchdogexd).)
- No other platform support is planned
- Pull requests are welcome

## Cannot support
- iOS – theoretically impossible to obtain now‑playing metadata without jailbreaking.
- Linux arm64 – official support for building a Linux arm64 Flutter app requires a native Linux arm64 machine, ~~but GitHub Actions does not provide a Linux arm64 runner~~, they do, but that requires additional time and effort for an architecture I cannot test, PR welcome anyways (if that comes with consistent test and feedback).
- Linux (except x86_64 and arm64) – not natively supported by Flutter.
- BSD – not natively supported by Flutter.

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

1. [Click to add the Fluent Lyrics custom F-Droid repo](https://fdroid.link/#https://kobe-koto.github.io/FluentLyrics/fdroid/repo?fingerprint=5ACD3280EC11CDD98DB5AC85640664B81DFCBFBFBA2F1074163C7B754F6BE799) or scan this QR Code: 

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

Common commands:

```bash
flutter pub get # get deps
flutter run -d <device> --[debug|profile|release] # run the app
dart run build_runner build --delete-conflicting-outputs  # after modifying Isar @Collection 
dart run slang # after modifying i18n datasets
dart pub global activate fastforge # Install Fastforge (refer to fastforge for packaging)
```

## Disclaimer

this project is vibe coded, I think I only produced the 5% of codebase, so don't expect any quality and experience from this.

Non-AI Coded Up To 5%!
