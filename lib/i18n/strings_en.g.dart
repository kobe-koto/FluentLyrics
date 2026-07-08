///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  );

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$language$en language = Translations$language$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$lyrics$en lyrics = Translations$lyrics$en.internal(_root);
	late final Translations$permission$en permission = Translations$permission$en.internal(_root);
	late final Translations$candidateSheet$en candidateSheet = Translations$candidateSheet$en.internal(_root);
}

// Path: language
class Translations$language$en {
	Translations$language$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'English'
	String get name => 'English';

	/// en: 'English'
	String get english => 'English';

	/// en: 'Simplified Chinese'
	String get chineseSimplified => 'Simplified Chinese';

	/// en: 'Traditional Chinese'
	String get chineseTraditional => 'Traditional Chinese';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'CANCEL'
	String get cancel => 'CANCEL';

	/// en: 'CLEAR ALL'
	String get clearAll => 'CLEAR ALL';

	/// en: 'Reset'
	String get reset => 'Reset';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Preferences'
	String get preferences => 'Preferences';

	late final Translations$settings$language$en language = Translations$settings$language$en.internal(_root);
	late final Translations$settings$destinations$en destinations = Translations$settings$destinations$en.internal(_root);
	late final Translations$settings$display$en display = Translations$settings$display$en.internal(_root);
	late final Translations$settings$translation$en translation = Translations$settings$translation$en.internal(_root);
	late final Translations$settings$lyricConfig$en lyricConfig = Translations$settings$lyricConfig$en.internal(_root);
	late final Translations$settings$cache$en cache = Translations$settings$cache$en.internal(_root);
	late final Translations$settings$experimental$en experimental = Translations$settings$experimental$en.internal(_root);
	late final Translations$settings$priority$en priority = Translations$settings$priority$en.internal(_root);
	late final Translations$settings$misc$en misc = Translations$settings$misc$en.internal(_root);
	late final Translations$settings$appBar$en appBar = Translations$settings$appBar$en.internal(_root);
	late final Translations$settings$version$en version = Translations$settings$version$en.internal(_root);
}

// Path: lyrics
class Translations$lyrics$en {
	Translations$lyrics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No Media Playing'
	String get noMedia => 'No Media Playing';

	/// en: 'Wait for music...'
	String get waitForMusic => 'Wait for music...';

	/// en: 'Clear cache & reload'
	String get clearCacheTooltip => 'Clear cache & reload';

	/// en: 'Settings'
	String get settingsTooltip => 'Settings';

	/// en: 'Choose lyrics'
	String get chooseLyricsTooltip => 'Choose lyrics';

	/// en: 'No lyrics found for this track'
	String get noLyricsFound => 'No lyrics found for this track';

	/// en: 'Start playing music'
	String get startPlaying => 'Start playing music';

	/// en: 'Pure Music / Instrumental'
	String get pureMusic => 'Pure Music / Instrumental';

	late final Translations$lyrics$info$en info = Translations$lyrics$info$en.internal(_root);
}

// Path: permission
class Translations$permission$en {
	Translations$permission$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Notification Access Required'
	String get title => 'Notification Access Required';

	/// en: 'Fluent Lyrics needs notification access to read media metadata from other apps.'
	String get description => 'Fluent Lyrics needs notification access to read media metadata from other apps.';

	/// en: 'GRANT ACCESS'
	String get grantAccess => 'GRANT ACCESS';

	/// en: 'Already granted? Tap to check now.'
	String get alreadyGranted => 'Already granted? Tap to check now.';
}

// Path: candidateSheet
class Translations$candidateSheet$en {
	Translations$candidateSheet$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Lyrics Picker'
	String get title => 'Lyrics Picker';

	/// en: 'Lyrics'
	String get lyricsTab => 'Lyrics';

	/// en: 'Translation'
	String get translationTab => 'Translation';

