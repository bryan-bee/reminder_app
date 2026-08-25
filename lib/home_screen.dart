import 'package:flutter/material.dart';

import 'custom_reminder.dart';
import 'custom_reminders_store.dart';
import 'interval_schedule_editor.dart';
import 'notification_service.dart';
import 'reminder_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ReminderSettings? _settings;
  List<CustomReminder> _customReminders = [];
  final _notifications = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _notifications.requestPermissions();
    final settings = await ReminderSettings.load();
    final customReminders = await CustomRemindersStore.load();
    setState(() {
      _settings = settings;
      _customReminders = customReminders;
    });
    await _refreshWaterIfNewDay(settings);
    await _refreshAffirmationIfNewDay(settings);
    await _refreshCustomRemindersIfNewDay();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _refreshWaterIfNewDay(ReminderSettings settings) async {
    if (!settings.waterEnabled) return;
    if (settings.waterLastScheduledDay == _todayKey()) return;
    await _rescheduleWater(settings);
  }

  Future<void> _rescheduleWater(ReminderSettings settings) async {
    await _notifications.scheduleWaterReminders(
      allDay: settings.waterAllDay,
      startHour: settings.waterStartHour,
      endHour: settings.waterEndHour,
      intervalHours: settings.waterIntervalHours,
    );
    settings.waterLastScheduledDay = _todayKey();
    await settings.save();
  }

  Future<void> _refreshAffirmationIfNewDay(ReminderSettings settings) async {
    if (!settings.affirmationEnabled) return;
    if (settings.affirmationLastScheduledDay == _todayKey()) return;
    await _rescheduleAffirmation(settings);
  }

  Future<void> _rescheduleAffirmation(ReminderSettings settings) async {
    await _notifications.scheduleAffirmationReminders(
      allDay: settings.affirmationAllDay,
      startHour: settings.affirmationStartHour,
      endHour: settings.affirmationEndHour,
      intervalHours: settings.affirmationIntervalHours,
    );
    settings.affirmationLastScheduledDay = _todayKey();
    await settings.save();
  }

  Future<void> _onWaterToggled(bool enabled) async {
    final settings = _settings!;
    settings.waterEnabled = enabled;
    if (enabled) {
      await _rescheduleWater(settings);
    } else {
      await _notifications.cancelWaterReminders();
      await settings.save();
    }
    setState(() {});
  }

  Future<void> _onWaterConfigChanged() async {
    final settings = _settings!;
    if (settings.waterEnabled) {
      await _rescheduleWater(settings);
    } else {
      await settings.save();
    }
    setState(() {});
  }

  Future<void> _onAffirmationToggled(bool enabled) async {
    final settings = _settings!;
    settings.affirmationEnabled = enabled;
    if (enabled) {
      await _rescheduleAffirmation(settings);
    } else {
      await _notifications.cancelAffirmationReminders();
      await settings.save();
    }
    setState(() {});
  }

  Future<void> _onAffirmationConfigChanged() async {
    final settings = _settings!;
    if (settings.affirmationEnabled) {
      await _rescheduleAffirmation(settings);
    } else {
      await settings.save();
    }
    setState(() {});
  }

  Future<void> _saveCustomReminders() async {
    await CustomRemindersStore.saveAll(_customReminders);
  }

  Future<void> _refreshCustomRemindersIfNewDay() async {
    final today = _todayKey();
    var changed = false;
    for (final reminder in _customReminders) {
      if (!reminder.enabled) continue;
      if (reminder.lastScheduledDay == today) continue;
      await _scheduleCustom(reminder);
      changed = true;
    }
    if (changed) await _saveCustomReminders();
  }

  Future<void> _addCustomReminder() async {
    final result = await _showCustomReminderDialog();
    if (result == null) return;
    final baseId = await CustomRemindersStore.nextBaseId();
    final reminder = CustomReminder(
      baseId: baseId,
      title: result.title,
      message: result.message,
      allDay: result.allDay,
      startHour: result.startHour,
      endHour: result.endHour,
      intervalHours: result.intervalHours,
      enabled: true,
    );
    setState(() => _customReminders.add(reminder));
    await _scheduleCustom(reminder);
    await _saveCustomReminders();
  }

  Future<void> _editCustomReminder(CustomReminder reminder) async {
    final result = await _showCustomReminderDialog(existing: reminder);
    if (result == null) return;
    setState(() {
      reminder.title = result.title;
      reminder.message = result.message;
      reminder.allDay = result.allDay;
      reminder.startHour = result.startHour;
      reminder.endHour = result.endHour;
      reminder.intervalHours = result.intervalHours;
    });
    if (reminder.enabled) {
      await _scheduleCustom(reminder);
    }
    await _saveCustomReminders();
  }

  Future<void> _scheduleCustom(CustomReminder reminder) async {
    await _notifications.scheduleCustomReminder(
      baseId: reminder.baseId,
      title: reminder.title,
      message: reminder.message,
      allDay: reminder.allDay,
      startHour: reminder.startHour,
      endHour: reminder.endHour,
      intervalHours: reminder.intervalHours,
    );
    reminder.lastScheduledDay = _todayKey();
  }

  Future<void> _toggleCustomReminder(CustomReminder reminder, bool enabled) async {
    setState(() => reminder.enabled = enabled);
    if (enabled) {
      await _scheduleCustom(reminder);
    } else {
      await _notifications.cancelCustomReminder(reminder.baseId);
    }
    await _saveCustomReminders();
  }

  Future<void> _deleteCustomReminder(CustomReminder reminder) async {
    await _notifications.cancelCustomReminder(reminder.baseId);
    setState(() => _customReminders.remove(reminder));
    await _saveCustomReminders();
  }

  Future<void> _fireTest(Future<void> Function() action) async {
    await action();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent 🧪')),
      );
    }
  }

  String _scheduleSummary(
      {required bool allDay,
      required int startHour,
      required int endHour,
      required int intervalHours}) {
    if (intervalHours == testingOneMinuteInterval) {
      return '1 min (test)';
    }
    final window = allDay ? 'all day' : '$startHour:00–$endHour:00';
    return 'Every $intervalHours hr, $window';
  }

  Future<_CustomReminderInput?> _showCustomReminderDialog({
    CustomReminder? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final messageController =
        TextEditingController(text: existing?.message ?? '');
    bool allDay = existing?.allDay ?? false;
    int startHour = existing?.startHour ?? 8;
    int endHour = existing?.endHour ?? 20;
    int intervalHours = existing?.intervalHours ?? 4;

    return showDialog<_CustomReminderInput>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'New reminder' : 'Edit reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Take medication',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'e.g. 💊 Time for your meds!',
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntervalScheduleEditor(
                      enabled: true,
                      allDay: allDay,
                      startHour: startHour,
                      endHour: endHour,
                      intervalHours: intervalHours,
                      onAllDayChanged: (value) =>
                          setDialogState(() => allDay = value),
                      onStartHourChanged: (value) =>
                          setDialogState(() => startHour = value),
                      onEndHourChanged: (value) =>
                          setDialogState(() => endHour = value),
                      onIntervalHoursChanged: (value) =>
                          setDialogState(() => intervalHours = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final message = messageController.text.trim();
                    if (title.isEmpty || message.isEmpty) return;
                    Navigator.of(dialogContext).pop(
                      _CustomReminderInput(
                        title: title,
                        message: message,
                        allDay: allDay,
                        startHour: startHour,
                        endHour: endHour,
                        intervalHours: intervalHours,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(title: const Text('🔔 Reminders')),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildWaterCard(settings),
                const SizedBox(height: 16),
                _buildAffirmationCard(settings),
                const SizedBox(height: 16),
                ..._customReminders.map(_buildCustomReminderCard),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addCustomReminder,
                  icon: const Icon(Icons.add),
                  label: const Text('Add custom reminder'),
                ),
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
                IconButton(
                  icon: const Icon(Icons.science_outlined),
                  tooltip: 'Send test notification',
                  onPressed: () =>
                      _fireTest(_notifications.showTestWaterNotification),
                ),
                Switch(
                  value: settings.waterEnabled,
                  onChanged: _onWaterToggled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            IntervalScheduleEditor(
              enabled: settings.waterEnabled,
              allDay: settings.waterAllDay,
              startHour: settings.waterStartHour,
              endHour: settings.waterEndHour,
              intervalHours: settings.waterIntervalHours,
              onAllDayChanged: (value) {
                setState(() => settings.waterAllDay = value);
                _onWaterConfigChanged();
              },
              onStartHourChanged: (value) {
                setState(() => settings.waterStartHour = value);
                _onWaterConfigChanged();
              },
              onEndHourChanged: (value) {
                setState(() => settings.waterEndHour = value);
                _onWaterConfigChanged();
              },
              onIntervalHoursChanged: (value) {
                setState(() => settings.waterIntervalHours = value);
                _onWaterConfigChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffirmationCard(ReminderSettings settings) {
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
                  child: Text('Daily affirmations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.science_outlined),
                  tooltip: 'Send test notification',
                  onPressed: () =>
                      _fireTest(_notifications.showTestAffirmationNotification),
                ),
                Switch(
                  value: settings.affirmationEnabled,
                  onChanged: _onAffirmationToggled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            IntervalScheduleEditor(
              enabled: settings.affirmationEnabled,
              allDay: settings.affirmationAllDay,
              startHour: settings.affirmationStartHour,
              endHour: settings.affirmationEndHour,
              intervalHours: settings.affirmationIntervalHours,
              onAllDayChanged: (value) {
                setState(() => settings.affirmationAllDay = value);
                _onAffirmationConfigChanged();
              },
              onStartHourChanged: (value) {
                setState(() => settings.affirmationStartHour = value);
                _onAffirmationConfigChanged();
              },
              onEndHourChanged: (value) {
                setState(() => settings.affirmationEndHour = value);
                _onAffirmationConfigChanged();
              },
              onIntervalHoursChanged: (value) {
                setState(() => settings.affirmationIntervalHours = value);
                _onAffirmationConfigChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomReminderCard(CustomReminder reminder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(reminder.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Switch(
                    value: reminder.enabled,
                    onChanged: (value) => _toggleCustomReminder(reminder, value),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(reminder.message),
              const SizedBox(height: 4),
              Text(
                _scheduleSummary(
                  allDay: reminder.allDay,
                  startHour: reminder.startHour,
                  endHour: reminder.endHour,
                  intervalHours: reminder.intervalHours,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.science_outlined),
                      tooltip: 'Send test notification',
                      onPressed: () => _fireTest(
                        () => _notifications.showTestCustomNotification(
                          title: reminder.title,
                          message: reminder.message,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => _editCustomReminder(reminder),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      onPressed: () => _deleteCustomReminder(reminder),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomReminderInput {
  final String title;
  final String message;
  final bool allDay;
  final int startHour;
  final int endHour;
  final int intervalHours;

  _CustomReminderInput({
    required this.title,
    required this.message,
    required this.allDay,
    required this.startHour,
    required this.endHour,
    required this.intervalHours,
  });
}
