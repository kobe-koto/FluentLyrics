import 'package:flutter/material.dart';
import '../i18n/strings.g.dart';

enum LyricProviderType { lrclib, musixmatch, netease, qqmusic, cache, llm }

LyricProviderType? lyricProviderTypeFromName(String? name) {
  if (name == null) return null;
  for (final provider in LyricProviderType.values) {
    if (provider.name == name) return provider;
  }
  return null;
}

LyricProviderType? lyricProviderTypeFromSource(String? source) {
  final normalized = source
      ?.replaceAll(RegExp(r'\s+\(cached\)$'), '')
      .trim()
      .toLowerCase();
  return switch (normalized) {
    'lrclib' => LyricProviderType.lrclib,
    'musixmatch' => LyricProviderType.musixmatch,
    'netease music' => LyricProviderType.netease,
    'qq music' => LyricProviderType.qqmusic,
    'cache' => LyricProviderType.cache,
    'llm translation' => LyricProviderType.llm,
    _ => null,
  };
}

extension LyricProviderTypeMetadata on LyricProviderType {
  Map<String, dynamic> get metadata {
    switch (this) {
      case LyricProviderType.lrclib:
        return {
          'color': Colors.blue,
          'name': 'LRCLIB',
          'description': 'Open-source lyrics database',
        };
      case LyricProviderType.musixmatch:
        return {
          'color': Colors.orange,
          'name': 'Musixmatch',
          'description': 'World\'s largest lyrics catalog',
        };
      case LyricProviderType.netease:
        return {
          'color': Colors.red,
          'name': 'Netease Music',
          'description':
              'Chinese music service, community driven lyrics catalog',
        };
      case LyricProviderType.qqmusic:
        return {
          'color': Colors.green,
          'name': 'QQ Music',
          'description': 'Chinese music streaming service by Tencent',
        };
      case LyricProviderType.llm:
        return {
          'color': Colors.purple,
          'name': 'LLM Translation',
          'description': 'OpenAI compatible LLM API',
        };
      case LyricProviderType.cache:
        return {
          'color': Colors.grey,
          'name': 'Cache',
          'description': 'Cached lyrics',
        };
    }
  }

  /// Localized display name for the provider. Brand names (LRCLIB,
  /// Musixmatch) stay constant across locales; generic names (Cache,
  /// LLM Translation, Netease Music, QQ Music) are translated.
  String localizedName(Translations i18n) {
    final p = i18n.settings.priority.providers;
    switch (this) {
      case LyricProviderType.lrclib:
        return p.lrclibName;
      case LyricProviderType.musixmatch:
        return p.musixmatchName;
      case LyricProviderType.netease:
        return p.neteaseName;
      case LyricProviderType.qqmusic:
        return p.qqmusicName;
      case LyricProviderType.llm:
        return p.llmName;
      case LyricProviderType.cache:
        return p.cacheName;
    }
  }

  /// Localized one-line description of the provider.
  String localizedDescription(Translations i18n) {
    final p = i18n.settings.priority.providers;
    switch (this) {
      case LyricProviderType.lrclib:
        return p.lrclibDescription;
      case LyricProviderType.musixmatch:
        return p.musixmatchDescription;
      case LyricProviderType.netease:
        return p.neteaseDescription;
      case LyricProviderType.qqmusic:
        return p.qqmusicDescription;
      case LyricProviderType.llm:
        return p.llmDescription;
      case LyricProviderType.cache:
        return p.cacheDescription;
    }
  }
}