	/// en: 'Searching providers…'
	String get searchingProviders => 'Searching providers…';

	/// en: 'No candidates found'
	String get noCandidates => 'No candidates found';

	/// en: 'Refresh Lyrics'
	String get refreshLyrics => 'Refresh Lyrics';

	/// en: 'Mark as pure music'
	String get markAsPureMusic => 'Mark as pure music';

	/// en: 'Searching translations...'
	String get searchingTranslations => 'Searching translations...';

	/// en: 'No alternatives found'
	String get noAlternatives => 'No alternatives found';

	/// en: 'Refresh Translations'
	String get refreshTranslations => 'Refresh Translations';

	/// en: 'Mark as skipped'
	String get markAsSkipped => 'Mark as skipped';

	/// en: 'Instrumental'
	String get syncInstrumental => 'Instrumental';

	/// en: 'Rich Sync'
	String get syncRich => 'Rich Sync';

	/// en: 'Synced'
	String get syncSynced => 'Synced';

	/// en: 'Plain'
	String get syncPlain => 'Plain';

	/// en: '(no lyrics)'
	String get noLyricsPreview => '(no lyrics)';

	/// en: '(no preview)'
	String get noTranslationPreview => '(no preview)';

	/// en: 'Choose Rich Sync Source'
	String get chooseRichSource => 'Choose Rich Sync Source';

	/// en: '{{count}} rich lines'
	String richLines({required Object count}) => '${count} rich lines';

	/// en: 'Instrumental track'
	String get instrumentalTrack => 'Instrumental track';

	/// en: '{{count}} lines'
	String lines({required Object count}) => '${count} lines';

	/// en: 'Unknown'
	String get unknownProvider => 'Unknown';

	/// en: 'Richify'
	String get richify => 'Richify';
}

// Path: settings.language
class Translations$settings$language$en {
	Translations$settings$language$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Language'
	String get title => 'Language';

	/// en: 'Choose the interface language'
	String get subtitle => 'Choose the interface language';

	/// en: 'Follow system'
	String get system => 'Follow system';
}

// Path: settings.destinations
class Translations$settings$destinations$en {
	Translations$settings$destinations$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$destinations$priority$en priority = Translations$settings$destinations$priority$en.internal(_root);
	late final Translations$settings$destinations$display$en display = Translations$settings$destinations$display$en.internal(_root);
	late final Translations$settings$destinations$translation$en translation = Translations$settings$destinations$translation$en.internal(_root);
	late final Translations$settings$destinations$lyricConfiguration$en lyricConfiguration = Translations$settings$destinations$lyricConfiguration$en.internal(_root);
	late final Translations$settings$destinations$cache$en cache = Translations$settings$destinations$cache$en.internal(_root);
	late final Translations$settings$destinations$experimental$en experimental = Translations$settings$destinations$experimental$en.internal(_root);
	late final Translations$settings$destinations$misc$en misc = Translations$settings$destinations$misc$en.internal(_root);
}

// Path: settings.display
class Translations$settings$display$en {
	Translations$settings$display$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Display Configuration'
	String get sectionTitle => 'Display Configuration';

	/// en: 'Adjust how lyrics are displayed.'
	String get sectionDescription => 'Adjust how lyrics are displayed.';

	/// en: 'Font Size'
	String get fontSize => 'Font Size';

	/// en: 'Size of the lyric text in pixels.'
	String get fontSizeSubtitle => 'Size of the lyric text in pixels.';

	/// en: 'Reset to 36px'
	String get fontSizeReset => 'Reset to 36px';

	/// en: 'Inactive Line Scale'
	String get inactiveScale => 'Inactive Line Scale';

	/// en: 'Scale factor for non-highlighted lines.'
	String get inactiveScaleSubtitle => 'Scale factor for non-highlighted lines.';

	/// en: 'Reset to 85%'
	String get inactiveScaleReset => 'Reset to 85%';

