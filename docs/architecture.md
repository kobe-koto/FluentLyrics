# Architecture

Fluent Lyrics is a single Flutter app. One `LyricsProvider` owns playback state, fetch lifecycle, cache, and the lyrics the UI actually paints. Screens and widgets observe it with `provider`. They do not call music services themselves.

## Runtime flow

```text
platform now-playing
        |
        v
MediaService.create()  --->  LyricsProvider
        |                         |
        |                         +--> SettingsService (SharedPreferences)
        |                         +--> LyricsService
        |                         |         |
        |                         |         +--> LyricsSourceRegistry
        |                         |         |       lrclib, musixmatch, netease,
        |                         |         |       qqmusic, cache, llm
        |                         |         +--> winner_selector
        |                         +--> LyricsCacheService (Isar)
        |                         +--> ZhConversionService (libopencc)
        v                         v
LyricsScreen / tray / LyricsStreamWriter
```

`main.dart` builds `LyricsProvider` before `runApp` so the tray can subscribe immediately. Desktop-only startup (`trayPlatformSupported`: Linux and macOS) initializes `window_manager`, `TrayService`, and `LyricsStreamWriter`. Android skips those. A global `HttpOverrides` sets the user agent to `FluentLyrics/git`.

Locale is restored from `SettingsService.getLocale()` into slang's `LocaleSettings`. `null` means follow the system. `TranslationProvider` wraps the app.

## Now playing

`MediaService.create()` picks one implementation:

| Platform | Implementation | Source |
| --- | --- | --- |
| Linux | `LinuxMediaService` | Session D-Bus, `org.mpris.MediaPlayer2.*` |
| Android | `AndroidMediaService` | `NotificationListenerService` in `MediaSessionListenerService.kt` |
| macOS | `MacOSMediaService` | `mediaremote-adapter` bundled into the app |

Linux, Android, and macOS files are `part`s of `lib/services/media_service.dart`. They share `MediaMetadata`, `MediaPlaybackStatus`, `MediaControlAbility`, and `MediaController`.

Android and macOS use the same channel names:

- `cc.koto.fluent_lyrics/media` — `getStatus`, `checkPermission`, `openPermissionSettings`, transport controls, `seek`
- `cc.koto.fluent_lyrics/media_events` — playback updates

Android needs the notification-listener permission. `LyricsProvider` polls it on Android. The lyrics screen shows `permission_overlay.dart` until it is granted. macOS has no equivalent permission flow; the adapter must already be prepared and bundled.

`MediaMetadata.==` ignores duration. `isSameTrack` includes duration. Fetch and cache identity follow the track fields used by `generateCacheId`, not widget equality.

## Fetch and ranking

`LyricsService.fetchLyrics` walks `SettingsService.getPriority()`. Cache is prepended when cache is enabled. Each entry is a `LyricsSource` from `LyricsSourceRegistry`. Unknown types are skipped.

`LyricsFetchRequest` carries title, artists, album, duration, metadata trimming, translation bias, and callbacks for status, artwork, and an early translation. Results with lyrics or `isPureMusic` are reported as candidates. `selectBetterCandidate` ranks them:

1. A pure-music result does not replace real lyrics.
2. Non-empty lyrics beat empty lyrics.
3. Rich sync beats plain sync when rich sync is enabled.
4. Synced lyrics beat unsynced lyrics.
5. Otherwise the current best stays.

`hasGoodEnoughLyricsResult` is the early-stop check: pure music, or non-empty rich/synced lyrics matching the rich-sync setting, plus a translation if translation is enabled. The provider can pause there and keep fetching the rest after the user looks at candidates.

`LyricsService.fetchTranslation` is a separate pass. It can reuse a translation bundled with the lyrics result, consult cache, or call a source that implements `fetchTranslation`. `LlmTranslationService` is OpenAI-compatible and is not a lyrics catalog. Alignment uses `translationAlignmentThreshold` and `translationCoverageThreshold` (default 80).

Provider services:

| Type | Service | Notes |
| --- | --- | --- |
| `lrclib` | `LrclibService` | Open lyrics database |
| `musixmatch` | `MusixmatchService` | Token stored in prefs; 401 renews the token |
| `netease` | `NeteaseService` | EAPI search; can return reading tracks |
| `qqmusic` | `QQMusicService` | Encrypted lyric payload in `qqmusic_lyric_decoder.dart`; word-level kana |
| `cache` | `LyricsCacheService` | Isar, not a network source |
| `llm` | `LlmTranslationService` | Translation only |

