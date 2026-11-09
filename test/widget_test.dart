import 'package:flutter_test/flutter_test.dart';
import 'package:gym_assistant/app.dart';
import 'package:gym_assistant/core/time/clock.dart';

void main() {
  testWidgets('app starts with title', (tester) async {
    await tester.pumpWidget(const GymApp());
    expect(find.text('Gym Assistant'), findsOneWidget);
  });

  test('FakeClock only moves when advanced', () {
    final clock = FakeClock(DateTime(2026, 1, 1, 10));
    expect(clock.now(), DateTime(2026, 1, 1, 10));
    clock.advance(const Duration(seconds: 90));
    expect(clock.now(), DateTime(2026, 1, 1, 10, 1, 30));
  });
}