	/// en: 'Blur Effect'
	String get blur => 'Blur Effect';

	/// en: 'Blur non-active lyric lines for focus.'
	String get blurSubtitle => 'Blur non-active lyric lines for focus.';

	/// en: 'Background Motion'
	String get backgroundMotion => 'Background Motion';

	/// en: 'Apply fragmented artwork with slow drifting motion to the background.'
	String get backgroundMotionSubtitle => 'Apply fragmented artwork with slow drifting motion to the background.';

	/// en: 'Lines Before Active'
	String get linesBefore => 'Lines Before Active';

	/// en: 'Number of preceding lines to show when auto-scrolling.'
	String get linesBeforeSubtitle => 'Number of preceding lines to show when auto-scrolling.';

	/// en: 'Reset to 2'
	String get linesBeforeReset => 'Reset to 2';

	/// en: 'Auto-Resume Delay'
	String get autoResumeDelay => 'Auto-Resume Delay';

	/// en: 'Time to wait before auto-scrolling resumes after you manual scroll.'
	String get autoResumeDelaySubtitle => 'Time to wait before auto-scrolling resumes after you manual scroll.';

	/// en: 'Reset to 5s'
	String get autoResumeDelayReset => 'Reset to 5s';

	/// en: 'Keep Screen On'
	String get keepScreenOn => 'Keep Screen On';

	/// en: 'Prevent device from sleeping while lyrics screen is active.'
	String get keepScreenOnSubtitle => 'Prevent device from sleeping while lyrics screen is active.';

	/// en: 'Artwork Minimum Size'
	String get artworkMinSize => 'Artwork Minimum Size';

	/// en: 'Reject artwork from media sources whose shorter side is below this threshold, then try alternate sources. Set to 0 to accept any size.'
	String get artworkMinSizeSubtitle => 'Reject artwork from media sources whose shorter side is below this threshold, then try alternate sources. Set to 0 to accept any size.';

	/// en: 'Reset to 300px'
	String get artworkMinSizeReset => 'Reset to 300px';
}

// Path: settings.translation
class Translations$settings$translation$en {
	Translations$settings$translation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Translation Configuration'
	String get sectionTitle => 'Translation Configuration';

	/// en: 'Configure translation settings.'
	String get sectionDescription => 'Configure translation settings.';

	/// en: 'Enable Translation'
	String get enable => 'Enable Translation';

	/// en: 'Show translated lyrics if available.'
	String get enableSubtitle => 'Show translated lyrics if available.';

	/// en: 'Show Translation Only When Highlighted'
	String get highlightOnly => 'Show Translation Only When Highlighted';

	/// en: 'Hide translation for non-active lines.'
	String get highlightOnlySubtitle => 'Hide translation for non-active lines.';

	/// en: 'Target Language Code'
	String get targetLanguageTitle => 'Target Language Code';

	/// en: 'Enter language codes separated by commas. The app will try to find the first available translation in the specified order. Values are case-sensitive.'
	String get targetLanguageDescription => 'Enter language codes separated by commas. The app will try to find the first available translation in the specified order. Values are case-sensitive.';

	/// en: '* Musixmatch uses "zht" for Chinese (Traditional) and "zh" for Chinese (Simplified)'
	String get targetLanguageNoteMusixmatch => '* Musixmatch uses "zht" for Chinese (Traditional) and "zh" for Chinese (Simplified)';

	/// en: '* LLM requires netural language input, use prefix "llm: [English]" to indicate the target language'
	String get targetLanguageNoteLlm => '* LLM requires netural language input, use prefix "llm: [English]" to indicate the target language';

	/// en: '* QQ Music and Netease Music only supports "zh_CN"'
	String get targetLanguageNoteCJK => '* QQ Music and Netease Music only supports "zh_CN"';

	/// en: 'e.g. en, zht, zh, jp'
	String get targetLanguageHint => 'e.g. en, zht, zh, jp';

