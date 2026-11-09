/// Injectable "now" so logic never calls DateTime.now() directly.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Test clock: time only moves when you tell it to.
class FakeClock implements Clock {
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);

  void set(DateTime t) => _now = t;
}
