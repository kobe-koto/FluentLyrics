import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../providers/appearance_controller.dart';
import '../theme/app_theme.dart';
import '../theme/settings_colors.dart';

/// Reusable scaffold for all settings sub-screens.
/// Applies the settings theme from [AppearanceScope], a solid background, app bar with back button, and
/// keyboard (Escape) / mouse-back-button navigation.
class SettingsScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const SettingsScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors =
        AppearanceScope.maybeOf(context)
            ?.resolve(MediaQuery.platformBrightnessOf(context)) ??
        SettingsColors.dark;
    return AnimatedTheme(
      data: buildSettingsTheme(colors),
      duration: const Duration(milliseconds: 200),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: colors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Builder(
      builder: (context) {
        final colors = context.settingsColors;
        return Listener(
          onPointerDown: (PointerDownEvent event) {
            if (event.buttons == kBackMouseButton) {
              Navigator.pop(context);
            }
          },
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  Navigator.pop(context),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: colors.background,
                body: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: colors.onSurface,
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
