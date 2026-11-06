import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';

enum LyricProviderType {
  lrclib,
  musixmatch,
  netease,
  qqmusic,
  kugou,
  youtubeMusic,
  cache,
  llm,
}

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
    'kugou music' => LyricProviderType.kugou,
    'youtube music' => LyricProviderType.youtubeMusic,
    'cache' => LyricProviderType.cache,
    'llm translation' => LyricProviderType.llm,
    _ => null,
  };
}

extension LyricProviderTypeMetadata on LyricProviderType {
  Map<String, dynamic> get metadata {
    switch (this) {
      case LyricProviderType.lrclib:
        return {'color': Colors.blue, 'name': 'LRCLIB'};
      case LyricProviderType.musixmatch:
        return {'color': Colors.orange, 'name': 'Musixmatch'};
      case LyricProviderType.netease:
        return {'color': Colors.red, 'name': 'Netease Music'};
      case LyricProviderType.qqmusic:
        return {'color': Colors.green, 'name': 'QQ Music'};
      case LyricProviderType.kugou:
        return {'color': const Color(0xFF0062FF), 'name': 'Kugou Music'};
      case LyricProviderType.youtubeMusic:
        return {'color': Colors.red, 'name': 'YouTube Music'};
      case LyricProviderType.llm:
        return {'color': Colors.purple, 'name': 'LLM Translation'};
      case LyricProviderType.cache:
        return {'color': Colors.grey, 'name': 'Cache'};
    }
  }

  /// Official website, or null for local / self-configured sources.
  String? get websiteUrl {
    return switch (this) {
      LyricProviderType.lrclib => 'https://lrclib.net/',
      LyricProviderType.musixmatch => 'https://www.musixmatch.com/',
      LyricProviderType.netease => 'https://music.163.com/',
      LyricProviderType.qqmusic => 'https://y.qq.com/',
      LyricProviderType.kugou => 'https://www.kugou.com/',
      LyricProviderType.youtubeMusic => 'https://music.youtube.com/',
      LyricProviderType.cache || LyricProviderType.llm => null,
    };
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
      case LyricProviderType.kugou:
        return p.kugouName;
      case LyricProviderType.youtubeMusic:
        return p.youtubeMusicName;
      case LyricProviderType.llm:
        return p.llmName;
      case LyricProviderType.cache:
        return p.cacheName;
    }
  }
}
