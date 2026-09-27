# FluentLyrics

Flutter lyrics viewer (`fluent_lyrics`). It watches the platform now-playing source, fetches synced lyrics from several providers, and renders them. License is AGPL-3.0-only.

Read this file before editing. Use [docs/architecture.md](docs/architecture.md) for data flow and [docs/development.md](docs/development.md) for setup, codegen, and release. [README.md](README.md) is the user-facing install page; do not move contributor rules into it.

## Scope

Supported targets are Linux (MPRIS), Android 7.0+ / API 24 (notification listener; tested on Android 15+), and macOS (limited; now-playing comes from the vendored MediaRemote adapter).

Do not add Windows, iOS, or other Flutter targets unless the user explicitly asks and the change includes a real now-playing source plus a way to test it. iOS cannot read now-playing metadata without a jailbreak. Windows is intentionally unsupported.

Do not widen a task into unrelated cleanup. The tree is large and some files (`lib/providers/lyrics_provider.dart`, `lib/screens/lyrics_screen.dart`) are already dense.

## Layout

| Path | Role |
| --- | --- |
| `lib/main.dart` | Bootstrap: HTTP user agent, locale, desktop tray, lyrics stream writer |
| `lib/providers/lyrics_provider.dart` | App state. Media changes, cache, candidate selection |
| `lib/providers/lyrics_provider_fetch.dart` | `part` of the provider. Lyrics and translation fetch |
| `lib/providers/lyrics_display_pipeline.dart` | Memoized display transforms |
| `lib/providers/lyrics_provider_settings.dart` | In-memory mirror of `PrefSettings.mirrored` |
| `lib/services/pref_setting.dart` | Persisted setting table: key, default, read/write |
| `lib/services/lyrics_service.dart` | Provider priority walk, winner selection, translation fetch |
| `lib/services/lyrics_source_registry.dart` | `LyricsSource` contract and per-provider adapters |
| `lib/services/providers/` | Network and cache implementations |
| `lib/services/media_service.dart` | `MediaService` plus platform `part` files |
| `lib/services/media_service_platforms/` | Linux D-Bus, Android channels, macOS channels |
| `lib/services/opencc/` | Chinese-script conversion over bundled libopencc |
| `lib/models/` | `Lyric` / `LyricsResult`, Isar collections, `Setting<T>` |
| `lib/constants/app_defaults.dart` | Default values for every persisted setting |
| `lib/screens/` | Route-level pages. Settings routes are thin scaffolds |
| `lib/widgets/screen/` | Actual lyrics and settings UI sections |
| `lib/utils/` | Parsers, alignment, ruby/reading, display helpers |
| `lib/i18n/*.i18n.json` | Translation source. Locales: `en`, `zh_CN`, `zh_TW` |
| `hook/build.dart` | Native-assets build of libopencc for app builds |
| `tool/` | OpenCC, MediaRemote, and release-artifact scripts |
| `android/app/src/main/kotlin/` | Notification-listener service and method channels |
| `third_party/opencc` | Sparse git submodule. Do not edit upstream sources here |
| `third_party/mediaremote-adapter` | macOS adapter. Framework binaries are local, not all tracked |

`lib/` uses relative imports. Tests use `package:fluent_lyrics/...`.

## Commands

```bash
git submodule update --init --depth 1
flutter pub get
./tool/sync_opencc_assets.sh          # required before build or OpenCC tests
flutter run -d <device>
flutter test                          # also run by CI
dart run slang                        # after editing lib/i18n/*.i18n.json
dart run build_runner build --delete-conflicting-outputs  # after Isar schema edits
./tool/build_opencc.sh                # host libopencc for flutter test
./tool/macos_prepare_mediaremote_adapter.sh   # macOS only, before macos build
```

Analyzer config is `analysis_options.yaml` (`package:flutter_lints` plus `prefer_single_quotes`). `experimental_member_use` is ignored because Isar needs it. Format changed Dart with `dart format` on the files you touched. Do not reformat unrelated files.

Known-good local SDK is Flutter 3.47.5 / Dart 3.13.4 (constraint in `pubspec.yaml` is `sdk: ^3.12.0` and Flutter `>=3.44.0`). Android matches the Flutter 3.47 template: Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0. Leave `android.builtInKotlin=false` and `android.newDsl=false` until every plugin has migrated. CI installs Flutter stable and runs `flutter test` on push, pull request, and before release builds. There is no committed FVM pin.

## Conventions