	/// en: 'Translation Bias'
	String get bias => 'Translation Bias';

	/// en: 'Adjust timing of translation lines (ms).'
	String get biasSubtitle => 'Adjust timing of translation lines (ms).';

	/// en: 'Reset to 50ms'
	String get biasReset => 'Reset to 50ms';

	/// en: 'Alignment Similarity Threshold'
	String get alignmentThreshold => 'Alignment Similarity Threshold';

	/// en: 'Min % similarity required to pair translation with original line.'
	String get alignmentThresholdSubtitle => 'Min % similarity required to pair translation with original line.';

	/// en: 'Reset to 80%'
	String get alignmentThresholdReset => 'Reset to 80%';

	/// en: 'Cache Coverage Threshold'
	String get coverageThreshold => 'Cache Coverage Threshold';

	/// en: 'Min % of current lyric lines that must match a cached translation. Only used when source providers differ.'
	String get coverageThresholdSubtitle => 'Min % of current lyric lines that must match a cached translation. Only used when source providers differ.';

	/// en: 'Reset to 80%'
	String get coverageThresholdReset => 'Reset to 80%';

	/// en: 'LLM Configuration'
	String get llmTitle => 'LLM Configuration';

	/// en: 'OpenAI Compatible API Base URL'
	String get llmEndpointLabel => 'OpenAI Compatible API Base URL';

	/// en: 'https://api.openai.com/v1'
	String get llmEndpointHint => 'https://api.openai.com/v1';

	/// en: 'API Key'
	String get llmApiKeyLabel => 'API Key';

	/// en: 'Model Name'
	String get llmModelLabel => 'Model Name';

	/// en: 'openai/gpt-oss-120b'
	String get llmModelHint => 'openai/gpt-oss-120b';

	/// en: 'Reasoning Effort'
	String get llmReasoningTitle => 'Reasoning Effort';

	/// en: 'Set the model's reasoning effort level. Select "auto" to use default parameters without explicitly passing the reasoning field.'
	String get llmReasoningSubtitle => 'Set the model\'s reasoning effort level. Select "auto" to use default parameters without explicitly passing the reasoning field.';

	/// en: 'None'
	String get llmReasoningNone => 'None';

	/// en: 'Low'
	String get llmReasoningLow => 'Low';

	/// en: 'Medium'
	String get llmReasoningMedium => 'Medium';

	/// en: 'High'
	String get llmReasoningHigh => 'High';

	/// en: 'Auto'
	String get llmReasoningAuto => 'Auto';
}

// Path: settings.lyricConfig
class Translations$settings$lyricConfig$en {
	Translations$settings$lyricConfig$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Lyric Configuration'
	String get sectionTitle => 'Lyric Configuration';

	/// en: 'Configure how lyrics are fetched and processed.'
	String get sectionDescription => 'Configure how lyrics are fetched and processed.';

	/// en: 'Rich Sync'
	String get richSync => 'Rich Sync';

	/// en: 'Enable word-level synchronization.'
	String get richSyncSubtitle => 'Enable word-level synchronization.';

	/// en: 'Global Lyrics Offset'
	String get globalOffset => 'Global Lyrics Offset';

	/// en: 'Set a default offset for all lyrics (e.g. if your device has audio latency).'
	String get globalOffsetSubtitle => 'Set a default offset for all lyrics (e.g. if your device has audio latency).';

	/// en: 'Reset to 0s'
	String get globalOffsetReset => 'Reset to 0s';

	/// en: 'Trim Metadata Lines'
	String get trimTitle => 'Trim Metadata Lines';

	/// en: 'Attempt to remove staff/metadata lines from selected providers.'
	String get trimSubtitle => 'Attempt to remove staff/metadata lines from selected providers.';

	/// en: 'Musixmatch Token'
	String get musixmatchTitle => 'Musixmatch Token';

