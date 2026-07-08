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
class TranslationsZhCn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhCn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhCn,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <zh-CN>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsZhCn _root = this; // ignore: unused_field

	@override 
	TranslationsZhCn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhCn(meta: meta ?? this.$meta);

	// Translations
	@override late final Translations$language$zh_CN language = Translations$language$zh_CN.internal(_root);
	@override late final Translations$common$zh_CN common = Translations$common$zh_CN.internal(_root);
	@override late final Translations$settings$zh_CN settings = Translations$settings$zh_CN.internal(_root);
	@override late final Translations$lyrics$zh_CN lyrics = Translations$lyrics$zh_CN.internal(_root);
	@override late final Translations$permission$zh_CN permission = Translations$permission$zh_CN.internal(_root);
	@override late final Translations$candidateSheet$zh_CN candidateSheet = Translations$candidateSheet$zh_CN.internal(_root);
}

// Path: language
class Translations$language$zh_CN extends Translations$language$en {
	Translations$language$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get name => '简体中文';
	@override String get english => '英语';
	@override String get chineseSimplified => '简体中文';
	@override String get chineseTraditional => '繁体中文';
}

// Path: common
class Translations$common$zh_CN extends Translations$common$en {
	Translations$common$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get clearAll => '全部清除';
	@override String get reset => '重置';
}

// Path: settings
class Translations$settings$zh_CN extends Translations$settings$en {
	Translations$settings$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get preferences => '偏好设置';
	@override late final Translations$settings$language$zh_CN language = Translations$settings$language$zh_CN.internal(_root);
	@override late final Translations$settings$destinations$zh_CN destinations = Translations$settings$destinations$zh_CN.internal(_root);
	@override late final Translations$settings$display$zh_CN display = Translations$settings$display$zh_CN.internal(_root);
	@override late final Translations$settings$translation$zh_CN translation = Translations$settings$translation$zh_CN.internal(_root);
	@override late final Translations$settings$lyricConfig$zh_CN lyricConfig = Translations$settings$lyricConfig$zh_CN.internal(_root);
	@override late final Translations$settings$cache$zh_CN cache = Translations$settings$cache$zh_CN.internal(_root);
	@override late final Translations$settings$experimental$zh_CN experimental = Translations$settings$experimental$zh_CN.internal(_root);
	@override late final Translations$settings$priority$zh_CN priority = Translations$settings$priority$zh_CN.internal(_root);
	@override late final Translations$settings$misc$zh_CN misc = Translations$settings$misc$zh_CN.internal(_root);
	@override late final Translations$settings$appBar$zh_CN appBar = Translations$settings$appBar$zh_CN.internal(_root);
	@override late final Translations$settings$version$zh_CN version = Translations$settings$version$zh_CN.internal(_root);
}

// Path: lyrics
class Translations$lyrics$zh_CN extends Translations$lyrics$en {
	Translations$lyrics$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get noMedia => '未在播放';
	@override String get waitForMusic => '等待音乐...';
	@override String get clearCacheTooltip => '清除缓存并重新加载';
	@override String get settingsTooltip => '设置';
	@override String get chooseLyricsTooltip => '选择歌词';
	@override String get noLyricsFound => '未找到本曲目的歌词';
	@override String get startPlaying => '请开始播放音乐';
	@override String get pureMusic => '纯音乐 / 器乐';
	@override late final Translations$lyrics$info$zh_CN info = Translations$lyrics$info$zh_CN.internal(_root);
}

// Path: permission
class Translations$permission$zh_CN extends Translations$permission$en {
	Translations$permission$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '需要通知访问权限';
	@override String get description => 'Fluent Lyrics 需要通知访问权限以从其他应用读取媒体元数据。';
	@override String get grantAccess => '授予权限';
	@override String get alreadyGranted => '已授权？点这里立即重新检测。';
}

