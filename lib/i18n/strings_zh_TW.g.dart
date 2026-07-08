///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZhTw extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhTw({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhTw,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <zh-TW>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsZhTw _root = this; // ignore: unused_field

	@override 
	TranslationsZhTw $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhTw(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$language$zh_TW language = Translations$language$zh_TW.internal(_root);
	@override late final Translations$common$zh_TW common = Translations$common$zh_TW.internal(_root);
	@override late final Translations$settings$zh_TW settings = Translations$settings$zh_TW.internal(_root);
	@override late final Translations$lyrics$zh_TW lyrics = Translations$lyrics$zh_TW.internal(_root);
	@override late final Translations$permission$zh_TW permission = Translations$permission$zh_TW.internal(_root);
	@override late final Translations$candidateSheet$zh_TW candidateSheet = Translations$candidateSheet$zh_TW.internal(_root);
}

// Path: language
class Translations$language$zh_TW extends Translations$language$en {
	Translations$language$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get name => '繁體中文';
	@override String get english => '英文';
	@override String get chineseSimplified => '簡體中文';
	@override String get chineseTraditional => '繁體中文';
}

// Path: common
class Translations$common$zh_TW extends Translations$common$en {
	Translations$common$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get clearAll => '全部清除';
	@override String get reset => '重設';
}

// Path: settings
class Translations$settings$zh_TW extends Translations$settings$en {
	Translations$settings$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get preferences => '偏好設定';
	@override late final Translations$settings$language$zh_TW language = Translations$settings$language$zh_TW.internal(_root);
	@override late final Translations$settings$destinations$zh_TW destinations = Translations$settings$destinations$zh_TW.internal(_root);
	@override late final Translations$settings$display$zh_TW display = Translations$settings$display$zh_TW.internal(_root);
	@override late final Translations$settings$translation$zh_TW translation = Translations$settings$translation$zh_TW.internal(_root);
	@override late final Translations$settings$lyricConfig$zh_TW lyricConfig = Translations$settings$lyricConfig$zh_TW.internal(_root);
	@override late final Translations$settings$cache$zh_TW cache = Translations$settings$cache$zh_TW.internal(_root);
	@override late final Translations$settings$experimental$zh_TW experimental = Translations$settings$experimental$zh_TW.internal(_root);
	@override late final Translations$settings$priority$zh_TW priority = Translations$settings$priority$zh_TW.internal(_root);
	@override late final Translations$settings$misc$zh_TW misc = Translations$settings$misc$zh_TW.internal(_root);
	@override late final Translations$settings$appBar$zh_TW appBar = Translations$settings$appBar$zh_TW.internal(_root);
	@override late final Translations$settings$version$zh_TW version = Translations$settings$version$zh_TW.internal(_root);
}

// Path: lyrics
class Translations$lyrics$zh_TW extends Translations$lyrics$en {
	Translations$lyrics$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get noMedia => '未在播放';
	@override String get waitForMusic => '等待音樂...';
	@override String get clearCacheTooltip => '清除快取並重新載入';
	@override String get settingsTooltip => '設定';
	@override String get chooseLyricsTooltip => '選擇歌詞';
	@override String get noLyricsFound => '未找到本曲目的歌詞';
	@override String get startPlaying => '請開始播放音樂';
	@override String get pureMusic => '純音樂 / 器樂';
	@override late final Translations$lyrics$info$zh_TW info = Translations$lyrics$info$zh_TW.internal(_root);
}

// Path: permission
class Translations$permission$zh_TW extends Translations$permission$en {
	Translations$permission$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '需要通知存取權限';
	@override String get description => 'Fluent Lyrics 需要通知存取權限以從其他應用讀取媒體中繼資料。';
	@override String get grantAccess => '授予權限';
	@override String get alreadyGranted => '已授權？點這裡立即重新偵測。';
}