	/// en: 'Required for Musixmatch provider.'
	String get musixmatchSubtitle => 'Required for Musixmatch provider.';

	/// en: 'Enter your User Token'
	String get musixmatchHint => 'Enter your User Token';

	/// en: 'Get New Token'
	String get getNewToken => 'Get New Token';

	/// en: 'Token saved'
	String get tokenSaved => 'Token saved';

	/// en: 'New token acquired'
	String get tokenAcquired => 'New token acquired';

	/// en: 'Failed to get new token'
	String get tokenFailed => 'Failed to get new token';
}

// Path: settings.cache
class Translations$settings$cache$en {
	Translations$settings$cache$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cache Management'
	String get sectionTitle => 'Cache Management';

	/// en: 'Manage local storage for lyrics.'
	String get sectionDescription => 'Manage local storage for lyrics.';

	/// en: 'Lyrics Cache'
	String get lyricsCacheTitle => 'Lyrics Cache';

	/// en: 'Clearing the cache will force the app to search for lyrics again.'
	String get lyricsCacheDescription => 'Clearing the cache will force the app to search for lyrics again.';

	/// en: '{{count}} items, {{size}} (Est.)'
	String lyricsCacheStats({required Object count, required Object size}) => '${count} items, ${size} (Est.)';

	/// en: 'Clear Cache'
	String get clearDialogTitle => 'Clear Cache';

	/// en: 'Are you sure you want to clear all cached lyrics?'
	String get clearDialogContent => 'Are you sure you want to clear all cached lyrics?';

	/// en: 'Cache cleared'
	String get cleared => 'Cache cleared';

	/// en: 'Clear All Lyrics Cache'
	String get clearLyricsCacheButton => 'Clear All Lyrics Cache';

	/// en: 'Artwork Cache'
	String get artworkCacheTitle => 'Artwork Cache';

	/// en: 'Clearing the cache will force the app to download artwork again.'
	String get artworkCacheDescription => 'Clearing the cache will force the app to download artwork again.';

	/// en: '{{count}} items, {{size}}'
	String artworkCacheStats({required Object count, required Object size}) => '${count} items, ${size}';

	/// en: 'Clear Artwork Cache'
	String get artworkClearDialogTitle => 'Clear Artwork Cache';

	/// en: 'Are you sure you want to clear all cached artwork?'
	String get artworkClearDialogContent => 'Are you sure you want to clear all cached artwork?';

	/// en: 'Artwork cache cleared'
	String get artworkCleared => 'Artwork cache cleared';

	/// en: 'Clear All Artwork Cache'
	String get clearArtworkCacheButton => 'Clear All Artwork Cache';
}

// Path: settings.experimental
class Translations$settings$experimental$en {
	Translations$settings$experimental$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Experimental'
	String get sectionTitle => 'Experimental';

	/// en: 'Try out new features. Some may be unstable.'
	String get sectionDescription => 'Try out new features. Some may be unstable.';

	/// en: 'Rich Parts Fonts Size Glitching Fix'
	String get richInlineFix => 'Rich Parts Fonts Size Glitching Fix';

	/// en: 'Enable the font size adjustment (divide by 0.9) for rich inline lyrics. This fixes alignment issues with certain fonts, or on some devices.'
	String get richInlineFixSubtitle => 'Enable the font size adjustment (divide by 0.9) for rich inline lyrics. This fixes alignment issues with certain fonts, or on some devices.';
}

// Path: settings.priority
class Translations$settings$priority$en {
	Translations$settings$priority$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Provider Priority'
	String get sectionTitle => 'Provider Priority';

	/// en: 'Reorder providers to prioritize where we fetch lyrics from first. Drag below "DISABLED AREA" to disable.'
	String get sectionDescription => 'Reorder providers to prioritize where we fetch lyrics from first. Drag below "DISABLED AREA" to disable.';

	/// en: 'Lyrics Cache'
	String get lyricsCacheTitle => 'Lyrics Cache';

