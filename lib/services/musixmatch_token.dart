/// Desktop `token.get` can return these instead of a usable user token.
const musixmatchZeroPlaceholder =
    '00000000000000000000000000000000000000000000000000000000';
const musixmatchUpgradeOnlyPlaceholder =
    'UpgradeOnlyUpgradeOnlyUpgradeOnlyUpgradeOnly';

/// True for blank, `"null"`, any all-zero string, and Musixmatch upgrade stubs.
bool musixmatchTokenIsPlaceholder(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.toLowerCase() == 'null') return true;
  if (RegExp(r'^0+$').hasMatch(trimmed)) return true;
  if (trimmed.contains('UpgradeOnly')) return true;
  return false;
}

bool isUsableMusixmatchToken(String? token) {
  if (token == null) return false;
  final trimmed = token.trim();
  if (trimmed.isEmpty) return false;
  return !musixmatchTokenIsPlaceholder(trimmed);
}
