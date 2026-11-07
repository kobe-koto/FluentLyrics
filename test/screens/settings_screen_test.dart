import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/screens/settings_screen.dart';
import 'package:fluent_lyrics/widgets/settings_card_frame.dart';
import 'package:fluent_lyrics/widgets/settings_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wide layout accent bar stays inside the destination card', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    LocaleSettings.setLocaleSync(AppLocale.en);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    _expectAccentBarInsideCard(tester);
    expect(tester.takeException(), isNull);
  });
}

void _expectAccentBarInsideCard(WidgetTester tester) {
  final bar = find.byKey(const ValueKey('bar'));
  expect(bar, findsOneWidget);

  final card = find.ancestor(of: bar, matching: find.byType(SettingsCardFrame));
  final barRect = tester.getRect(bar);
  final cardRect = tester.getRect(card);
  expect(cardRect.height, lessThan(160));
  expect(barRect.left, greaterThanOrEqualTo(cardRect.left));
  expect(barRect.top, greaterThanOrEqualTo(cardRect.top));
  expect(barRect.right, lessThanOrEqualTo(cardRect.right));
  expect(barRect.bottom, lessThanOrEqualTo(cardRect.bottom));

  final clip = tester.widget<Material>(
    find.descendant(of: card, matching: find.byType(Material)).first,
  );
  expect(
    clip.borderRadius,
    SettingsGroupMetrics.radiusFor(SettingsGroupPosition.first),
  );
  expect(clip.clipBehavior, isNot(Clip.none));
}
