import 'package:fluent_lyrics/widgets/settings_card_frame.dart';
import 'package:fluent_lyrics/widgets/settings_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('grouped cards use a larger outer radius than inner cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsGroup(
            children: [
              SettingsCardFrame(child: SizedBox(key: Key('first'), height: 40)),
              SettingsCardFrame(
                child: SizedBox(key: Key('middle'), height: 40),
              ),
              SettingsCardFrame(child: SizedBox(key: Key('last'), height: 40)),
            ],
          ),
        ),
      ),
    );

    final first = _radiusOf(tester, 'first');
    final middle = _radiusOf(tester, 'middle');
    final last = _radiusOf(tester, 'last');

    expect(first.topLeft.x, SettingsGroupMetrics.outerRadius);
    expect(first.topRight.x, SettingsGroupMetrics.outerRadius);
    expect(last.bottomLeft.x, SettingsGroupMetrics.outerRadius);
    expect(last.bottomRight.x, SettingsGroupMetrics.outerRadius);

    for (final radius in _corners(middle)) {
      expect(first.topLeft.x, greaterThan(radius));
      expect(last.bottomLeft.x, greaterThan(radius));
    }
    expect(first.bottomLeft.x, SettingsGroupMetrics.innerRadius);
    expect(last.topLeft.x, SettingsGroupMetrics.innerRadius);

    final firstRect = tester.getRect(_card(tester, 'first'));
    final middleRect = tester.getRect(_card(tester, 'middle'));
    expect(middleRect.top - firstRect.bottom, SettingsGroupMetrics.gap);
  });

  testWidgets('a single grouped card keeps the large radius', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsGroup(
            children: [
              SettingsCardFrame(child: SizedBox(key: Key('only'), height: 40)),
            ],
          ),
        ),
      ),
    );

    final radius = _radiusOf(tester, 'only');
    expect(_corners(radius), everyElement(SettingsGroupMetrics.outerRadius));
  });

  testWidgets('ungrouped cards stay fully rounded', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsCardFrame(
            child: SizedBox(key: Key('solo'), height: 40),
          ),
        ),
      ),
    );

    final radius = _radiusOf(tester, 'solo');
    expect(_corners(radius), everyElement(SettingsGroupMetrics.outerRadius));
  });
}

Finder _card(WidgetTester tester, String key) {
  return find.ancestor(
    of: find.byKey(Key(key)),
    matching: find.byType(SettingsCardFrame),
  );
}

BorderRadius _radiusOf(WidgetTester tester, String key) {
  final card = _card(tester, key);
  final container = tester.widget<Container>(
    find.descendant(of: card, matching: find.byType(Container)).first,
  );
  return (container.decoration! as BoxDecoration).borderRadius! as BorderRadius;
}

List<double> _corners(BorderRadius radius) {
  return [
    radius.topLeft.x,
    radius.topRight.x,
    radius.bottomLeft.x,
    radius.bottomRight.x,
  ];
}
