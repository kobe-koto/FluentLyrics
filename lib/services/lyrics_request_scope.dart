import 'package:http/http.dart' as http;

import '../models/lyric_model.dart';

/// Thrown when a fetch is abandoned before the next HTTP call starts.
class LyricsRequestCancelled implements Exception {
  const LyricsRequestCancelled();
}

/// One lyrics or translation fetch. Closing it aborts that fetch's HTTP calls.
class LyricsRequestScope {
  LyricsRequestScope({http.Client? client}) : client = client ?? http.Client();

  final http.Client client;
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    client.close();
  }
}

bool isLyricsRequestCancelled(LyricsRequestScope? scope, [Object? error]) {
  return scope?.isCancelled == true || error is LyricsRequestCancelled;
}

/// A cancelled fetch is an empty result, never a selectable failure.
LyricsResult failureUnlessCancelled(
  Object error, {
  required LyricsRequestScope? scope,
  required String source,
  bool translation = false,
  String? translationProvider,
}) {
  if (isLyricsRequestCancelled(scope, error)) return LyricsResult.empty();
  return LyricsResult.failure(
    source: source,
    message: error.toString(),
    translation: translation,
    translationProvider: translationProvider,
  );
}

Future<http.Response> scopedGet(
  Uri uri, {
  LyricsRequestScope? scope,
  Map<String, String>? headers,
}) {
  if (scope?.isCancelled == true) throw const LyricsRequestCancelled();
  if (scope == null) return http.get(uri, headers: headers);
  return scope.client.get(uri, headers: headers);
}

Future<http.Response> scopedPost(
  Uri uri, {
  LyricsRequestScope? scope,
  Map<String, String>? headers,
  Object? body,
}) {
  if (scope?.isCancelled == true) throw const LyricsRequestCancelled();
  if (scope == null) return http.post(uri, headers: headers, body: body);
  return scope.client.post(uri, headers: headers, body: body);
}
