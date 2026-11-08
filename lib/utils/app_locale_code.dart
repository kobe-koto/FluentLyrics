import '../i18n/strings.g.dart';

/// Code saved in the `app_locale` preference and shown on the language page.
/// Chinese uses the script (Hans / Hant) rather than a region.
String appLocaleCode(AppLocale locale) {
  return switch (locale) {
    AppLocale.en => 'en',
    AppLocale.zhCn => 'zh_Hans',
    AppLocale.zhTw => 'zh_Hant',
  };
}

/// Locale for a saved [code], or null when it matches none.
AppLocale? appLocaleFromCode(String? code) {
  for (final locale in AppLocale.values) {
    if (appLocaleCode(locale) == code) return locale;
  }
  return null;
}