`lyricProviderTypeFromSource` maps display names such as `Netease Music` and `QQ Music` back to the enum. Cached rows strip a trailing `(cached)` before that mapping. Keep those strings stable or update both sides.

## Models

`Lyric` is one line: start, optional end, text, optional `inlineParts` (word-level times), optional translation, optional furigana `annotations`.

`LyricsResult` is one provider payload: lines, source label, sync flags, credits, artwork URLs, optional `LyricsReading` (`kana` or `romaji`), language, and translation fields. `translation: true` means this result is a translation payload rather than the primary lyrics.

`LyricsResult.trim()` drops leading and trailing blank lines and collapses consecutive blanks. `copyWith` does not. Callers that want padding preserved must not run the result through `trim()`.

## Cache

Isar database name is `lyrics_cache`. Collections live in `lib/models/lyric_cache.dart` (`LyricCache`, `TranslationCache`, `ReadingCache`, `ReadingCandidateCache`, and the embedded item types). `lib/models/lyric_cache.g.dart` is generated.

Cache id is `sha256(title|artists|album|durationSeconds)` plus `_rich` or `_std`. Lookup tries rich first, then standard. Artwork images are a separate file cache under `libCachedImageData`, via `CacheHelper`, not Isar.

## Display pipeline

`LyricsProvider` does not hand the raw fetch result straight to the list. Before paint it can:

- convert Chinese script through `ZhConversionService` (`off`, `zh_CN` / `t2s`, `zh_TW` / `s2twp`, `zh_HK` / `s2hk`)
- skip conversion for languages in `zhConversionIgnoredLanguages` (default `ja`), decided per song so a track is never half-converted
- attach readings from the provider track, with `annotationBias` controlling pairing
- repair rich-sync inline parts when those experimental fixes are on

Rendering is split across `lib/widgets/screen/lyrics/` (`lyrics_list`, `lyrics_header`, `lyrics_background`, `lyrics_control_area`, `lyrics_candidate_sheet`) and `lib/widgets/lyric_line.dart` / `ruby_text.dart`. `lib/screens/lyrics_screen.dart` still owns layout and a few private section widgets. Prefer new lyrics UI in `lib/widgets/screen/lyrics/` instead of growing the screen file.

Position for highlighting comes from the media service, plus global and per-track offset. `currentPositionNotifier` updates on every position tick. `positionResyncNotifier` fires when the highlighted line changes, when playback seeks backward, or when a tick jumps by more than 400 ms. The list uses that signal to resnap instead of rebuilding on every tick.

## Settings

`Setting<T>` records `current`, `defaultValue`, and `changed`. Defaults live only in `AppDefaults`. Persistence keys live only in `SettingsService`. The provider mirrors them in `LyricsProviderSettings` and exposes getters for the UI.

Changing a setting should update prefs and notify listeners. Reset actions compare against `AppDefaults`, not a second copy of the default buried in a widget.

## Chinese conversion

`hook/build.dart` builds `libopencc` from `third_party/opencc` and exposes it as a dynamic native asset named `services/opencc/opencc_bindings.dart`. App builds do not run OpenCC's dictionary compiler; they load the text dictionaries generated into `assets/opencc/`.

`ZhConversionService` extracts those assets, opens one `ZhConverter` per config, and registers the OpenCC license with `LicenseRegistry`. `ZhConversion` is the pure line/part/annotation walker used by tests.

Japanese text is detected in `lib/utils/script_detector.dart` before conversion. Do not run OpenCC over kana/kanji lyrics by default.

## Desktop extras

`TrayService` mirrors now-playing, candidate lists, and a few provider actions (select candidate, refetch, mark pure music, skip translation). It is Linux/macOS only.

`LyricsStreamWriter` writes the current lyric and translation to plain files so desktop users can `tail -F` them into a status bar or OBS. It is not started on Android, on purpose, to avoid storage permission prompts.

## UI map

| Area | Route / shell | Controls |
| --- | --- | --- |
| Now playing | `LyricsScreen` | `lib/widgets/screen/lyrics/` |
| Settings hub | `SettingsScreen` | destination list |
| Priority, display, translation, lyric config, cache, misc, language | `lib/screens/settings/` | matching `*_section.dart` |
| About | `AboutScreen` plus `lib/screens/about/` | contributors, diagnostics, provider blurbs |

Settings sections should stay free of fetch logic. They call provider setters and read `Setting<T>`.
