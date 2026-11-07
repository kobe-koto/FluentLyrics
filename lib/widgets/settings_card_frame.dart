import 'package:flutter/material.dart';

import 'settings_group.dart';
import '../theme/settings_colors.dart';

class SettingsCardFrame extends StatelessWidget {
  static const defaultPadding = EdgeInsets.all(20);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const SettingsCardFrame({
    super.key,
    required this.child,
    this.padding = defaultPadding,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final position = SettingsGroupScope.maybeOf(context);
    final radius = SettingsGroupMetrics.radiusFor(position);
    final resolvedPadding = position != null && padding == defaultPadding
        ? SettingsGroupMetrics.groupedPadding
        : padding;
    return Container(
      decoration: BoxDecoration(
        color: color ?? context.settingsColors.card,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? context.settingsColors.cardBorder,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}
