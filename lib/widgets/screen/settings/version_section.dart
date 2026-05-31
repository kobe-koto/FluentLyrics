import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../i18n/strings.g.dart';
import '../../../utils/version_display_helper.dart';

class VersionSection extends StatelessWidget {
  final String version;

  const VersionSection({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final versionDisplay = VersionDisplayHelper.formatVersionLabel(
      version: version,
      isDebugMode: kDebugMode,
      isProfileMode: kProfileMode,
    );
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          t.settings.version.label(version: versionDisplay),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
