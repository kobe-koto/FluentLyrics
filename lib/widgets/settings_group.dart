import 'package:flutter/material.dart';

/// Where a card sits inside a [SettingsGroup].
enum SettingsGroupPosition {
  only,
  first,
  middle,
  last;

  static SettingsGroupPosition at(int index, int count) {
    if (count <= 1) return SettingsGroupPosition.only;
    if (index <= 0) return SettingsGroupPosition.first;
    if (index >= count - 1) return SettingsGroupPosition.last;
    return SettingsGroupPosition.middle;
  }
}

/// Material 3 segmented-list shape for settings cards.
///
/// The first card's top corners and the last card's bottom corners use
/// [outerRadius] (large, 16). Every other corner in the group uses
/// [innerRadius] (extra small, 4), so those outer corners stay larger than
/// every radius on the remaining cards. A 2px gap keeps the inner corners
/// visible without the old 16–24px stack.
class SettingsGroupMetrics {
  static const double outerRadius = 16;
  static const double innerRadius = 6;
  static const double gap = 6;

  static const EdgeInsets groupedPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  static BorderRadius radiusFor(SettingsGroupPosition? position) {
    final outer = Radius.circular(outerRadius);
    final inner = Radius.circular(innerRadius);
    return switch (position) {
      null || SettingsGroupPosition.only => BorderRadius.all(outer),
      SettingsGroupPosition.first => BorderRadius.vertical(
        top: outer,
        bottom: inner,
      ),
      SettingsGroupPosition.middle => BorderRadius.all(inner),
      SettingsGroupPosition.last => BorderRadius.vertical(
        top: inner,
        bottom: outer,
      ),
    };
  }
}

/// Tells a descendant [SettingsCardFrame] which grouped radius to use.
class SettingsGroupScope extends InheritedWidget {
  const SettingsGroupScope({
    super.key,
    required this.position,
    required super.child,
  });

  final SettingsGroupPosition position;

  static SettingsGroupPosition? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SettingsGroupScope>()
        ?.position;
  }

  @override
  bool updateShouldNotify(SettingsGroupScope oldWidget) {
    return position != oldWidget.position;
  }
}

/// Packs settings cards into one segmented group.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.children,
    this.gap = SettingsGroupMetrics.gap,
  });

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: gap),
          SettingsGroupScope(
            position: SettingsGroupPosition.at(index, children.length),
            child: children[index],
          ),
        ],
      ],
    );
  }
}