- User-visible copy goes through slang. Edit all three JSON files, then run `dart run slang`, and commit both the JSON and `lib/i18n/strings*.g.dart`. Read strings with the generated `t` variable (`import '../i18n/strings.g.dart'`). Brand names may stay untranslated. Do not hardcode new UI English in widgets.
- Logs go through `AppLogger.debug`. It prints only in debug mode. Do not add `print`.
- Persisted settings start as a row in `PrefSettings` (`lib/services/pref_setting.dart`): key, default from `AppDefaults`, and read/write. Settings mirrored by the provider go in `PrefSettings.mirrored`; `LyricsProviderSettings.load` reads that list. Add a typed accessor there and a `SettingsService` one-line wrapper only if a caller still uses the named method. UI reads the provider's `Setting<T>` (`current`, `defaultValue`, `changed`), not prefs directly. Mark a secret row `secure: true`. Those values go through `SecretStore`, not SharedPreferences. Do not log them. Secret `Setting` objects must be constructed in a `PrefSetting` instance method; a generic constructor returns `Setting<dynamic>` and the provider cast crashes.
- Monospace styles must clear `fontVariations` to an empty list and pin a normal weight via `monospaceTextStyle`; a null variation list keeps the Outfit `wght` axis and draws non-variable monospace as zeros.
- New settings UI belongs in `lib/widgets/screen/settings/`. `lib/screens/settings/` only wraps a section in `SettingsScaffold`. Keep both in sync when a destination already has a route.
- A new lyrics provider needs all of: `LyricProviderType`, a service under `lib/services/providers/`, a `LyricsSource` in the registry factory, localized name/description keys, and a priority default only if it should be enabled out of the box. `llm` is a translation source, not a normal lyrics catalog.
- Fetch orchestration stays in `LyricsService`. Ranking stays in `lib/services/winner_selector.dart`. Provider fetch methods live in `lyrics_provider_fetch.dart`, a `part` of `lyrics_provider.dart`. Display transforms live in `LyricsDisplayPipeline`. Do not fetch from widgets.
- Platform now-playing code is a `part` of `lib/services/media_service.dart`. Do not turn those files into separate libraries. Android and macOS share channel names `cc.koto.fluent_lyrics/media` and `cc.koto.fluent_lyrics/media_events`. Change both sides together.
- Tests mirror `lib/` under `test/`. Inject fakes through constructors (`LyricsProvider`, `LyricsService`, `SettingsService` overrides). Widget tests must call `SharedPreferences.setMockInitialValues({})` and `LocaleSettings.setLocaleSync` before pumping `MyApp`.
- Keep CMake flags in `hook/build.dart` and `tool/build_opencc.sh` aligned. OpenCC dictionaries are text (`OPENCC_DICT_FORMAT=text`), not `.ocd2`.
- Package ids differ on purpose: Android/Linux `cc.koto.fluent_lyrics`, macOS `cc.koto.fluentLyrics`. Android debug/profile append `.debug` / `.profile`. Do not "normalize" these.
- Single quotes. Match surrounding style. No copyright headers. No drive-by renames.

## Generated and vendored files

Do not hand-edit:

- `lib/i18n/strings.g.dart`, `strings_en.g.dart`, `strings_zh_CN.g.dart`, `strings_zh_TW.g.dart`
- `lib/models/lyric_cache.g.dart`
- `assets/opencc/` (gitignored; `./tool/sync_opencc_assets.sh` regenerates it, including `version.txt`)
- `third_party/opencc` sources. Bump the pin with `./tool/prepare_opencc.sh <tag>` (default `ver.1.4.2`) and then sync assets.
- `build/`, `.dart_tool/`, `tmp/`, `release.md`, `dist/`

Commit the slang and Isar outputs after regenerating them. Do not commit `assets/opencc/`. CI runs `./tool/sync_opencc_assets.sh` before each platform build. `hook/build.dart` fails if `assets/opencc/version.txt` is missing.

`third_party/mediaremote-adapter` tracks the license, README, `VERSION`, and `bin/mediaremote-adapter.pl`. The framework is produced on macOS by `./tool/macos_prepare_mediaremote_adapter.sh` (default `v0.7.6`) and copied in by `macos/scripts/bundle_mediaremote_adapter.sh`. Do not commit built framework binaries.

## Secrets and release

Never commit `android/key.properties`, `*.jks`, keystore passwords, or LLM API keys. Signing uses env vars in CI (`ANDROID_KEYSTORE_*`) or a local `android/key.properties`. An example file is `android/key.properties.example`.

The LLM API key and Musixmatch token are stored with `flutter_secure_storage` (Android Keystore, macOS login keychain, Linux libsecret). Do not put either value in logs, diagnostics, or a new preference. A failed open must not fall back to the plaintext copy or delete it. Linux builds need `libsecret-1-dev`. macOS must keep `usesDataProtectionKeychain: false`; do not add a Keychain Sharing entitlement.

`pubspec.yaml` `version:` is `name+code` (currently `0.0.46+46`). Release tags look like `v0.0.46+46`. CI rewrites `version:` from the tag. Do not bump the version unless the user is cutting a release. `.github/workflows/test.yml` runs `flutter test` on push and pull request. Release builds call that workflow and do not start until it passes. OpenCC native tests still skip in CI unless `libopencc` is built.

## Checks before finishing

- Run the narrowest `flutter test` that covers the change, then a broader `flutter test` if the change is on the fetch or provider path.
- If you touched Isar collections, regenerate `lyric_cache.g.dart` and make sure the schema still round-trips through `LyricsCacheService`.
- If you touched user-facing strings, regenerate slang and keep `en`, `zh_CN`, and `zh_TW` in parity.
- If you touched OpenCC bindings or CMake flags, update both `hook/build.dart` and `tool/build_opencc.sh`, then run `./tool/build_opencc.sh` so the native tests are not skipped.
- CI runs `flutter test`. It does not build `libopencc`, so OpenCC native tests skip there. Do not claim CI verified conversion, signing, or a platform build.