// Path: candidateSheet
class Translations$candidateSheet$zh_TW extends Translations$candidateSheet$en {
	Translations$candidateSheet$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '歌詞選擇器';
	@override String get lyricsTab => '歌詞';
	@override String get translationTab => '翻譯';
	@override String get searchingProviders => '正在搜尋來源...';
	@override String get noCandidates => '未找到候選項';
	@override String get refreshLyrics => '重新整理歌詞';
	@override String get markAsPureMusic => '標記為純音樂';
	@override String get searchingTranslations => '正在搜尋翻譯...';
	@override String get noAlternatives => '未找到候選項';
	@override String get refreshTranslations => '重新整理翻譯';
	@override String get markAsSkipped => '標記為略過';
	@override String get syncInstrumental => '純音樂';
	@override String get syncRich => 'Rich Sync';
	@override String get syncSynced => '已同步';
	@override String get syncPlain => '純文字';
	@override String get noLyricsPreview => '(無歌詞)';
	@override String get noTranslationPreview => '(無預覽)';
	@override String get chooseRichSource => '選擇 Rich Sync 來源';
	@override String richLines({required Object count}) => '${count} 個 rich 行';
	@override String get instrumentalTrack => '純音樂曲目';
	@override String lines({required Object count}) => '${count} 行';
	@override String get unknownProvider => '未知';
	@override String get richify => 'Richify';
}

// Path: settings.language
class Translations$settings$language$zh_TW extends Translations$settings$language$en {
	Translations$settings$language$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '語言';
	@override String get subtitle => '選擇介面語言';
	@override String get system => '跟隨系統';
}

// Path: settings.destinations
class Translations$settings$destinations$zh_TW extends Translations$settings$destinations$en {
	Translations$settings$destinations$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override late final Translations$settings$destinations$priority$zh_TW priority = Translations$settings$destinations$priority$zh_TW.internal(_root);
	@override late final Translations$settings$destinations$display$zh_TW display = Translations$settings$destinations$display$zh_TW.internal(_root);
	@override late final Translations$settings$destinations$translation$zh_TW translation = Translations$settings$destinations$translation$zh_TW.internal(_root);
	@override late final Translations$settings$destinations$lyricConfiguration$zh_TW lyricConfiguration = Translations$settings$destinations$lyricConfiguration$zh_TW.internal(_root);
	@override late final Translations$settings$destinations$cache$zh_TW cache = Translations$settings$destinations$cache$zh_TW.internal(_root);
	@override late final Translations$settings$destinations$experimental$zh_TW experimental = Translations$settings$destinations$experimental$zh_TW.internal(_root);
	@override late final Translations$settings$destinations$misc$zh_TW misc = Translations$settings$destinations$misc$zh_TW.internal(_root);
}

// Path: settings.display
class Translations$settings$display$zh_TW extends Translations$settings$display$en {
	Translations$settings$display$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '顯示設定';
	@override String get sectionDescription => '調整歌詞的顯示方式。';
	@override String get fontSize => '字型大小';
	@override String get fontSizeSubtitle => '歌詞文字的像素大小。';
	@override String get fontSizeReset => '重設為 36px';
	@override String get inactiveScale => '非活動行縮放';
	@override String get inactiveScaleSubtitle => '非高亮行的縮放比例。';
	@override String get inactiveScaleReset => '重設為 85%';
	@override String get blur => '模糊效果';
	@override String get blurSubtitle => '模糊非活動歌詞行以聚焦當前行。';
	@override String get backgroundMotion => '背景動效';
	@override String get backgroundMotionSubtitle => '對背景套用碎片化封面圖並緩慢漂移。';
	@override String get linesBefore => '活動行前顯示數';
	@override String get linesBeforeSubtitle => '自動捲動時活動行之前顯示的行數。';
	@override String get linesBeforeReset => '重設為 2';
	@override String get autoResumeDelay => '自動恢復延遲';
	@override String get autoResumeDelaySubtitle => '手動捲動後,等待多少時間再恢復自動捲動。';
	@override String get autoResumeDelayReset => '重設為 5 秒';
	@override String get keepScreenOn => '螢幕常亮';
	@override String get keepScreenOnSubtitle => '歌詞畫面活躍時阻止裝置睡眠。';
	@override String get artworkMinSize => '封面最小尺寸';
	@override String get artworkMinSizeSubtitle => '拒絕媒體源提供的較短邊低於此閾值的封面，然後嘗試備選源。設為 0 則接受任意尺寸。';
	@override String get artworkMinSizeReset => '重置為 300px';
}

