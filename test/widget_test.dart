import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_assistant/core/time/clock.dart';
import 'package:gym_assistant/data/models/plan_exercise.dart';
import 'package:gym_assistant/logic/workout_controller.dart';
import 'package:gym_assistant/ui/workout/workout_screen.dart';
import 'package:provider/provider.dart';

const pull = [
  PlanExercise('Lat Pulldown', 4, 120),
  PlanExercise('Seated Row', 4, 120),
  PlanExercise('Barbell Curl', 4, 90),
  PlanExercise('Hammer Curl', 4, 90),
];

Future<WorkoutController> openScreen(
  WidgetTester tester,
  FakeClock clock,
) async {
  tester.view.physicalSize = const Size(1080, 2400); // Redmi Note 13 5G
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final w = WorkoutController(clock, pull, name: 'Pull');
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider.value(
        value: w,
        child: const WorkoutScreen(),
      ),
    ),
  );
  return w;
}

void main() {
  testWidgets('workout screen fits a phone and ticking shows the rest panel', (
    tester,
  ) async {
    final clock = FakeClock(DateTime(2026, 1, 1, 10));
    await openScreen(tester, clock);
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

  testWidgets('typing a weight in the dialog updates the set without errors', (
    tester,
  ) async {
    await openScreen(tester, FakeClock(DateTime(2026, 1, 1)));

    await tester.tap(find.text('– kg').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '62.5');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('62.5 kg'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('End Workout needs a reason, then a second confirm', (
    tester,
  ) async {
    final w = await openScreen(tester, FakeClock(DateTime(2026, 1, 1)));

    await tester.tap(find.text('End Workout'));
    await tester.pumpAndSettle();
    expect(
      find.text('You have 16 sets left. Why are you ending?'),
      findsOneWidget,
    );
    final next = find.widgetWithText(FilledButton, 'Next');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);

    await tester.tap(find.text('Gym crowded'));
    await tester.pump();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text("This can't be undone."), findsOneWidget);

    await tester.tap(find.text('Keep going'));
    await tester.pumpAndSettle();
    expect(find.text('Lat Pulldown'), findsOneWidget);
    expect(w.completed, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  test('FakeClock only moves when advanced', () {
    final clock = FakeClock(DateTime(2026, 1, 1, 10));
    expect(clock.now(), DateTime(2026, 1, 1, 10));
    clock.advance(const Duration(seconds: 90));
    expect(clock.now(), DateTime(2026, 1, 1, 10, 1, 30));
  });

  testWidgets('rest ending in the background waits for the app to return', (
    tester,
  ) async {
    final clock = FakeClock(DateTime(2026, 1, 1, 10));
    final w = await openScreen(tester, clock);
    await tester.tap(find.byIcon(Icons.add).at(0));
    await tester.tap(find.byIcon(Icons.add).at(1));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.advance(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(w.rest.isResting, isTrue); // notification stays; no hidden popup
    expect(find.text('Rest over 💪'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Rest over 💪'), findsOneWidget);
    expect(w.rest.isResting, isFalse);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
}
