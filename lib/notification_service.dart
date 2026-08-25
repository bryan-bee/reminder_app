import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'affirmations.dart';
import 'shuffle_bag.dart';

/// The maximum number of slots any recurring reminder can have in a day.
/// A windowed reminder can have up to ~24 one-shot "today" slots (preserving
/// the minute it was turned on) PLUS up to ~24 hour-aligned daily-repeat
/// slots active at once, so every reminder type's id block must be wide
/// enough to hold both sets without colliding with the next reminder's ids.
const int maxDailySlots = 48;

/// Sentinel value for intervalHours meaning "every 1 minute, for testing
/// only". Android's daily-repeat mechanism can't fire sub-hourly, so this
/// bypasses the normal time-window scheduling entirely.
const int testingOneMinuteInterval = 0;

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

  static const _customChannel = AndroidNotificationDetails(
    'custom_channel',
    'Custom reminders',
    channelDescription: 'Your own custom reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  // iOS suppresses alerts while the app is in the foreground unless told
  // otherwise; this makes reminders show even while the app is open, same
  // as Android's default behavior.
  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const int _waterIdBase = 1000;
  static const int _affirmationIdBase = 2000;

  final ShuffleBag<String> _waterMessageBag =
      ShuffleBag<String>(waterReminderMessages);
  final ShuffleBag<String> _affirmationBag = ShuffleBag<String>(affirmations);

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permissions are requested explicitly later (in requestPermissions),
    // not automatically at init, so the app controls when the iOS prompt
    // appears rather than it firing the instant the app launches.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: settings);
  }

  /// Android 13+ requires the user to grant notification permission at
  /// runtime; scheduling exact-time alarms also needs a separate permission
  /// on Android 12+. iOS requires its own alert/badge/sound permission
  /// prompt. All are requested here.
  Future<void> requestPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    final canScheduleExact = await androidPlugin?.canScheduleExactNotifications();
    debugPrint('[NotificationService] canScheduleExactNotifications=$canScheduleExact');

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Fires a one-shot notification 60 seconds from now via the same
  /// zonedSchedule path real reminders use, so it exercises real
  /// exact-alarm delivery (including while backgrounded/idle) without
  /// relying on a true repeating OS alarm.
  Future<void> _showTestingDelayed({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationDetails channel,
  }) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 60));
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: NotificationDetails(android: channel, iOS: _iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('[NotificationService] scheduled 1-min test for id=$id at $scheduledTime');
    } catch (e) {
      debugPrint('[NotificationService] FAILED to schedule 1-min test for id=$id: $e');
      rethrow;
    }
  }

  /// The hours-of-day a windowed reminder should fire at.
  List<int> hoursForWindow({
    required int startHour,
    required int endHour,
    required int intervalHours,
  }) {
    return [for (int h = startHour; h <= endHour; h += intervalHours) h];
  }

  /// Schedules a recurring reminder, preserving the exact minute it was
  /// turned on/reconfigured (e.g. enabled at 10:31 with a 1hr interval fires
  /// at 11:31, 12:31, ...) rather than snapping to the top of the hour.
  ///
  /// [allDay] reminders have no window boundary, so a single native
  /// repeating alarm preserves that minute offset forever.
  ///
  /// Windowed reminders can't repeat sub-daily on Android without an
  /// exact-time anchor, so this schedules two layers:
  ///  - one-shot notifications for the rest of *today*, preserving the
  ///    turn-on minute, until the window closes;
  ///  - a forever daily-repeating pattern aligned to whole hours (e.g. 8:00,
  ///    9:00, ...), which takes over once the window re-opens. Hours whose
  ///    today's occurrence would fall inside the one-shot range are skipped
  ///    today so they don't double-fire, then resolve to tomorrow.
  /// The hour-aligned layer only "tops up" as far as the next occurrence
  /// hasn't already passed, so re-running this once a day (already done via
  /// the app's daily refresh) keeps the whole window covered.
  Future<void> _scheduleRecurring({
    required int idBase,
    required String title,
    required String Function() nextMessage,
    required AndroidNotificationDetails channel,
    required bool allDay,
    required int startHour,
    required int endHour,
    required int intervalHours,
  }) async {
    if (allDay) {
      await _plugin.periodicallyShowWithDuration(
        id: idBase,
        title: title,
        body: nextMessage(),
        repeatDurationInterval: Duration(hours: intervalHours),
        notificationDetails: NotificationDetails(android: channel, iOS: _iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final windowStart =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, startHour);
    final windowEnd =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, endHour);
    final insideWindow = !now.isBefore(windowStart) && !now.isAfter(windowEnd);

    int slot = 0;

    if (insideWindow) {
      var t = now.add(Duration(hours: intervalHours));
      while (!t.isAfter(windowEnd)) {
        await _plugin.zonedSchedule(
          id: idBase + slot,
          title: title,
          body: nextMessage(),
          scheduledDate: t,
          notificationDetails: NotificationDetails(android: channel, iOS: _iosDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        slot++;
        t = t.add(Duration(hours: intervalHours));
      }
    }

    final hours = hoursForWindow(
      startHour: startHour,
      endHour: endHour,
      intervalHours: intervalHours,
    );
    for (final hour in hours) {
      final hourTime =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      final alreadyPassedToday = !hourTime.isAfter(now);
      if (insideWindow && !alreadyPassedToday) {
        // Already covered by today's one-shot pattern above.
        continue;
      }
      await _plugin.zonedSchedule(
        id: idBase + slot,
        title: title,
        body: nextMessage(),
        scheduledDate: hourTime,
        notificationDetails: NotificationDetails(android: channel, iOS: _iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      slot++;
    }
  }

  Future<void> cancelWaterReminders() async {
    for (int i = 0; i < maxDailySlots; i++) {
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
    if (intervalHours == testingOneMinuteInterval) {
      await _showTestingDelayed(
        id: _waterIdBase,
        title: '💧 Hydration time',
        body: _waterMessageBag.next(),
        channel: _waterChannel,
      );
      return;
    }
    await _scheduleRecurring(
      idBase: _waterIdBase,
      title: '💧 Hydration time',
      nextMessage: _waterMessageBag.next,
      channel: _waterChannel,
      allDay: allDay,
      startHour: startHour,
      endHour: endHour,
      intervalHours: intervalHours,
    );
  }

  static const int _testWaterId = 9001;
  static const int _testAffirmationId = 9002;
  static const int _testCustomId = 9003;

  /// Fires a notification for this reminder type immediately, using a
  /// random message from its own pool, so you can confirm it looks right
  /// without waiting for a real scheduled time to arrive.
  Future<void> showTestWaterNotification() async {
    final message =
        waterReminderMessages[Random().nextInt(waterReminderMessages.length)];
    await _plugin.show(
      id: _testWaterId,
      title: '💧 Hydration time',
      body: message,
      notificationDetails:
          const NotificationDetails(android: _waterChannel, iOS: _iosDetails),
    );
  }

  Future<void> showTestAffirmationNotification() async {
    final message = affirmations[Random().nextInt(affirmations.length)];
    await _plugin.show(
      id: _testAffirmationId,
      title: '✨ Your daily affirmation',
      body: message,
      notificationDetails: const NotificationDetails(
          android: _affirmationChannel, iOS: _iosDetails),
    );
  }

  Future<void> showTestCustomNotification({
    required String title,
    required String message,
  }) async {
    await _plugin.show(
      id: _testCustomId,
      title: title,
      body: message,
      notificationDetails:
          const NotificationDetails(android: _customChannel, iOS: _iosDetails),
    );
  }

  Future<void> cancelAffirmationReminders() async {
    for (int i = 0; i < maxDailySlots; i++) {
      await _plugin.cancel(id: _affirmationIdBase + i);
    }
  }

  Future<void> scheduleAffirmationReminders({
    required bool allDay,
    required int startHour,
    required int endHour,
    required int intervalHours,
  }) async {
    await cancelAffirmationReminders();
    if (intervalHours == testingOneMinuteInterval) {
      await _showTestingDelayed(
        id: _affirmationIdBase,
        title: '✨ Your daily affirmation',
        body: _affirmationBag.next(),
        channel: _affirmationChannel,
      );
      return;
    }
    await _scheduleRecurring(
      idBase: _affirmationIdBase,
      title: '✨ Your daily affirmation',
      nextMessage: _affirmationBag.next,
      channel: _affirmationChannel,
      allDay: allDay,
      startHour: startHour,
      endHour: endHour,
      intervalHours: intervalHours,
    );
  }

  Future<void> cancelCustomReminder(int baseId) async {
    for (int i = 0; i < maxDailySlots; i++) {
      await _plugin.cancel(id: baseId + i);
    }
  }

  Future<void> scheduleCustomReminder({
    required int baseId,
    required String title,
    required String message,
    required bool allDay,
    required int startHour,
    required int endHour,
    required int intervalHours,
  }) async {
    await cancelCustomReminder(baseId);
    if (intervalHours == testingOneMinuteInterval) {
      await _showTestingDelayed(
        id: baseId,
        title: title,
        body: message,
        channel: _customChannel,
      );
      return;
    }
    await _scheduleRecurring(
      idBase: baseId,
      title: title,
      nextMessage: () => message,
      channel: _customChannel,
      allDay: allDay,
      startHour: startHour,
      endHour: endHour,
      intervalHours: intervalHours,
    );
  }
}
