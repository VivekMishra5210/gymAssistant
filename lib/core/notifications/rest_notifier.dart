import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Where the workout sends "rest ends at" (SPEC §7). Tests use [NoAlerts].
abstract class RestAlerts {
  Future<void> schedule(DateTime at, String body);
  Future<void> cancel();
}

class NoAlerts implements RestAlerts {
  const NoAlerts();

  @override
  Future<void> schedule(DateTime at, String body) async {}
  @override
  Future<void> cancel() async {}
}

const _id = 1; // one rest notification; scheduling again replaces it

const _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'rest_timer',
    'Rest timer',
    channelDescription: 'Tells you when your rest between sets is over',
    importance: Importance.max,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
  ),
);

/// Local notification at the rest end time, exact when allowed (SPEC §7).
class RestNotifier implements RestAlerts {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// Bumps when a rest notification is tapped while the app is alive.
  final taps = ValueNotifier<int>(0);

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Returns true if the app was launched by tapping the notification.
  Future<bool> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_dumbbell'),
      ),
      onDidReceiveNotificationResponse: (_) => taps.value++,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp ?? false;
  }

  /// At Start Workout. The OS only prompts the first time.
  Future<void> requestPermissions() async {
    final a = _android;
    if (a == null) return;
    await a.requestNotificationsPermission();
    // Android 12 only; 13+ gets USE_EXACT_ALARM from the manifest.
    if (await a.canScheduleExactNotifications() == false) {
      await a.requestExactAlarmsPermission();
    }
  }

  @override
  Future<void> schedule(DateTime at, String body) async {
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      id: _id,
      // An absolute instant, so UTC avoids needing the device time zone.
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: _details,
      // Denied exact alarms → inexact; the in-app popup still fires on resume.
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Rest over 💪',
      body: body,
    );
  }

  @override
  Future<void> cancel() => _plugin.cancel(id: _id);
}
