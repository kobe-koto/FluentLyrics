import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';
import '../../../providers/lyrics_provider.dart';

class PermissionOverlay extends StatelessWidget {
  final LyricsProvider provider;

  const PermissionOverlay({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.androidPermissionGranted) return const SizedBox.shrink();

    final i18n = t.permission;
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: Colors.white, size: 64),
            const SizedBox(height: 24),
            Text(
              i18n.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              i18n.description,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => provider.requestAndroidPermission(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(i18n.grantAccess),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => provider.checkAndroidPermission(),
              child: Text(
                i18n.alreadyGranted,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