	/// en: 'Always prioritized if enabled'
	String get lyricsCacheSubtitle => 'Always prioritized if enabled';

	/// en: 'DISABLED AREA'
	String get disabledArea => 'DISABLED AREA';

	/// en: 'Priority updated'
	String get updated => 'Priority updated';

	/// en: 'Cache enabled'
	String get cacheEnabled => 'Cache enabled';

	/// en: 'Cache disabled'
	String get cacheDisabled => 'Cache disabled';

	late final Translations$settings$priority$providers$en providers = Translations$settings$priority$providers$en.internal(_root);
}

// Path: settings.misc
class Translations$settings$misc$en {
	Translations$settings$misc$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Misc'
	String get sectionTitle => 'Misc';

	/// en: 'Miscellaneous options.'
	String get sectionDescription => 'Miscellaneous options.';

	/// en: 'System Tray Icon'
	String get tray => 'System Tray Icon';

	/// en: 'Show a Fluent Lyrics icon in the system tray with quick show/hide and quit actions. Requires AppIndicator on Linux (libayatana-appindicator).'
	String get traySubtitle => 'Show a Fluent Lyrics icon in the system tray with quick show/hide and quit actions. Requires AppIndicator on Linux (libayatana-appindicator).';

	/// en: 'Hide to Tray on Close'
	String get hideToTray => 'Hide to Tray on Close';

	/// en: 'When you close the main window, hide it to the tray instead of quitting. Lyrics and translations keep fetching in the background; UI rendering pauses while hidden. Use the tray menu to quit.'
	String get hideToTraySubtitle => 'When you close the main window, hide it to the tray instead of quitting. Lyrics and translations keep fetching in the background; UI rendering pauses while hidden. Use the tray menu to quit.';

	/// en: 'There is nothing here on this platform yet — system tray and lyrics streaming are only available on Linux and macOS desktops.'
	String get unsupported => 'There is nothing here on this platform yet — system tray and lyrics streaming are only available on Linux and macOS desktops.';

	/// en: 'Lyrics Stream Output'
	String get streamTitle => 'Lyrics Stream Output';

	/// en: 'Append the currently-sung lyric line to a plain text file as playback advances. The translation file mirrors the lyrics file line-for-line; lines without a translation become empty lines so external tools can index by line number. Useful for OBS, status bars, or `tail -n 1`. Leave a path empty to disable that output — the previous file (if Fluent Lyrics created it) will be removed.'
	String get streamDescription => 'Append the currently-sung lyric line to a plain text file as playback advances. The translation file mirrors the lyrics file line-for-line; lines without a translation become empty lines so external tools can index by line number. Useful for OBS, status bars, or `tail -n 1`. Leave a path empty to disable that output — the previous file (if Fluent Lyrics created it) will be removed.';

	/// en: 'Lyrics file path'
	String get lyricsPathLabel => 'Lyrics file path';

	/// en: 'Translation file path'
	String get translationPathLabel => 'Translation file path';
}

// Path: settings.appBar
class Translations$settings$appBar$en {
	Translations$settings$appBar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Lyrics Configuration'
	String get lyricsConfiguration => 'Lyrics Configuration';
}

// Path: settings.version
class Translations$settings$version$en {
	Translations$settings$version$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Fluent Lyrics {{version}}'
	String label({required Object version}) => 'Fluent Lyrics ${version}';
}

// Path: lyrics.info
class Translations$lyrics$info$en {
	Translations$lyrics$info$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Source: {{value}}'
	String source({required Object value}) => 'Source: ${value}';

	/// en: 'Written by: {{value}}'
	String writtenBy({required Object value}) => 'Written by: ${value}';

	/// en: 'Composer: {{value}}'
	String composer({required Object value}) => 'Composer: ${value}';

	/// en: 'Contributor: {{value}}'
	String contributor({required Object value}) => 'Contributor: ${value}';

