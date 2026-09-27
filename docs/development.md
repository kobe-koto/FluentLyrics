# Development

Contributor and agent setup for Fluent Lyrics. Product install instructions stay in [README.md](README.md). Behavior and module boundaries are in [docs/architecture.md](docs/architecture.md).

## Requirements

- Flutter stable that satisfies `sdk: ^3.12.0` and Flutter `>=3.44.0`. Local development uses Flutter 3.47.5 / Dart 3.13.4.
- Dart (shipped with Flutter).
- CMake, Ninja, and a C/C++ toolchain for the vendored OpenCC build.
- Linux: GTK 3, Ayatana AppIndicator, libsecret, and the usual Flutter Linux deps (`clang`, `ninja`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`, `libayatana-appindicator3-dev`, `libsecret-1-dev`). Runtime needs `libsecret-1-0` and an unlocked secret service (GNOME Keyring or KWallet) to save an API key or Musixmatch token.
- Android: SDK, NDK (`flutter.ndkVersion`), Java 17 language level. CI builds with Java 21. `minSdk` is 24, `compileSdk` / `targetSdk` are 36. The wrapper is Gradle 9.3.1 with Android Gradle Plugin 9.1.0 and Kotlin 2.4.0, the versions Flutter 3.47 verifies. Do not move to a newer AGP ahead of that template.
- macOS: Xcode, plus a prepared MediaRemote adapter. There is no maintainer Mac, so treat macOS changes as untested unless someone ran them.

Windows and iOS are out of scope. See [AGENTS.md](../AGENTS.md).

## First checkout

```bash
git clone --recurse-submodules <repo-url>
cd FluentLyrics
git submodule update --init --depth 1   # existing clone
flutter pub get
./tool/sync_opencc_assets.sh            # writes gitignored assets/opencc/
```

`third_party/opencc` is a shallow submodule pinned by `./tool/prepare_opencc.sh` (default tag `ver.1.4.2`). That script sparse-checkouts only the sources the app compiles. Do not commit a full OpenCC tree, and do not edit files under `third_party/opencc`.

`assets/opencc/` is generated and gitignored. `flutter build` and `hook/build.dart` fail without `assets/opencc/version.txt`. CI syncs it in every build job. Sync again after changing the OpenCC pin or the asset script.

Host tests that load libopencc also need:

```bash
./tool/build_opencc.sh
```

Output is `build/opencc/out/{lib,share/opencc}`. App bundles do not use that directory; they go through `hook/build.dart`. Keep the CMake flags in those two files in sync. Dictionary format is `text`.

## Everyday commands

```bash
flutter pub get
flutter run -d <device>          # add --profile or --release as needed
flutter test
flutter test test/utils/rich_lrc_parser_test.dart
dart format lib/path/you_changed.dart test/path/you_changed.dart
```

VS Code launch configs in `.vscode/launch.json` cover debug, profile, and release. `.vscode/settings.json` is local and gitignored.

Android release signing reads `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`, or `android/key.properties` (see `android/key.properties.example`). Never commit the properties file or a keystore.

API secrets are not signing keys. The LLM API key and Musixmatch token go through `FlutterSecureSecretStore`. Android backup is disabled (`android:allowBackup="false"`) so the Keystore-wrapped values are not restored without their key. Do not log those values or copy them into diagnostics.


macOS, before the first build on a machine:

```bash
./tool/macos_prepare_mediaremote_adapter.sh    # default v0.7.6
```

The Xcode build phase `macos/scripts/bundle_mediaremote_adapter.sh` copies the script and framework into the app bundle and fails with a pointer to that tool if they are missing.

## Codegen

| Change | Command | Commit? |
| --- | --- | --- |
| `lib/i18n/*.i18n.json` | `dart run slang` | Yes: JSON and `lib/i18n/strings*.g.dart` |
| `@Collection` / embedded fields in `lib/models/lyric_cache.dart` | `dart run build_runner build --delete-conflicting-outputs` | Yes: `lib/models/lyric_cache.g.dart` |
| OpenCC pin or dictionary set | `./tool/prepare_opencc.sh` then `./tool/sync_opencc_assets.sh` | No: `assets/opencc/` stays gitignored |
| slang config | `slang.yaml` | Yes, then regenerate strings |

Locales are `en` (base, fallback), `zh_CN`, and `zh_TW`. Keys are camelCase. Interpolation is `{{doubleBraces}}`. Add a key to all three JSON files in the same change. The generated files say not to edit them by hand.

`analysis_options.yaml` excludes `build/`, `android/`, `macos/`, and `linux/` from the Dart analyzer.

## Tests

There are widget, provider, service, and util tests under `test/`. CI runs `flutter test` on push, pull request, and before a release build. OpenCC native tests skip in CI because it does not build `libopencc`. Run the focused file locally before handing off, and `./tool/build_opencc.sh` when the change touches conversion.

Patterns already in the tree:

- Subclass `SettingsService` and override the getters a test needs. Return `Setting<T>`. If the test constructs `LyricsProvider` and needs a non-default mirrored setting, also override `readSetting`; `LyricsProviderSettings.load` reads that table, not the named getters.
- Pass fake `MediaService`, `LyricsService`, and `LyricsCacheService` into `LyricsProvider({...})`. The constructor starts polling, so fakes must implement `startPolling` and `addListener`.
- `test/widget_test.dart` sets mock `SharedPreferences` and `LocaleSettings.setLocaleSync(AppLocale.en)` before pumping `MyApp`.
- OpenCC tests in `test/services/opencc/` skip with `run tool/build_opencc.sh first` when `build/opencc/out` is missing. A green run that skipped those tests did not exercise conversion.

Prefer a focused test file over the full suite while iterating. Run `flutter test` once before finishing a fetch, cache, or provider change.

## Adding a setting

1. Default in `lib/constants/app_defaults.dart`.
2. A row in `PrefSettings` (`lib/services/pref_setting.dart`): key, default, and read/write. If the provider should mirror it, add that row to `PrefSettings.mirrored` and a typed accessor on `LyricsProviderSettings`. A secret row sets `secure: true` and is not written to SharedPreferences except as a one-time migration source.
3. A one-line `SettingsService` wrapper only if a caller still uses the named getter or setter. Priority order and locale stay handwritten.
4. Controls in the matching `lib/widgets/screen/settings/*_section.dart`.
5. Strings in `en.i18n.json`, `zh_CN.i18n.json`, and `zh_TW.i18n.json`, then `dart run slang`.
6. A unit test if the value changes fetch, cache, or display behavior.

Do not invent a second default in the widget. An empty translation-target list deletes the key. An empty `trimMetadataProviders` list reads back as the default.

## Adding a lyrics provider

1. Add a `LyricProviderType` value and its `localizedName` / `localizedDescription` keys.
2. Implement fetch in `lib/services/providers/`. Return `LyricsResult`. Put format-specific decoding in `lib/utils/` if it is testable without HTTP.
3. Add a `LyricsSource` subclass and register it in `LyricsSourceRegistry.fromServices`.
4. Decide whether it belongs in `AppDefaults.providerPriority` and `enabledProviderCount`. Cache is inserted by `getPriority()` when enabled; do not hardcode it into the saved order.
5. Cover search/parse logic with fakes. Do not hit live catalogs from `flutter test`.

Translation-only sources implement `fetchTranslation` and `checkTranslationSupport`. They should not win the primary lyrics ranking.

## Platform notes

Linux now-playing is session-bus MPRIS only. A player that does not export `org.mpris.MediaPlayer2` will not appear.

Android listens to media sessions through a notification listener. Debug and profile builds use different application ids (`cc.koto.fluent_lyrics.debug` / `.profile`), so the permission must be granted again after switching build modes.

macOS support is best-effort. Adapter version is recorded in `third_party/mediaremote-adapter/VERSION`. Only the license, README, that version file, and `bin/mediaremote-adapter.pl` are tracked. Rebuild the framework on a Mac; do not commit it.

Tray and lyric file streaming are desktop-only. Do not start them on Android.

## Release

Pushing a `v*` tag runs `.github/workflows/release.yml`. Manual dispatch can build without publishing, or publish an unstable prerelease. The workflow:

1. Runs `flutter test` via `.github/workflows/test.yml`. Platform builds wait for it.
2. Derives `version_name` and `version_code` from the tag (`v0.0.46+46`).
3. Rewrites `pubspec.yaml` `version:` in the build job only.
4. Syncs OpenCC assets.
5. Builds Linux x64 and arm64, Android, and macOS.
6. Publishes GitHub Release notes from `tool/generate-release-notes.sh` and `tool/downloads-template.md`.

Do not bump `pubspec.yaml` version on a normal feature commit. Tag releases as `v<name>+<code>`, matching `version:`.

F-Droid metadata is `fdroid-config/metadata/cc.koto.fluent_lyrics.yml`. Update it when the user-facing summary or license changes, not for internal refactors.

## Files that should stay untracked

`assets/opencc/`, `build/`, `.dart_tool/`, `tmp/`, `dist/`, `release.md`, `android/key.properties`, keystores, and `.widget_preview/`. If a change seems to require committing one of these, stop and check `.gitignore` first.
