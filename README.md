# Gym Assistant 🏋️

A personal, fully offline Android app that runs your workout and **enforces consistent rest between sets** — no account, no internet, no ads. Your data never leaves your phone.

## Features

- **Flexible split cycle** — define your own days (e.g. Push / Pull / Legs / Rest). The cycle advances only when you finish a workout or a rest day passes, never by weekday, so a missed day doesn't scramble your plan.
- **Multiple splits** — keep several (e.g. *College*, *Exams*, *Home*) and switch anytime; each remembers where you left off.
- **Guided workouts** — log kg × reps per set with last-session pre-fill, or **minutes for cardio**.
- **Rest timer you can trust** — based on a stored end time, not a running countdown, so it survives the app being closed. A notification, sound and vibration tell you when rest is over, even with the screen locked.
- **History & streaks** — calendar with completed / ended-early / rest marks, day details, current and best streak with configurable grace days.
- **Progress & PRs** — per exercise: best set, estimated 1RM, heaviest-set chart, last session.
- **Stats** — gym time, workouts, average per workout and per day, sets and volume for this week, this month and all time.
- **BMI & weight trend** — height plus a weigh-in log with a trend chart.
- **Backup & restore** — export everything to Drive / Downloads and restore it on any phone.
- Dark, high-contrast UI with large tap targets, built for use mid-set.

## Install

Download `app-release.apk` from [Releases](../../releases) (or build it, below) and open it on your phone.

1. Allow **Install unknown apps** when Android asks, and tap **Install anyway** if Play Protect warns (it's not from the Play Store).
2. Allow notifications.
3. For a reliable rest alarm, set **Battery → No restrictions** for the app; on Xiaomi / Redmi / Poco also turn **Autostart** on.

Android only. Updates signed with the same key install over the old version and keep your data.

## Build from source

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ≥ 3.13) and the Android SDK.

```bash
flutter pub get
flutter analyze
flutter test
flutter run                       # debug build on a connected phone
flutter build apk --release       # build/app/outputs/flutter-apk/app-release.apk
flutter build apk --release --split-per-abi   # smaller per-CPU APKs
```

Update an installed copy without losing data:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

(`flutter install` uninstalls first, which wipes the app's data.)

**Release signing:** put `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`) next to your keystore. Both are gitignored. Without them, release builds fall back to the debug key.

## Tech

Flutter · SQLite (`sqflite`) · `provider` · `flutter_local_notifications` · `table_calendar` · `wakelock_plus` · `audioplayers` · `vibration`

```
lib/
  core/      database + migrations, backup, clock, notifications
  data/      models and repositories (plan, sessions, app state)
  logic/     pure, unit-tested rules: split cycle, rest timer, streaks, stats
  ui/        dashboard, workout, day detail, stats, BMI, settings
test/        unit and widget tests
```

Business logic is pure Dart with an injected clock, so time-dependent rules (rest timer, streaks, midnight crossing) are fully testable. The full design and rules are in [docs/SPEC.md](docs/SPEC.md).