// Path: candidateSheet
class Translations$candidateSheet$zh_CN extends Translations$candidateSheet$en {
	Translations$candidateSheet$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '歌词选择器';
	@override String get lyricsTab => '歌词';
	@override String get translationTab => '翻译';
	@override String get searchingProviders => '正在搜索源...';
	@override String get noCandidates => '未找到候选项';
	@override String get refreshLyrics => '刷新歌词';
	@override String get markAsPureMusic => '标记为纯音乐';
	@override String get searchingTranslations => '正在搜索翻译...';
	@override String get noAlternatives => '未找到候选项';
	@override String get refreshTranslations => '刷新翻译';
	@override String get markAsSkipped => '标记为跳过';
	@override String get syncInstrumental => '纯音乐';
	@override String get syncRich => 'Rich Sync';
	@override String get syncSynced => '已同步';
	@override String get syncPlain => '纯文本';
	@override String get noLyricsPreview => '(无歌词)';
	@override String get noTranslationPreview => '(无预览)';
	@override String get chooseRichSource => '选择 Rich Sync 来源';
	@override String richLines({required Object count}) => '${count} 个 rich 行';
	@override String get instrumentalTrack => '纯音乐曲目';
	@override String lines({required Object count}) => '${count} 行';
	@override String get unknownProvider => '未知';
	@override String get richify => 'Richify';
}

// Path: settings.language
class Translations$settings$language$zh_CN extends Translations$settings$language$en {
	Translations$settings$language$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '语言';
	@override String get subtitle => '选择界面语言';
	@override String get system => '跟随系统';
}

// Path: settings.destinations
class Translations$settings$destinations$zh_CN extends Translations$settings$destinations$en {
	Translations$settings$destinations$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override late final Translations$settings$destinations$priority$zh_CN priority = Translations$settings$destinations$priority$zh_CN.internal(_root);
	@override late final Translations$settings$destinations$display$zh_CN display = Translations$settings$destinations$display$zh_CN.internal(_root);
	@override late final Translations$settings$destinations$translation$zh_CN translation = Translations$settings$destinations$translation$zh_CN.internal(_root);
	@override late final Translations$settings$destinations$lyricConfiguration$zh_CN lyricConfiguration = Translations$settings$destinations$lyricConfiguration$zh_CN.internal(_root);
	@override late final Translations$settings$destinations$cache$zh_CN cache = Translations$settings$destinations$cache$zh_CN.internal(_root);
	@override late final Translations$settings$destinations$experimental$zh_CN experimental = Translations$settings$destinations$experimental$zh_CN.internal(_root);
	@override late final Translations$settings$destinations$misc$zh_CN misc = Translations$settings$destinations$misc$zh_CN.internal(_root);
}

// Path: settings.display
class Translations$settings$display$zh_CN extends Translations$settings$display$en {
	Translations$settings$display$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '显示配置';
	@override String get sectionDescription => '调整歌词的显示方式。';
	@override String get fontSize => '字体大小';
	@override String get fontSizeSubtitle => '歌词文本的像素大小。';
	@override String get fontSizeReset => '重置为 36px';
	@override String get inactiveScale => '非活动行缩放';
	@override String get inactiveScaleSubtitle => '非高亮行的缩放比例。';
	@override String get inactiveScaleReset => '重置为 85%';
	@override String get blur => '模糊效果';
	@override String get blurSubtitle => '模糊非活动歌词行以聚焦当前行。';
	@override String get backgroundMotion => '背景动效';
	@override String get backgroundMotionSubtitle => '对背景应用碎片化封面图并缓慢漂移。';
	@override String get linesBefore => '活动行前显示数';
	@override String get linesBeforeSubtitle => '自动滚动时活动行之前显示的行数。';
	@override String get linesBeforeReset => '重置为 2';
	@override String get autoResumeDelay => '自动恢复延迟';
	@override String get autoResumeDelaySubtitle => '手动滚动后,等待多少时间再恢复自动滚动。';
	@override String get autoResumeDelayReset => '重置为 5 秒';
	@override String get keepScreenOn => '屏幕常亮';
	@override String get keepScreenOnSubtitle => '歌词页面活跃时阻止设备休眠。';
	@override String get artworkMinSize => '封面最小尺寸';
	@override String get artworkMinSizeSubtitle => '拒绝媒体源提供的较短边低于此阈值的封面，然后尝试备选源。设为 0 则接受任意尺寸。';
	@override String get artworkMinSizeReset => '重置为 300px';
}