// Path: settings.translation
class Translations$settings$translation$zh_TW extends Translations$settings$translation$en {
	Translations$settings$translation$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '翻譯設定';
	@override String get sectionDescription => '設定翻譯相關項目。';
	@override String get enable => '啟用翻譯';
	@override String get enableSubtitle => '在可用時顯示翻譯後的歌詞。';
	@override String get highlightOnly => '僅在高亮行顯示翻譯';
	@override String get highlightOnlySubtitle => '對非活動行隱藏翻譯。';
	@override String get targetLanguageTitle => '目標語言代碼';
	@override String get targetLanguageDescription => '以逗號分隔語言代碼。應用會按指定順序嘗試尋找第一個可用的翻譯。區分大小寫。';
	@override String get targetLanguageNoteMusixmatch => '* Musixmatch 使用 "zht" 代表繁體中文，"zh" 代表簡體中文';
	@override String get targetLanguageNoteLlm => '* LLM 需要自然語言輸入，使用 "llm: [English]" 前綴來指定目標語言';
	@override String get targetLanguageNoteCJK => '* QQ 音樂和網易雲只支援 "zh_CN"';
	@override String get targetLanguageHint => '例如 en, zht, zh, jp';
	@override String get bias => '翻譯時間偏移';
	@override String get biasSubtitle => '調整翻譯行的時間偏移(毫秒)。';
	@override String get biasReset => '重設為 50ms';
	@override String get alignmentThreshold => '對齊相似度閾值';
	@override String get alignmentThresholdSubtitle => '將翻譯與原文行配對所需的最小相似度百分比。';
	@override String get alignmentThresholdReset => '重設為 80%';
	@override String get coverageThreshold => '快取覆蓋率閾值';
	@override String get coverageThresholdSubtitle => '快取翻譯需要符合目前歌詞行的最小百分比。僅當來源不同時使用。';
	@override String get coverageThresholdReset => '重設為 80%';
	@override String get llmTitle => 'LLM 設定';
	@override String get llmEndpointLabel => 'OpenAI 相容 API Base URL';
	@override String get llmEndpointHint => 'https://api.openai.com/v1';
	@override String get llmApiKeyLabel => 'API Key';
	@override String get llmModelLabel => '模型名稱';
	@override String get llmModelHint => 'openai/gpt-oss-120b';
	@override String get llmReasoningTitle => '推理強度';
	@override String get llmReasoningSubtitle => '設定模型推理強度等級。選擇 "自動" 將使用預設參數，不明確傳遞 reasoning 欄位。';
	@override String get llmReasoningNone => '無';
	@override String get llmReasoningLow => '低';
	@override String get llmReasoningMedium => '中';
	@override String get llmReasoningHigh => '高';
	@override String get llmReasoningAuto => '自動';
}

// Path: settings.lyricConfig
class Translations$settings$lyricConfig$zh_TW extends Translations$settings$lyricConfig$en {
	Translations$settings$lyricConfig$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '歌詞設定';
	@override String get sectionDescription => '設定歌詞的擷取與處理方式。';
	@override String get richSync => 'Rich Sync';
	@override String get richSyncSubtitle => '啟用逐字同步。';
	@override String get globalOffset => '全域歌詞偏移';
	@override String get globalOffsetSubtitle => '為所有歌詞設定預設偏移 (例如裝置存在音訊延遲)。';
	@override String get globalOffsetReset => '重設為 0 秒';
	@override String get trimTitle => '修剪中繼資料行';
	@override String get trimSubtitle => '嘗試從選定來源中移除製作人員/中繼資料行。';
	@override String get musixmatchTitle => 'Musixmatch Token';
	@override String get musixmatchSubtitle => 'Musixmatch 來源所必需。';
	@override String get musixmatchHint => '輸入你的 User Token';
	@override String get getNewToken => '取得新 Token';
	@override String get tokenSaved => 'Token 已儲存';
	@override String get tokenAcquired => '已取得新 Token';
	@override String get tokenFailed => '取得新 Token 失敗';
}

