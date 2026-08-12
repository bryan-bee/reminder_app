import 'dart:math';

import 'package:flutter/material.dart';

import 'affirmations.dart';
import 'notification_service.dart';
import 'reminder_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ReminderSettings? _settings;
  final _notifications = NotificationService.instance;

  static const List<int> _intervalOptions = [1, 2, 3, 4, 6];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _notifications.requestPermissions();
    final settings = await ReminderSettings.load();
    setState(() => _settings = settings);
    await _refreshAffirmationIfNewDay(settings);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _refreshAffirmationIfNewDay(ReminderSettings settings) async {
    if (!settings.affirmationEnabled) return;
    final today = _todayKey();
    if (settings.affirmationLastScheduledDay == today) return;

    final affirmation = affirmations[Random().nextInt(affirmations.length)];
    await _notifications.scheduleAffirmationReminder(
      hour: settings.affirmationHour,
      minute: settings.affirmationMinute,
      affirmationText: affirmation,
    );
    settings.affirmationLastScheduledDay = today;
    await settings.save();
  }

  Future<void> _onWaterToggled(bool enabled) async {
    final settings = _settings!;
    settings.waterEnabled = enabled;
    await settings.save();
    if (enabled) {
      await _notifications.scheduleWaterReminders(
        allDay: settings.waterAllDay,
        startHour: settings.waterStartHour,
        endHour: settings.waterEndHour,
        intervalHours: settings.waterIntervalHours,
      );
    } else {
      await _notifications.cancelWaterReminders();
    }
    setState(() {});
  }

  Future<void> _onWaterConfigChanged() async {
    final settings = _settings!;
    await settings.save();
    if (settings.waterEnabled) {
      await _notifications.scheduleWaterReminders(
        allDay: settings.waterAllDay,
        startHour: settings.waterStartHour,
        endHour: settings.waterEndHour,
        intervalHours: settings.waterIntervalHours,
      );
    }
    setState(() {});
  }

  Future<void> _onAffirmationToggled(bool enabled) async {
    final settings = _settings!;
    settings.affirmationEnabled = enabled;
    if (enabled) {
      final affirmation = affirmations[Random().nextInt(affirmations.length)];
      await _notifications.scheduleAffirmationReminder(
        hour: settings.affirmationHour,
        minute: settings.affirmationMinute,
        affirmationText: affirmation,
      );
      settings.affirmationLastScheduledDay = _todayKey();
    } else {
      await _notifications.cancelAffirmationReminder();
    }
    await settings.save();
    setState(() {});
  }

  Future<void> _onAffirmationTimeChanged() async {
    final settings = _settings!;
    await settings.save();
    if (settings.affirmationEnabled) {
      final affirmation = affirmations[Random().nextInt(affirmations.length)];
      await _notifications.scheduleAffirmationReminder(
        hour: settings.affirmationHour,
        minute: settings.affirmationMinute,
        affirmationText: affirmation,
      );
      settings.affirmationLastScheduledDay = _todayKey();
      await settings.save();
    }
    setState(() {});
  }

  Future<void> _pickAffirmationTime() async {
    final settings = _settings!;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: settings.affirmationHour, minute: settings.affirmationMinute),
    );
    if (picked == null) return;
    settings.affirmationHour = picked.hour;
    settings.affirmationMinute = picked.minute;
    await _onAffirmationTimeChanged();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Send test notification',
            onPressed: () async {
              await _notifications.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent 🧪')),
                );
              }
            },
          ),
        ],
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildWaterCard(settings),
                const SizedBox(height: 16),
                _buildAffirmationCard(settings),
              ],
            ),
    );
  }

  Widget _buildWaterCard(ReminderSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('💧', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Water reminders',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Switch(
                  value: settings.waterEnabled,
                  onChanged: _onWaterToggled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Every'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: settings.waterIntervalHours,
                  items: _intervalOptions
                      .map((h) => DropdownMenuItem(value: h, child: Text('$h hr')))
                      .toList(),
                  onChanged: settings.waterEnabled
                      ? (value) {
                          if (value == null) return;
                          setState(() => settings.waterIntervalHours = value);
                          _onWaterConfigChanged();
                        }
                      : null,
                ),
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All day (00:00–23:59)'),
              value: settings.waterAllDay,
              onChanged: settings.waterEnabled
                  ? (value) {
                      if (value == null) return;
                      setState(() => settings.waterAllDay = value);
                      _onWaterConfigChanged();
                    }
                  : null,
            ),
            if (!settings.waterAllDay)
              Row(
                children: [
                  const Text('from'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: settings.waterStartHour,
                    items: List.generate(24, (h) => h)
                        .map((h) => DropdownMenuItem(value: h, child: Text('$h:00')))
                        .toList(),
                    onChanged: settings.waterEnabled
                        ? (value) {
                            if (value == null) return;
                            setState(() => settings.waterStartHour = value);
                            _onWaterConfigChanged();
                          }
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Text('to'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: settings.waterEndHour,
                    items: List.generate(24, (h) => h)
                        .map((h) => DropdownMenuItem(value: h, child: Text('$h:00')))
                        .toList(),
                    onChanged: settings.waterEnabled
                        ? (value) {
                            if (value == null) return;
                            setState(() => settings.waterEndHour = value);
                            _onWaterConfigChanged();
                          }
                        : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffirmationCard(ReminderSettings settings) {
    final timeLabel = TimeOfDay(
            hour: settings.affirmationHour, minute: settings.affirmationMinute)
        .format(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Daily affirmation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Switch(
                  value: settings.affirmationEnabled,
                  onChanged: _onAffirmationToggled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('At'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: settings.affirmationEnabled ? _pickAffirmationTime : null,
                  child: Text(timeLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
