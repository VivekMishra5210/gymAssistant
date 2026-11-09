import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_assistant/app.dart';
import 'package:gym_assistant/core/time/clock.dart';

void main() {
  testWidgets('app starts with title', (tester) async {
    await tester.pumpWidget(const GymApp());
    expect(find.text('Gym Assistant'), findsOneWidget);
  });

  testWidgets('workout screen fits a phone and ticking shows the rest panel',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400); // Redmi Note 13 5G
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final clock = FakeClock(DateTime(2026, 1, 1, 10));
    await tester.pumpWidget(GymApp(clock: clock));
    await tester.tap(find.textContaining('Start Workout'));
    await tester.pumpAndSettle();
    expect(find.text('Lat Pulldown'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).at(0)); // weight +2.5
    await tester.tap(find.byIcon(Icons.add).at(1)); // reps +1
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pump();
    expect(find.text('Skip rest'), findsOneWidget);
    expect(find.text('Next: Set 2 · Lat Pulldown'), findsOneWidget);
    expect(find.text('2:00'), findsOneWidget);

    // Countdown must redraw on the 1 s ticker alone, with no other taps.
    clock.advance(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1:57'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // dispose screen + its ticker
  });

  testWidgets('typing a weight in the dialog updates the set without errors',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(GymApp(clock: FakeClock(DateTime(2026, 1, 1))));
    await tester.tap(find.textContaining('Start Workout'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('– kg').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '62.5');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('62.5 kg'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  test('FakeClock only moves when advanced', () {
    final clock = FakeClock(DateTime(2026, 1, 1, 10));
    expect(clock.now(), DateTime(2026, 1, 1, 10));
    clock.advance(const Duration(seconds: 90));
    expect(clock.now(), DateTime(2026, 1, 1, 10, 1, 30));
  });
}
