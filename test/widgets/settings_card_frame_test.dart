import 'package:fluent_lyrics/widgets/settings_card_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('list tile ink is not hidden by the card fill', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsCardFrame(
            padding: EdgeInsets.zero,
            child: ListTile(title: const Text('Cache'), onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.byType(ListTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch list tile ink is not hidden by the card fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsCardFrame(
            padding: EdgeInsets.zero,
            color: Colors.white.withValues(alpha: 0.045),
            borderColor: Colors.white.withValues(alpha: 0.08),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 4,
              ),
              title: const Text('Include configuration'),
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
