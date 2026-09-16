import 'package:flutter/material.dart';
import '../i18n/strings.g.dart';
import 'settings_card_frame.dart';

/// Settings card with a title, subtitle and a value picked from [options].
class SettingsDropdownCard<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final List<SettingsDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final VoidCallback? onReset;
  final String? resetTooltip;

  const SettingsDropdownCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
    this.onReset,
    this.resetTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onReset != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: onReset,
                  tooltip: resetTooltip ?? t.common.reset,
                  style: IconButton.styleFrom(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(20, 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E1E),
            underline: Container(height: 1, color: Colors.white12),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            items: [
              for (final option in options)
                DropdownMenuItem<T>(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class SettingsDropdownOption<T> {
  final T value;
  final String label;

  const SettingsDropdownOption({required this.value, required this.label});
}
