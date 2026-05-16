import 'package:aurganize_lyf/shared/widgets/day_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: child),
  ),
);

void main() {
  testWidgets('default size is 40x52', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(DayTile(
      weekdayLabel: 'TUE',
      dayOfMonth: 16,
      state: DayTileState.defaultState,
      fullDateForA11y: 'Tuesday, May 16, 2026',
      onTap: () {},
    )));
    expect(tester.getSize(find.byType(DayTile)), const Size(40, 52));
  });

  testWidgets('semantics label includes full date and total count',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrap(DayTile(
          weekdayLabel: 'TUE',
          dayOfMonth: 16,
          state: DayTileState.focused,
          pill: const DayTilePill.total(count: 4),
          fullDateForA11y: 'Tuesday, May 16, 2026',
          onTap: () {},
        )));
        expect(
          find.bySemanticsLabel(
            'Tuesday, May 16, 2026, 4 items today, currently selected',
          ),
          findsOneWidget,
        );
      });

  testWidgets('semantics label includes leftover information',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrap(DayTile(
          weekdayLabel: 'MON',
          dayOfMonth: 15,
          state: DayTileState.defaultState,
          pill: const DayTilePill.leftover(count: 1, olderThanYesterday: false),
          fullDateForA11y: 'Monday, May 15, 2026',
          onTap: () {},
        )));
        expect(
          find.bySemanticsLabel(
            'Monday, May 15, 2026, 1 leftover item from yesterday',
          ),
          findsOneWidget,
        );
      });

  testWidgets('tap fires onTap', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(_wrap(DayTile(
      weekdayLabel: 'WED',
      dayOfMonth: 17,
      state: DayTileState.defaultState,
      fullDateForA11y: 'Wednesday, May 17, 2026',
      onTap: () => taps++,
    )));
    await tester.tap(find.byType(DayTile));
    expect(taps, 1);
  });

  testWidgets('golden — focused with total pill', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(DayTile(
      weekdayLabel: 'TUE',
      dayOfMonth: 16,
      state: DayTileState.focused,
      pill: const DayTilePill.total(count: 4),
      fullDateForA11y: 'Tuesday, May 16, 2026',
      onTap: () {},
    )));
    await expectLater(
      find.byType(DayTile),
      matchesGoldenFile('goldens/day_tile_focused.png'),
    );
  });

  testWidgets('golden — default no pill', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(DayTile(
      weekdayLabel: 'WED',
      dayOfMonth: 17,
      state: DayTileState.defaultState,
      fullDateForA11y: 'Wednesday, May 17, 2026',
      onTap: () {},
    )));
    await expectLater(
      find.byType(DayTile),
      matchesGoldenFile('goldens/day_tile_default.png'),
    );
  });

  testWidgets('golden — leftover amber pill', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(DayTile(
      weekdayLabel: 'MON',
      dayOfMonth: 15,
      state: DayTileState.defaultState,
      pill: const DayTilePill.leftover(count: 2, olderThanYesterday: false),
      fullDateForA11y: 'Monday, May 15, 2026',
      onTap: () {},
    )));
    await expectLater(
      find.byType(DayTile),
      matchesGoldenFile('goldens/day_tile_leftover_amber.png'),
    );
  });
}