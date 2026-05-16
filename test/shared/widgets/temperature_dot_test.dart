import 'package:aurganize_lyf/domain/enums/temperature.dart';
import 'package:aurganize_lyf/shared/widgets/temperature_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.white,
    body: Center(child: child),
  ),
);

void main() {
  testWidgets('renders hot/warm/cool with correct semantics labels',
          (WidgetTester tester) async {
        for (final Temperature t in Temperature.values) {
          await tester.pumpWidget(_wrap(TemperatureDot(temperature: t)));
          expect(
            find.bySemanticsLabel('${t.name} temperature'),
            findsOneWidget,
            reason: 'semantics label for ${t.name}',
          );
        }
      });

  testWidgets('default size is 7 logical pixels', (WidgetTester tester) async {
    await tester
        .pumpWidget(_wrap(const TemperatureDot(temperature: Temperature.hot)));
    final Size size = tester.getSize(find.byType(TemperatureDot));
    expect(size, const Size(7, 7));
  });

  testWidgets('golden — hot', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(const Padding(
      padding: EdgeInsets.all(40),
      child: TemperatureDot(temperature: Temperature.hot, size: 32),
    )));
    await expectLater(
      find.byType(TemperatureDot),
      matchesGoldenFile('goldens/temperature_dot_hot.png'),
    );
  });
}