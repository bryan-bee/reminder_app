import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'custom_reminder.dart';

class CustomRemindersStore {
  static const _remindersKey = 'custom_reminders_json';
  static const _nextIdKey = 'custom_reminders_next_id';
  static const _firstId = 3000;
  // Each reminder gets a block of ids for its up-to-24 daily slots
  // (baseId + slotIndex), so blocks must not overlap.
  static const _blockSize = 100;

  static Future<List<CustomReminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_remindersKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    final reminders = <CustomReminder>[];
    for (final entry in decoded) {
      try {
        reminders.add(CustomReminder.fromJson(entry as Map<String, dynamic>));
      } catch (_) {
        // Skip entries saved under an older, incompatible schema instead of
        // crashing the whole list.
      }
    }
    return reminders;
  }

  static Future<void> saveAll(List<CustomReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, encoded);
  }

  static Future<int> nextBaseId() async {
    final prefs = await SharedPreferences.getInstance();
    final next = prefs.getInt(_nextIdKey) ?? _firstId;
    await prefs.setInt(_nextIdKey, next + _blockSize);
    return next;
  }
}
