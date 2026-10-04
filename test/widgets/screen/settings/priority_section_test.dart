import 'package:fluent_lyrics/i18n/strings.g.dart';
import 'package:fluent_lyrics/models/lyric_provider_type.dart';
import 'package:fluent_lyrics/widgets/screen/settings/priority_section.dart';
import 'package:fluent_lyrics/widgets/settings_card_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const providers = <LyricProviderType>[
    LyricProviderType.musixmatch,
    LyricProviderType.netease,
    LyricProviderType.qqmusic,
  ];

  testWidgets('drag handle is centered on the icon and flush with the card', (
    tester,
  ) async {
    await _pumpPriority(tester, providers: providers, enabledCount: 2);

    _expectDragHandle(tester, LyricProviderType.musixmatch, reorderIndex: 0);
    _expectDragHandle(tester, LyricProviderType.qqmusic, reorderIndex: 3);
  });

  testWidgets('only the icon-centered handle starts a reorder', (tester) async {
    var reorders = 0;
    await _pumpPriority(
      tester,
      providers: providers,
      enabledCount: 2,
      onReorder: (_, _) => reorders++,
    );

    await tester.drag(find.text('Musixmatch'), const Offset(0, 300));
    await tester.pump();
    expect(reorders, 0);

    final handle = _listener(LyricProviderType.musixmatch);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reorders, 1);
  });
}

Future<void> _pumpPriority(
  WidgetTester tester, {
  required List<LyricProviderType> providers,
  required int enabledCount,
  void Function(List<LyricProviderType> providers, int enabledCount)? onReorder,
}) async {
  SharedPreferences.setMockInitialValues({});
  LocaleSettings.setLocaleSync(AppLocale.en);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(900, 1400));

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PrioritySection(
          allProviders: providers,
          enabledCount: enabledCount,
          cacheEnabled: true,
          onReorder: onReorder ?? (_, _) {},
          onCacheToggle: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void _expectDragHandle(
  WidgetTester tester,
  LyricProviderType type, {
  required int reorderIndex,
}) {
  final card = find.descendant(
    of: find.byKey(ValueKey(type)),
    matching: find.byType(SettingsCardFrame),
  );
  final icon = find.descendant(
    of: card,
    matching: find.byIcon(Icons.drag_indicator),
  );
  final listener = _listener(type);
  expect(card, findsOneWidget);
  expect(icon, findsOneWidget);
  expect(listener, findsOneWidget);
  expect(
    tester.widget<ReorderableDragStartListener>(listener).index,
    reorderIndex,
  );

  final cardRect = tester.getRect(card);
  final iconRect = tester.getRect(icon);
  final listenerRect = tester.getRect(listener);

  expect(listenerRect.top, closeTo(cardRect.top, 0.01));
  expect(listenerRect.bottom, closeTo(cardRect.bottom, 0.01));
  expect(listenerRect.right, closeTo(cardRect.right, 0.01));
  expect(listenerRect.left, greaterThanOrEqualTo(cardRect.left));
  expect(listenerRect.center.dx, closeTo(iconRect.center.dx, 0.5));
  expect(listenerRect.center.dy, closeTo(iconRect.center.dy, 0.5));
  expect(listenerRect.width, greaterThan(iconRect.width));
  expect(listenerRect.width, lessThan(cardRect.width / 2));
  expect(listenerRect.contains(iconRect.center), isTrue);
  expect(listenerRect.contains(cardRect.centerLeft), isFalse);
}

Finder _listener(LyricProviderType type) {
  return find.descendant(
    of: find.byKey(ValueKey(type)),
    matching: find.byType(ReorderableDragStartListener),
  );
}