// Path: settings.cache
class Translations$settings$cache$zh_TW extends Translations$settings$cache$en {
	Translations$settings$cache$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '快取管理';
	@override String get sectionDescription => '管理本機歌詞儲存。';
	@override String get lyricsCacheTitle => '歌詞快取';
	@override String get lyricsCacheDescription => '清除快取將強制應用重新搜尋歌詞。';
	@override String lyricsCacheStats({required Object count, required Object size}) => '${count} 項，${size} (估算)';
	@override String get clearDialogTitle => '清除快取';
	@override String get clearDialogContent => '確定要清除所有已快取的歌詞嗎?';
	@override String get cleared => '快取已清除';
	@override String get clearLyricsCacheButton => '清除所有歌詞快取';
	@override String get artworkCacheTitle => '封面快取';
	@override String get artworkCacheDescription => '清除快取將強制應用重新下載封面。';
	@override String artworkCacheStats({required Object count, required Object size}) => '${count} 項，${size}';
	@override String get artworkClearDialogTitle => '清除封面快取';
	@override String get artworkClearDialogContent => '確定要清除所有已快取的封面嗎？';
	@override String get artworkCleared => '封面快取已清除';
	@override String get clearArtworkCacheButton => '清除所有封面快取';
}

// Path: settings.experimental
class Translations$settings$experimental$zh_TW extends Translations$settings$experimental$en {
	Translations$settings$experimental$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '實驗性';
	@override String get sectionDescription => '試用新功能，部分可能不穩定。';
	@override String get richInlineFix => 'Rich 字型大小錯位修正';
	@override String get richInlineFixSubtitle => '為 rich inline 歌詞啟用字型大小調整 (除以 0.9)。可修復某些字型或裝置上的對齊問題。';
}

// Path: settings.priority
class Translations$settings$priority$zh_TW extends Translations$settings$priority$en {
	Translations$settings$priority$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '來源優先序';
	@override String get sectionDescription => '調整來源順序以優先從哪裡擷取歌詞。拖到 "已停用區域" 下方即可停用。';
	@override String get lyricsCacheTitle => '歌詞快取';
	@override String get lyricsCacheSubtitle => '啟用時始終優先';
	@override String get disabledArea => '已停用區域';
	@override String get updated => '優先序已更新';
	@override String get cacheEnabled => '快取已啟用';
	@override String get cacheDisabled => '快取已停用';
	@override late final Translations$settings$priority$providers$zh_TW providers = Translations$settings$priority$providers$zh_TW.internal(_root);
}

// Path: settings.misc
class Translations$settings$misc$zh_TW extends Translations$settings$misc$en {
	Translations$settings$misc$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '雜項';
	@override String get sectionDescription => '雜項選項。';
	@override String get tray => '系統匣圖示';
	@override String get traySubtitle => '在系統匣顯示 Fluent Lyrics 圖示，提供快速顯隱和結束操作。Linux 需要 AppIndicator (如 libayatana-appindicator)。';
	@override String get hideToTray => '關閉時隱藏到系統匣';
	@override String get hideToTraySubtitle => '關閉主視窗時隱藏到系統匣而非結束。背景仍會繼續擷取歌詞與翻譯;隱藏時 UI 繪製暫停。請使用系統匣選單結束。';
	@override String get unsupported => '目前平台暫無此類選項 — 系統匣和歌詞輸出僅在 Linux 和 macOS 桌面端可用。';
	@override String get streamTitle => '歌詞輸出';
	@override String get streamDescription => '隨播放進度將目前演唱的歌詞行附加寫入純文字檔案。翻譯檔案與歌詞檔案逐行對應；無翻譯的行寫為空行，便於外部工具依行號索引。留空即可停用對應輸出 — 之前的檔案 (若由 Fluent Lyrics 建立) 將被刪除。';
	@override String get lyricsPathLabel => '歌詞檔案路徑';
	@override String get translationPathLabel => '翻譯檔案路徑';
}

