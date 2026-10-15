# FluentLyrics

A cross-platform lyrics viewer built with Flutter that displays and synchronizes song lyrics from multiple providers.

## Lyrics Providers
- Musixmatch
- Netease Music
- QQ Music
- LRCLIB

## Features
- Synchronized and syllable-synced (rich) lyrics support.
- Multiple lyrics providers with configurable priority.
- Local lyrics cache using Isar.
- Per-track and global lyrics offset support.
- Lyrics translation support, including LLM-based translation.

## Screenshots

<div style="display: flex; overflow: auto; height: 85vh;">
<img style="height: 85vh;" alt="The main interface" src="https://raw.githubusercontent.com/kobe-koto/FluentLyrics/main/previews/android/main_playing.png" />
<img style="height: 85vh;" alt="The lyrics candidate interface" src="https://raw.githubusercontent.com/kobe-koto/FluentLyrics/main/previews/android/candidate_lyrics.png" />
<img style="height: 85vh;" alt="The settings interface" src="https://raw.githubusercontent.com/kobe-koto/FluentLyrics/main/previews/android/settings_main.png" />
</div>

## Installation

### Linux

1. Arch Linux (x86_64/arm64)

```bash
paru -Sy fluent-lyrics-bin
```

2. Other Linux Distros

   Download the portable archive from [GitHub Releases](https://github.com/kobe-koto/FluentLyrics/releases) or kindly package it yourself :3

   Saving an LLM API key or Musixmatch token needs a Secret Service (GNOME Keyring or KWallet) and `libsecret`.

### Android

1. [GitHub Releases](https://github.com/kobe-koto/FluentLyrics/releases)

2. Tracking GitHub Releases with Apps like [Obtainium](https://obtainium.imranr.dev/) (Recommended)

3. Custom F-Droid repo:

   1. [Click to add the Fluent Lyrics custom F-Droid repo](https://kobe-koto.github.io/FluentLyrics/fdroid/repo?fingerprint=5ACD3280EC11CDD98DB5AC85640664B81DFCBFBFBA2F1074163C7B754F6BE799) or scan this QR Code: 

      <details>
      <summary>Click to expand the QR code</summary>
      <img src="https://kobe-koto.github.io/FluentLyrics/fdroid/repo/index.png" alt="QR: Fluent Lyrics custom F-Droid repo">
      </details>

   2. Sync the repos

   3. Search for "Fluent Lyrics"

### Others

Check [GitHub Releases](https://github.com/kobe-koto/FluentLyrics/releases) for other platform builds (such as macOS).

## Support status

### Fully Supported

- Linux
  - Retrieve now-playing metadata via the MPRIS D-Bus interface.
- Android
  - Requires Android 7.0 (API 24) or later.
  - Currently tested primarily on Android 15 and later.

### Limited Support

- macOS
  - Obtain now-playing metadata via the [MediaRemote adapter](https://github.com/ungive/mediaremote-adapter).
  - HUGE thanks to [@watchdogexd](https://github.com/watchdogexd) for testing and contributing.
  - I don't have a macOS device, so I can't test it directly; expect best-effort support.

- Linux arm64
  - I don't have a Linux arm64 device, so I cannot test on this architecture directly.

### Cannot Support

- Windows

  we dun want to :3

  In fact, the project's developers do not have Windows installations, so we do not consider developing for Windows to have a sufficient benefit.

- iOS

  Theoretically impossible to obtain now-playing metadata without jailbreaking.

- Other platforms/architectures
  Platforms not natively supported by Flutter will not be supported. Pull requests for other Flutter-supported platforms/architectures are welcome if accompanied by tests and feedback.

## Development

For architecture, setup instructions, codegen, and everyday commands, see:

- [AGENTS.md](AGENTS.md) — conventions, generated files, and agent rules
- [docs/architecture.md](docs/architecture.md) — now-playing, fetch, cache, and UI flow
- [docs/development.md](docs/development.md) — setup, toolchains, tests, and release workflows

Quick clone with submodules:

```bash
git clone --recurse-submodules <repo-url>
./tool/sync_opencc_assets.sh
flutter run
```

## Disclaimer

This project is vibe-coded; I think I only produced around 5% of the codebase, so don't expect any quality or polished experience from this.

Non-AI Coded Up To 5%!