// Path: settings.translation
class Translations$settings$translation$zh_CN extends Translations$settings$translation$en {
	Translations$settings$translation$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '翻译配置';
	@override String get sectionDescription => '配置翻译相关设置。';
	@override String get enable => '启用翻译';
	@override String get enableSubtitle => '在可用时显示翻译后的歌词。';
	@override String get highlightOnly => '仅在高亮行显示翻译';
	@override String get highlightOnlySubtitle => '对非活动行隐藏翻译。';
	@override String get targetLanguageTitle => '目标语言代码';
	@override String get targetLanguageDescription => '用逗号分隔语言代码。应用会按指定顺序尝试查找第一个可用的翻译。区分大小写。';
	@override String get targetLanguageNoteMusixmatch => '* Musixmatch 使用 "zht" 代表繁体中文，"zh" 代表简体中文';
	@override String get targetLanguageNoteLlm => '* LLM 需要自然语言输入，使用 "llm: [English]" 前缀来指定目标语言';
	@override String get targetLanguageNoteCJK => '* QQ 音乐和网易云只支持 "zh_CN"';
	@override String get targetLanguageHint => '例如 en, zht, zh, jp';
	@override String get bias => '翻译时间偏移';
	@override String get biasSubtitle => '调整翻译行的时间偏移 (毫秒)。';
	@override String get biasReset => '重置为 50ms';
	@override String get alignmentThreshold => '对齐相似度阈值';
	@override String get alignmentThresholdSubtitle => '将翻译与原文行配对所需的最小相似度百分比。';
	@override String get alignmentThresholdReset => '重置为 80%';
	@override String get coverageThreshold => '缓存覆盖率阈值';
	@override String get coverageThresholdSubtitle => '缓存翻译需要匹配当前歌词行的最小百分比。仅当来源不同时使用。';
	@override String get coverageThresholdReset => '重置为 80%';
	@override String get llmTitle => 'LLM 配置';
	@override String get llmEndpointLabel => 'OpenAI 兼容 API Base URL';
	@override String get llmEndpointHint => 'https://api.openai.com/v1';
	@override String get llmApiKeyLabel => 'API Key';
	@override String get llmModelLabel => '模型名称';
	@override String get llmModelHint => 'openai/gpt-oss-120b';
	@override String get llmReasoningTitle => '推理强度';
	@override String get llmReasoningSubtitle => '设置模型推理强度等级。选择 "自动" 将使用默认参数,不显式传递 reasoning 字段。';
	@override String get llmReasoningNone => '无';
	@override String get llmReasoningLow => '低';
	@override String get llmReasoningMedium => '中';
	@override String get llmReasoningHigh => '高';
	@override String get llmReasoningAuto => '自动';
}

// Path: settings.lyricConfig
class Translations$settings$lyricConfig$zh_CN extends Translations$settings$lyricConfig$en {
	Translations$settings$lyricConfig$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '歌词配置';
	@override String get sectionDescription => '配置歌词的获取与处理方式。';
	@override String get richSync => 'Rich Sync';
	@override String get richSyncSubtitle => '启用逐词同步。';
	@override String get globalOffset => '全局歌词偏移';
	@override String get globalOffsetSubtitle => '为所有歌词设置默认偏移 (例如设备存在音频延迟)。';
	@override String get globalOffsetReset => '重置为 0 秒';
	@override String get trimTitle => '修剪元数据行';
	@override String get trimSubtitle => '尝试从选定源中移除制作人员/元数据行。';
	@override String get musixmatchTitle => 'Musixmatch Token';
	@override String get musixmatchSubtitle => 'Musixmatch 源所必需。';
	@override String get musixmatchHint => '输入你的 User Token';
	@override String get getNewToken => '获取新 Token';
	@override String get tokenSaved => 'Token 已保存';
	@override String get tokenAcquired => '已获取新 Token';
	@override String get tokenFailed => '获取新 Token 失败';
}