	/// en: 'Copyright: {{value}}'
	String copyright({required Object value}) => 'Copyright: ${value}';

	/// en: 'Translation Provider: {{value}}'
	String translationProvider({required Object value}) => 'Translation Provider: ${value}';

	/// en: 'Translation Contributor: {{value}}'
	String translationContributor({required Object value}) => 'Translation Contributor: ${value}';
}

// Path: settings.destinations.priority
class Translations$settings$destinations$priority$en {
	Translations$settings$destinations$priority$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Provider Priority'
	String get title => 'Provider Priority';

	/// en: 'Reorder and enable/disable lyrics providers'
	String get subtitle => 'Reorder and enable/disable lyrics providers';
}

// Path: settings.destinations.display
class Translations$settings$destinations$display$en {
	Translations$settings$destinations$display$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Display'
	String get title => 'Display';

	/// en: 'Font size, blur, background motion, scroll behavior'
	String get subtitle => 'Font size, blur, background motion, scroll behavior';
}

// Path: settings.destinations.translation
class Translations$settings$destinations$translation$en {
	Translations$settings$destinations$translation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Translation'
	String get title => 'Translation';

	/// en: 'Translation targets, LLM config, alignment'
	String get subtitle => 'Translation targets, LLM config, alignment';
}

// Path: settings.destinations.lyricConfiguration
class Translations$settings$destinations$lyricConfiguration$en {
	Translations$settings$destinations$lyricConfiguration$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Lyric Configuration'
	String get title => 'Lyric Configuration';

	/// en: 'Rich sync, offset, metadata trim, Musixmatch token'
	String get subtitle => 'Rich sync, offset, metadata trim, Musixmatch token';
}

// Path: settings.destinations.cache
class Translations$settings$destinations$cache$en {
	Translations$settings$destinations$cache$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cache Management'
	String get title => 'Cache Management';

	/// en: 'Clear lyrics and artwork cache'
	String get subtitle => 'Clear lyrics and artwork cache';
}

// Path: settings.destinations.experimental
class Translations$settings$destinations$experimental$en {
	Translations$settings$destinations$experimental$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Experimental'
	String get title => 'Experimental';

	/// en: 'Unstable features and fixes'
	String get subtitle => 'Unstable features and fixes';
}

// Path: settings.destinations.misc
class Translations$settings$destinations$misc$en {
	Translations$settings$destinations$misc$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Misc'
	String get title => 'Misc';

	/// en: 'System tray and other miscellaneous options'
	String get subtitle => 'System tray and other miscellaneous options';
}

// Path: settings.priority.providers
class Translations$settings$priority$providers$en {
	Translations$settings$priority$providers$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'LRCLIB'
	String get lrclibName => 'LRCLIB';

	/// en: 'Open-source lyrics database'
	String get lrclibDescription => 'Open-source lyrics database';

	/// en: 'Musixmatch'
	String get musixmatchName => 'Musixmatch';

	/// en: 'World's largest lyrics catalog'
	String get musixmatchDescription => 'World\'s largest lyrics catalog';

	/// en: 'Netease Music'
	String get neteaseName => 'Netease Music';

	/// en: 'Chinese music service, community driven lyrics catalog'
	String get neteaseDescription => 'Chinese music service, community driven lyrics catalog';

	/// en: 'QQ Music'
	String get qqmusicName => 'QQ Music';

	/// en: 'Chinese music streaming service by Tencent'
	String get qqmusicDescription => 'Chinese music streaming service by Tencent';

	/// en: 'LLM Translation'
	String get llmName => 'LLM Translation';

	/// en: 'OpenAI compatible LLM API'
	String get llmDescription => 'OpenAI compatible LLM API';

	/// en: 'Cache'
	String get cacheName => 'Cache';

	/// en: 'Cached lyrics'
	String get cacheDescription => 'Cached lyrics';
}
