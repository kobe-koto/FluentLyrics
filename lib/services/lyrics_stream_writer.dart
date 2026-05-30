import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/lyric_model.dart';
import '../providers/lyrics_provider.dart';
import '../utils/app_logger.dart';

/// Streams the currently-sung lyric line (and its translation) to one or two
/// plain text files so external tools (OBS, status bars, `tail -n 1`, etc.)
/// can consume them.
///
/// Behaviour:
/// - Lyrics file line N corresponds 1:1 to translation file line N. A lyric
///   line without a translation produces an empty translation line so line
///   numbers stay aligned.
/// - When [LyricsProvider]'s `currentIndex` advances, the new line is
///   appended to whichever files are configured.
/// - When the underlying `lyrics` list changes (new song / candidate switch)
///   or `currentIndex` rewinds (user seeks backwards), both files are
///   rewritten from the start up to the current line.
/// - Disabled (and the existing file untouched) when the corresponding path
///   setting is empty.
class LyricsStreamWriter {
  LyricsStreamWriter({required this.provider});

  final LyricsProvider provider;

  /// Identity of the `lyrics` list last reflected on disk; used to detect
  /// when the song / candidate changed.
  List<Lyric>? _lastLyricsRef;
  int _lastWrittenIndex = -1;

  /// Paths last observed; tracked so we can detect setting changes without
  /// querying the provider each tick.
  String _lastLyricsPath = '';
  String _lastTranslationPath = '';

  /// Paths the writer itself has materialised on disk. Only files we wrote
  /// are eligible for deletion when the path changes / clears; we never
  /// delete a path the writer has not first written to.
  final Set<String> _ownedFiles = <String>{};

  /// Serializes all file IO so two notify ticks cannot interleave a rewrite
  /// with an append.
  Future<void> _ioChain = Future.value();

  bool _started = false;

  /// Subscribe to [provider] and begin syncing. Safe to call once.
  void start() {
    if (_started) return;
    _started = true;
    _lastLyricsPath = provider.lyricsStreamPath.current;
    _lastTranslationPath = provider.translationStreamPath.current;
    provider.addListener(_onProviderChanged);
    // Kick a first pass in case lyrics already loaded before we attached.
    _onProviderChanged();
  }

  /// Stop syncing. Pending IO is awaited before returning.
  Future<void> dispose() async {
    if (!_started) return;
    provider.removeListener(_onProviderChanged);
    _started = false;
    await _ioChain;
  }

  void _onProviderChanged() {
    final lyricsPath = provider.lyricsStreamPath.current;
    final translationPath = provider.translationStreamPath.current;
    final lyrics = provider.lyrics;
    final currentIndex = provider.currentIndex;

    final lyricsPathChanged = lyricsPath != _lastLyricsPath;
    final translationPathChanged = translationPath != _lastTranslationPath;

    // When a path changes (including being cleared), delete the previous
    // file if we were the ones who created it. We never delete a path the
    // writer did not materialise — that would risk wiping user data.
    if (lyricsPathChanged && _lastLyricsPath.isNotEmpty) {
      _enqueueDeleteIfOwned(_lastLyricsPath);
    }
    if (translationPathChanged && _lastTranslationPath.isNotEmpty) {
      _enqueueDeleteIfOwned(_lastTranslationPath);
    }

    _lastLyricsPath = lyricsPath;
    _lastTranslationPath = translationPath;

    // Both off → nothing left to do beyond the deletions above.
    if (lyricsPath.isEmpty && translationPath.isEmpty) {
      _lastLyricsRef = lyrics;
      _lastWrittenIndex = -1;
      return;
    }

    final pathsChanged = lyricsPathChanged || translationPathChanged;
    final lyricsChanged = !identical(lyrics, _lastLyricsRef);
    final indexRewound = currentIndex < _lastWrittenIndex;

    // Rewrite case: paths just changed, song/candidate changed, or user
    // seeked backwards. All collapse to "truncate and rewrite [0..idx]".
    if (pathsChanged || lyricsChanged || indexRewound) {
      _lastLyricsRef = lyrics;
      _lastWrittenIndex = -1; // forget previous progress
      _enqueueRewrite(
        lyricsPath: lyricsPath,
        translationPath: translationPath,
        lyrics: lyrics,
        upToIndex: currentIndex,
      );
      _lastWrittenIndex = currentIndex;
      return;
    }

    if (currentIndex > _lastWrittenIndex) {
      final from = _lastWrittenIndex + 1;
      final to = currentIndex;
      _lastWrittenIndex = currentIndex;
      _enqueueAppend(
        lyricsPath: lyricsPath,
        translationPath: translationPath,
        lyrics: lyrics,
        fromIndex: from,
        toIndex: to,
      );
    }
  }

