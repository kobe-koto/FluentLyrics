import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/lyric_provider_type.dart';
import '../../settings_card_frame.dart';
import '../../settings_section.dart';

class PrioritySection extends StatelessWidget {
  final List<LyricProviderType> allProviders;
  final int enabledCount;
  final bool cacheEnabled;
  final Function(List<LyricProviderType> newProviders, int newEnabledCount)
  onReorder;
  final ValueChanged<bool> onCacheToggle;

  const PrioritySection({
    super.key,
    required this.allProviders,
    required this.enabledCount,
    required this.cacheEnabled,
    required this.onReorder,
    required this.onCacheToggle,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> listItems = [];
    for (int i = 0; i < allProviders.length; i++) {
      if (i == enabledCount) {
        listItems.add(
          _buildDisabledHeader(key: const ValueKey('disabled_header')),
        );
      }
      listItems.add(
        _buildProviderCard(allProviders[i], i, isEnabled: i < enabledCount),
      );
    }
    if (enabledCount == allProviders.length) {
      listItems.add(
        _buildDisabledHeader(key: const ValueKey('disabled_header')),
      );
    }

    return SettingsSection(
      title: t.settings.priority.sectionTitle,
      description: t.settings.priority.sectionDescription,
      children: [
        _buildCacheButton(),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            // ReorderableListView indices correspond to the children list
            // Get current visual list to map indices correctly
            final visualList = [];
            for (int i = 0; i < allProviders.length; i++) {
              if (i == enabledCount) visualList.add('HEADER');
              visualList.add(allProviders[i]);
            }
            if (enabledCount == allProviders.length) {
              visualList.add('HEADER');
            }

            final item = visualList.removeAt(oldIndex);
            if (newIndex > oldIndex) newIndex--;
            visualList.insert(newIndex, item);

            // Now reconstruct allProviders and enabledCount from visualList
            final newAllProviders = <LyricProviderType>[];
            int newEnabledCount = 0;
            bool foundHeader = false;
            for (final v in visualList) {
              if (v == 'HEADER') {
                foundHeader = true;
              } else {
                newAllProviders.add(v as LyricProviderType);
                if (!foundHeader) newEnabledCount++;
              }
            }
            onReorder(newAllProviders, newEnabledCount);
          },
          proxyDecorator: (child, index, animation) {
            return Material(color: Colors.transparent, child: child);
          },
          children: listItems,
        ),
      ],
    );
  }

  Widget _buildCacheButton() {
    return SettingsCardFrame(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storage, color: Colors.grey),
        ),
        title: Text(
          t.settings.priority.lyricsCacheTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          t.settings.priority.lyricsCacheSubtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Switch(
          value: cacheEnabled,
          onChanged: onCacheToggle,
          activeThumbColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDisabledHeader({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              const Expanded(child: Divider(color: Colors.white10)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  t.settings.priority.disabledArea,
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Colors.white10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(
    LyricProviderType type,
    int index, {
    bool isEnabled = true,
  }) {
    final metadata = type.metadata;
    final Color color = metadata['color'];
    final String name = type.localizedName(t);
    final String description = type.localizedDescription(t);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      key: ValueKey(type),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: SettingsCardFrame(
          padding: EdgeInsets.zero,
          child: ReorderableDragStartListener(
            index: index + (index >= enabledCount ? 1 : 0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isEnabled
                      ? Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Icon(
                          Icons.block,
                          size: 20,
                          color: color.withValues(alpha: 0.5),
                        ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.drag_indicator, color: Colors.white24),
            ),
          ),
        ),
      ),
    );
  }
}
