import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';
import '../../../models/lyric_provider_type.dart';
import '../../settings_card_frame.dart';
import '../../settings_group.dart';
import '../../settings_section.dart';
import 'musixmatch_token_card.dart';

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
          onReorderItem: (oldIndex, newIndex) {
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
        const SizedBox(height: 16),
        const MusixmatchTokenCard(),
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
    final segmentStart = isEnabled ? 0 : enabledCount;
    final segmentCount = isEnabled
        ? enabledCount
        : allProviders.length - enabledCount;
    final position = SettingsGroupPosition.at(
      index - segmentStart,
      segmentCount,
    );
    final isSegmentEnd =
        position == SettingsGroupPosition.only ||
        position == SettingsGroupPosition.last;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      key: ValueKey(type),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isSegmentEnd ? 0 : SettingsGroupMetrics.gap,
        ),
        child: SettingsGroupScope(
          position: position,
          child: _ProviderPriorityCard(
            type: type,
            index: index,
            enabledCount: enabledCount,
            isEnabled: isEnabled,
          ),
        ),
      ),
    );
  }
}

class _ProviderPriorityCard extends StatefulWidget {
  const _ProviderPriorityCard({
    required this.type,
    required this.index,
    required this.enabledCount,
    required this.isEnabled,
  });

  final LyricProviderType type;
  final int index;
  final int enabledCount;
  final bool isEnabled;

  @override
  State<_ProviderPriorityCard> createState() => _ProviderPriorityCardState();
}

class _ProviderPriorityCardState extends State<_ProviderPriorityCard> {
  final GlobalKey _boundsKey = GlobalKey();
  final GlobalKey _iconKey = GlobalKey();
  double _dragWidth = 0;
  bool _measureScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant _ProviderPriorityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      _measureDragWidth();
    });
  }

  void _measureDragWidth() {
    if (!mounted) return;
    final bounds = _boundsKey.currentContext?.findRenderObject() as RenderBox?;
    final icon = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (bounds == null ||
        icon == null ||
        !bounds.hasSize ||
        !icon.hasSize ||
        !bounds.attached ||
        !icon.attached) {
      return;
    }
    final iconCenter = icon.localToGlobal(
      icon.size.center(Offset.zero),
      ancestor: bounds,
    );
    final width = 2 * (bounds.size.width - iconCenter.dx);
    final next = width.isFinite && width > 0 ? width : 0.0;
    if ((next - _dragWidth).abs() < 0.5) return;
    setState(() => _dragWidth = next);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    final metadata = widget.type.metadata;
    final Color color = metadata['color'];
    final name = widget.type.localizedName(t);
    final description = widget.type.localizedDescription(t);
    final reorderIndex =
        widget.index + (widget.index >= widget.enabledCount ? 1 : 0);

    return Stack(
      key: _boundsKey,
      clipBehavior: Clip.none,
      children: [
        SettingsCardFrame(
          padding: EdgeInsets.zero,
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
                child: widget.isEnabled
                    ? Text(
                        (widget.index + 1).toString(),
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
            trailing: Icon(
              Icons.drag_indicator,
              key: _iconKey,
              color: Colors.white24,
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: _dragWidth,
          child: ReorderableDragStartListener(
            index: reorderIndex,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}