  void _enqueueRewrite({
    required String lyricsPath,
    required String translationPath,
    required List<Lyric> lyrics,
    required int upToIndex,
  }) {
    _ioChain = _ioChain.then((_) async {
      // Collect lines [0..upToIndex] (inclusive). When upToIndex < 0
      // (no current line yet) we still want both files emptied.
      final end = upToIndex < 0
          ? -1
          : (upToIndex >= lyrics.length ? lyrics.length - 1 : upToIndex);
      final lyricsBuf = StringBuffer();
      final translationBuf = StringBuffer();
      for (var i = 0; i <= end; i++) {
        final line = lyrics[i];
        lyricsBuf.writeln(line.text);
        translationBuf.writeln(line.translation ?? '');
      }
      await _writeFull(lyricsPath, lyricsBuf.toString());
      await _writeFull(translationPath, translationBuf.toString());
    });
  }

  void _enqueueAppend({
    required String lyricsPath,
    required String translationPath,
    required List<Lyric> lyrics,
    required int fromIndex,
    required int toIndex,
  }) {
    _ioChain = _ioChain.then((_) async {
      if (fromIndex < 0 || fromIndex >= lyrics.length) return;
      final end = toIndex >= lyrics.length ? lyrics.length - 1 : toIndex;
      if (end < fromIndex) return;
      final lyricsBuf = StringBuffer();
      final translationBuf = StringBuffer();
      for (var i = fromIndex; i <= end; i++) {
        final line = lyrics[i];
        lyricsBuf.writeln(line.text);
        translationBuf.writeln(line.translation ?? '');
      }
      await _appendChunk(lyricsPath, lyricsBuf.toString());
      await _appendChunk(translationPath, translationBuf.toString());
    });
  }

  void _enqueueDeleteIfOwned(String path) {
    if (path.isEmpty) return;
    if (!_ownedFiles.contains(path)) return;
    _ownedFiles.remove(path);
    _ioChain = _ioChain.then((_) async {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e, st) {
        AppLogger.debug('LyricsStreamWriter: failed to delete $path: $e\n$st');
      }
    });
  }

  Future<void> _writeFull(String path, String content) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (!await _ensureParent(file)) return;
      await file.writeAsString(content, flush: true, encoding: utf8);
      _ownedFiles.add(path);
    } catch (e, st) {
      AppLogger.debug('LyricsStreamWriter._writeFull($path) failed: $e\n$st');
    }
  }

  Future<void> _appendChunk(String path, String content) async {
    if (path.isEmpty || content.isEmpty) return;
    try {
      final file = File(path);
      if (!await _ensureParent(file)) return;
      // Create the file on first append if a rewrite hasn't happened yet
      // (e.g. user enabled the path mid-song with no prior rewrite trigger
      // because we treat path change as a rewrite — this branch is the
      // safety net).
      await file.writeAsString(
        content,
        mode: FileMode.append,
        flush: true,
        encoding: utf8,
      );
      _ownedFiles.add(path);
    } catch (e, st) {
      AppLogger.debug('LyricsStreamWriter._appendChunk($path) failed: $e\n$st');
    }
  }

  /// Ensure the parent directory of [file] exists, creating it (and any
  /// missing ancestors) when needed. Returns `false` if creation failed so
  /// the caller can skip the write rather than throw.
  Future<bool> _ensureParent(File file) async {
    final parent = file.parent;
    if (await parent.exists()) return true;
    try {
      await parent.create(recursive: true);
      return true;
    } catch (e, st) {
      AppLogger.debug(
        'LyricsStreamWriter: failed to create parent ${parent.path}: $e\n$st',
      );
      return false;
    }
  }
}
