import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import '../../widgets/settings_scaffold.dart';
import '../../widgets/screen/settings/cache_section.dart';

class CacheScreen extends StatelessWidget {
  const CacheScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: t.settings.destinations.cache.title,
      child: const CacheSettingsContent(),
    );
  }
}

class CacheSettingsContent extends StatelessWidget {
  const CacheSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: CacheSection(
        onRefresh: () {},
        showSnackBar: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: Colors.white24,
            ),
          );
        },
      ),
    );
  }
}
