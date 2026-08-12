import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'affirmations.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _waterChannel = AndroidNotificationDetails(
    'water_channel',
    'Water reminders',
    channelDescription: 'Reminders to drink water',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _affirmationChannel = AndroidNotificationDetails(
    'affirmation_channel',
    'Daily affirmations',
    channelDescription: 'Daily positive affirmation reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const int _waterIdBase = 1000;
  static const int _affirmationId = 2000;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);
  }

  /// Android 13+ requires the user to grant notification permission at
  /// runtime; scheduling exact-time alarms also needs a separate permission
  /// on Android 12+. Both are requested here.
  Future<void> requestPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  List<int> hoursForWindow({
    required bool allDay,
    required int startHour,
    required int endHour,
    required int intervalHours,
  }) {
    return allDay
        ? [for (int h = 0; h < 24; h += intervalHours) h]
        : [for (int h = startHour; h <= endHour; h += intervalHours) h];
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < 24; i++) {
      await _plugin.cancel(id: _waterIdBase + i);
    }
  }

  Future<void> scheduleWaterReminders({
    required bool allDay,
    required int startHour,
    required int endHour,
    required int intervalHours,
  }) async {
    await cancelWaterReminders();
    final hours = hoursForWindow(
      allDay: allDay,
      startHour: startHour,
      endHour: endHour,
      intervalHours: intervalHours,
    );

    for (int slot = 0; slot < hours.length; slot++) {
      final scheduledTime = _nextInstanceOfTime(hours[slot], 0);
      final message = waterReminderMessages[slot % waterReminderMessages.length];
      await _plugin.zonedSchedule(
        id: _waterIdBase + slot,
        title: '💧 Hydration time',
        body: message,
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(android: _waterChannel),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Fires a notification immediately so you can confirm the notification
  /// pipeline (permissions, channel, icon) works without waiting for a real
  /// scheduled time to arrive.
  Future<void> showTestNotification() async {
    final message = waterReminderMessages[
        DateTime.now().second % waterReminderMessages.length];
    await _plugin.show(
      id: 9999,
      title: '🧪 Test notification',
      body: message,
      notificationDetails: const NotificationDetails(android: _waterChannel),
    );
  }

  Future<void> cancelAffirmationReminder() async {
    await _plugin.cancel(id: _affirmationId);
  }

  Future<void> scheduleAffirmationReminder({
    required int hour,
    required int minute,
    required String affirmationText,
  }) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);
    await _plugin.zonedSchedule(
      id: _affirmationId,
      title: '✨ Your daily affirmation',
      body: affirmationText,
      scheduledDate: scheduledTime,
      notificationDetails:
          const NotificationDetails(android: _affirmationChannel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
