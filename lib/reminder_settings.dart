import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  static const _waterEnabledKey = 'water_enabled';
  static const _waterAllDayKey = 'water_all_day';
  static const _waterStartHourKey = 'water_start_hour';
  static const _waterEndHourKey = 'water_end_hour';
  static const _waterIntervalHoursKey = 'water_interval_hours';

  static const _affirmationEnabledKey = 'affirmation_enabled';
  static const _affirmationHourKey = 'affirmation_hour';
  static const _affirmationMinuteKey = 'affirmation_minute';
  static const _affirmationLastScheduledDayKey = 'affirmation_last_scheduled_day';

  bool waterEnabled;
  bool waterAllDay;
  int waterStartHour;
  int waterEndHour;
  int waterIntervalHours;

  bool affirmationEnabled;
  int affirmationHour;
  int affirmationMinute;
  String? affirmationLastScheduledDay;

  ReminderSettings({
    required this.waterEnabled,
    required this.waterAllDay,
    required this.waterStartHour,
    required this.waterEndHour,
    required this.waterIntervalHours,
    required this.affirmationEnabled,
    required this.affirmationHour,
    required this.affirmationMinute,
    required this.affirmationLastScheduledDay,
  });

  static Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      waterEnabled: prefs.getBool(_waterEnabledKey) ?? false,
      waterAllDay: prefs.getBool(_waterAllDayKey) ?? false,
      waterStartHour: prefs.getInt(_waterStartHourKey) ?? 8,
      waterEndHour: prefs.getInt(_waterEndHourKey) ?? 22,
      waterIntervalHours: prefs.getInt(_waterIntervalHoursKey) ?? 2,
      affirmationEnabled: prefs.getBool(_affirmationEnabledKey) ?? false,
      affirmationHour: prefs.getInt(_affirmationHourKey) ?? 9,
      affirmationMinute: prefs.getInt(_affirmationMinuteKey) ?? 0,
      affirmationLastScheduledDay:
          prefs.getString(_affirmationLastScheduledDayKey),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_waterEnabledKey, waterEnabled);
    await prefs.setBool(_waterAllDayKey, waterAllDay);
    await prefs.setInt(_waterStartHourKey, waterStartHour);
    await prefs.setInt(_waterEndHourKey, waterEndHour);
    await prefs.setInt(_waterIntervalHoursKey, waterIntervalHours);
    await prefs.setBool(_affirmationEnabledKey, affirmationEnabled);
    await prefs.setInt(_affirmationHourKey, affirmationHour);
    await prefs.setInt(_affirmationMinuteKey, affirmationMinute);
    if (affirmationLastScheduledDay != null) {
      await prefs.setString(
          _affirmationLastScheduledDayKey, affirmationLastScheduledDay!);
    }
  }
}