// Path: settings.appBar
class Translations$settings$appBar$zh_TW extends Translations$settings$appBar$en {
	Translations$settings$appBar$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get lyricsConfiguration => '歌詞設定';
}

// Path: settings.version
class Translations$settings$version$zh_TW extends Translations$settings$version$en {
	Translations$settings$version$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String label({required Object version}) => 'Fluent Lyrics ${version}';
}

// Path: lyrics.info
class Translations$lyrics$info$zh_TW extends Translations$lyrics$info$en {
	Translations$lyrics$info$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String source({required Object value}) => '來源：${value}';
	@override String writtenBy({required Object value}) => '作詞：${value}';
	@override String composer({required Object value}) => '作曲：${value}';
	@override String contributor({required Object value}) => '貢獻者：${value}';
	@override String copyright({required Object value}) => '版權：${value}';
	@override String translationProvider({required Object value}) => '翻譯來源：${value}';
	@override String translationContributor({required Object value}) => '翻譯貢獻者：${value}';
}

// Path: settings.destinations.priority
class Translations$settings$destinations$priority$zh_TW extends Translations$settings$destinations$priority$en {
	Translations$settings$destinations$priority$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '來源優先序';
	@override String get subtitle => '調整順序並啟用/停用歌詞來源';
}

// Path: settings.destinations.display
class Translations$settings$destinations$display$zh_TW extends Translations$settings$destinations$display$en {
	Translations$settings$destinations$display$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '顯示';
	@override String get subtitle => '字型大小、模糊、背景動效、捲動行為';
}

// Path: settings.destinations.translation
class Translations$settings$destinations$translation$zh_TW extends Translations$settings$destinations$translation$en {
	Translations$settings$destinations$translation$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '翻譯';
	@override String get subtitle => '翻譯目標語言、LLM 設定、對齊';
}

// Path: settings.destinations.lyricConfiguration
class Translations$settings$destinations$lyricConfiguration$zh_TW extends Translations$settings$destinations$lyricConfiguration$en {
	Translations$settings$destinations$lyricConfiguration$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '歌詞設定';
	@override String get subtitle => 'Rich sync、偏移、中繼資料修剪、Musixmatch token';
}

// Path: settings.destinations.cache
class Translations$settings$destinations$cache$zh_TW extends Translations$settings$destinations$cache$en {
	Translations$settings$destinations$cache$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '快取管理';
	@override String get subtitle => '清除歌詞與封面快取';
}

// Path: settings.destinations.experimental
class Translations$settings$destinations$experimental$zh_TW extends Translations$settings$destinations$experimental$en {
	Translations$settings$destinations$experimental$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '實驗性';
	@override String get subtitle => '不穩定的功能與修正';
}

// Path: settings.destinations.misc
class Translations$settings$destinations$misc$zh_TW extends Translations$settings$destinations$misc$en {
	Translations$settings$destinations$misc$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get title => '雜項';
	@override String get subtitle => '系統匣與其他雜項選項';
}

// Path: settings.priority.providers
class Translations$settings$priority$providers$zh_TW extends Translations$settings$priority$providers$en {
	Translations$settings$priority$providers$zh_TW.internal(TranslationsZhTw root) : this._root = root, super.internal(root);

	final TranslationsZhTw _root; // ignore: unused_field

	// Translations
	@override String get lrclibName => 'LRCLIB';
	@override String get lrclibDescription => '開源歌詞資料庫';
	@override String get musixmatchName => 'Musixmatch';
	@override String get musixmatchDescription => '全球最大的歌詞目錄';
	@override String get neteaseName => '網易雲音樂';
	@override String get neteaseDescription => '中國音樂服務,社群驅動的歌詞目錄';
	@override String get qqmusicName => 'QQ 音樂';
	@override String get qqmusicDescription => '騰訊旗下的中國音樂串流服務';
	@override String get llmName => 'LLM 翻譯';
	@override String get llmDescription => 'OpenAI 相容的 LLM API';
	@override String get cacheName => '快取';
	@override String get cacheDescription => '已快取的歌詞';
}