// Path: settings.cache
class Translations$settings$cache$zh_CN extends Translations$settings$cache$en {
	Translations$settings$cache$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '缓存管理';
	@override String get sectionDescription => '管理本地歌词存储。';
	@override String get lyricsCacheTitle => '歌词缓存';
	@override String get lyricsCacheDescription => '清除缓存将强制应用重新搜索歌词。';
	@override String lyricsCacheStats({required Object count, required Object size}) => '${count} 项，${size} (估算)';
	@override String get clearDialogTitle => '清除缓存';
	@override String get clearDialogContent => '确定要清除所有已缓存的歌词吗?';
	@override String get cleared => '缓存已清除';
	@override String get clearLyricsCacheButton => '清除所有歌词缓存';
	@override String get artworkCacheTitle => '封面缓存';
	@override String get artworkCacheDescription => '清除缓存将强制应用重新下载封面。';
	@override String artworkCacheStats({required Object count, required Object size}) => '${count} 项，${size}';
	@override String get artworkClearDialogTitle => '清除封面缓存';
	@override String get artworkClearDialogContent => '确定要清除所有已缓存的封面吗？';
	@override String get artworkCleared => '封面缓存已清除';
	@override String get clearArtworkCacheButton => '清除所有封面缓存';
}

// Path: settings.experimental
class Translations$settings$experimental$zh_CN extends Translations$settings$experimental$en {
	Translations$settings$experimental$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '实验性';
	@override String get sectionDescription => '试用新功能,部分可能不稳定。';
	@override String get richInlineFix => 'Rich 字体大小错位修复';
	@override String get richInlineFixSubtitle => '为 rich inline 歌词启用字体大小调整 (除以 0.9)。可修复某些字体或设备上的对齐问题。';
}

// Path: settings.priority
class Translations$settings$priority$zh_CN extends Translations$settings$priority$en {
	Translations$settings$priority$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '源优先级';
	@override String get sectionDescription => '调整源顺序以优先从哪里获取歌词。拖到 "已禁用区域" 下方即可禁用。';
	@override String get lyricsCacheTitle => '歌词缓存';
	@override String get lyricsCacheSubtitle => '启用时始终优先';
	@override String get disabledArea => '已禁用区域';
	@override String get updated => '优先级已更新';
	@override String get cacheEnabled => '缓存已启用';
	@override String get cacheDisabled => '缓存已禁用';
	@override late final Translations$settings$priority$providers$zh_CN providers = Translations$settings$priority$providers$zh_CN.internal(_root);
}

// Path: settings.misc
class Translations$settings$misc$zh_CN extends Translations$settings$misc$en {
	Translations$settings$misc$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => '杂项';
	@override String get sectionDescription => '杂项选项。';
	@override String get tray => '系统托盘图标';
	@override String get traySubtitle => '在系统托盘显示 Fluent Lyrics 图标，提供快速显隐和退出操作。Linux 需要 AppIndicator (如 libayatana-appindicator)。';
	@override String get hideToTray => '关闭时隐藏到托盘';
	@override String get hideToTraySubtitle => '关闭主窗口时隐藏到托盘而非退出。后台仍会继续获取歌词与翻译;隐藏时 UI 渲染暂停。请使用托盘菜单退出。';
	@override String get unsupported => '当前平台暂无此类选项 — 系统托盘和歌词输出仅在 Linux 和 macOS 桌面端可用。';
	@override String get streamTitle => '歌词输出';
	@override String get streamDescription => '随播放进度将当前演唱的歌词行追加写入纯文本文件。翻译文件与歌词文件逐行对应；无翻译的行写为空行，便于外部工具按行号索引。留空即可禁用对应输出 — 之前的文件 (若由 Fluent Lyrics 创建) 将被删除。';
	@override String get lyricsPathLabel => '歌词文件路径';
	@override String get translationPathLabel => '翻译文件路径';
}

