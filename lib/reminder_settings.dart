import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  static const _waterEnabledKey = 'water_enabled';
  static const _waterAllDayKey = 'water_all_day';
  static const _waterStartHourKey = 'water_start_hour';
  static const _waterEndHourKey = 'water_end_hour';
  static const _waterIntervalHoursKey = 'water_interval_hours';
  static const _waterLastScheduledDayKey = 'water_last_scheduled_day';

  static const _affirmationEnabledKey = 'affirmation_enabled';
  static const _affirmationAllDayKey = 'affirmation_all_day';
  static const _affirmationStartHourKey = 'affirmation_start_hour';
  static const _affirmationEndHourKey = 'affirmation_end_hour';
  static const _affirmationIntervalHoursKey = 'affirmation_interval_hours';
  static const _affirmationLastScheduledDayKey = 'affirmation_last_scheduled_day';

  bool waterEnabled;
  bool waterAllDay;
  int waterStartHour;
  int waterEndHour;
  int waterIntervalHours;
  String? waterLastScheduledDay;

  bool affirmationEnabled;
  bool affirmationAllDay;
  int affirmationStartHour;
  int affirmationEndHour;
  int affirmationIntervalHours;
  String? affirmationLastScheduledDay;

  ReminderSettings({
    required this.waterEnabled,
    required this.waterAllDay,
    required this.waterStartHour,
    required this.waterEndHour,
    required this.waterIntervalHours,
    required this.waterLastScheduledDay,
    required this.affirmationEnabled,
    required this.affirmationAllDay,
    required this.affirmationStartHour,
    required this.affirmationEndHour,
    required this.affirmationIntervalHours,
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
      waterLastScheduledDay: prefs.getString(_waterLastScheduledDayKey),
      affirmationEnabled: prefs.getBool(_affirmationEnabledKey) ?? false,
      affirmationAllDay: prefs.getBool(_affirmationAllDayKey) ?? false,
      affirmationStartHour: prefs.getInt(_affirmationStartHourKey) ?? 8,
      affirmationEndHour: prefs.getInt(_affirmationEndHourKey) ?? 22,
      affirmationIntervalHours: prefs.getInt(_affirmationIntervalHoursKey) ?? 6,
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
    if (waterLastScheduledDay != null) {
      await prefs.setString(_waterLastScheduledDayKey, waterLastScheduledDay!);
    }
    await prefs.setBool(_affirmationEnabledKey, affirmationEnabled);
    await prefs.setBool(_affirmationAllDayKey, affirmationAllDay);
    await prefs.setInt(_affirmationStartHourKey, affirmationStartHour);
    await prefs.setInt(_affirmationEndHourKey, affirmationEndHour);
    await prefs.setInt(_affirmationIntervalHoursKey, affirmationIntervalHours);
    if (affirmationLastScheduledDay != null) {
      await prefs.setString(
          _affirmationLastScheduledDayKey, affirmationLastScheduledDay!);
    }
  }
}
