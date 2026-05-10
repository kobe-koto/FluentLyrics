import 'package:flutter/material.dart';

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
}