// Path: settings.appBar
class Translations$settings$appBar$zh_CN extends Translations$settings$appBar$en {
	Translations$settings$appBar$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get lyricsConfiguration => '歌词配置';
}

// Path: settings.version
class Translations$settings$version$zh_CN extends Translations$settings$version$en {
	Translations$settings$version$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String label({required Object version}) => 'Fluent Lyrics ${version}';
}

// Path: lyrics.info
class Translations$lyrics$info$zh_CN extends Translations$lyrics$info$en {
	Translations$lyrics$info$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String source({required Object value}) => '来源：${value}';
	@override String writtenBy({required Object value}) => '作词：${value}';
	@override String composer({required Object value}) => '作曲：${value}';
	@override String contributor({required Object value}) => '贡献者：${value}';
	@override String copyright({required Object value}) => '版权：${value}';
	@override String translationProvider({required Object value}) => '翻译来源：${value}';
	@override String translationContributor({required Object value}) => '翻译贡献者：${value}';
}

// Path: settings.destinations.priority
class Translations$settings$destinations$priority$zh_CN extends Translations$settings$destinations$priority$en {
	Translations$settings$destinations$priority$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '源优先级';
	@override String get subtitle => '调整顺序并启用/禁用歌词源';
}

// Path: settings.destinations.display
class Translations$settings$destinations$display$zh_CN extends Translations$settings$destinations$display$en {
	Translations$settings$destinations$display$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '显示';
	@override String get subtitle => '字体大小、模糊、背景动效、滚动行为';
}

// Path: settings.destinations.translation
class Translations$settings$destinations$translation$zh_CN extends Translations$settings$destinations$translation$en {
	Translations$settings$destinations$translation$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '翻译';
	@override String get subtitle => '翻译目标语言、LLM 配置、对齐';
}

// Path: settings.destinations.lyricConfiguration
class Translations$settings$destinations$lyricConfiguration$zh_CN extends Translations$settings$destinations$lyricConfiguration$en {
	Translations$settings$destinations$lyricConfiguration$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '歌词配置';
	@override String get subtitle => 'Rich sync、偏移、元数据修剪、Musixmatch token';
}

// Path: settings.destinations.cache
class Translations$settings$destinations$cache$zh_CN extends Translations$settings$destinations$cache$en {
	Translations$settings$destinations$cache$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '缓存管理';
	@override String get subtitle => '清理歌词与封面缓存';
}

// Path: settings.destinations.experimental
class Translations$settings$destinations$experimental$zh_CN extends Translations$settings$destinations$experimental$en {
	Translations$settings$destinations$experimental$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '实验性';
	@override String get subtitle => '不稳定的功能与修复';
}

// Path: settings.destinations.misc
class Translations$settings$destinations$misc$zh_CN extends Translations$settings$destinations$misc$en {
	Translations$settings$destinations$misc$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get title => '杂项';
	@override String get subtitle => '系统托盘及其他杂项选项';
}

// Path: settings.priority.providers
class Translations$settings$priority$providers$zh_CN extends Translations$settings$priority$providers$en {
	Translations$settings$priority$providers$zh_CN.internal(TranslationsZhCn root) : this._root = root, super.internal(root);

	final TranslationsZhCn _root; // ignore: unused_field

	// Translations
	@override String get lrclibName => 'LRCLIB';
	@override String get lrclibDescription => '开源歌词数据库';
	@override String get musixmatchName => 'Musixmatch';
	@override String get musixmatchDescription => '全球最大的歌词目录';
	@override String get neteaseName => '网易云音乐';
	@override String get neteaseDescription => '中国音乐服务,社区驱动的歌词目录';
	@override String get qqmusicName => 'QQ 音乐';
	@override String get qqmusicDescription => '腾讯旗下的中国音乐流媒体服务';
	@override String get llmName => 'LLM 翻译';
	@override String get llmDescription => 'OpenAI 兼容的 LLM API';
	@override String get cacheName => '缓存';
	@override String get cacheDescription => '已缓存的歌词';
}
