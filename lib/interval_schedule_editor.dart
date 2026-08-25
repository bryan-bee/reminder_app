import 'package:flutter/material.dart';

import 'notification_service.dart';

/// Editor for a recurring reminder's schedule: an interval between
/// notifications, and either "all day" or a specific start/end hour window.
/// Shared by the water card, the affirmation card, and custom reminders so
/// all three reminder types configure their timing the same way.
class IntervalScheduleEditor extends StatelessWidget {
  const IntervalScheduleEditor({
    super.key,
    required this.enabled,
    required this.allDay,
    required this.startHour,
    required this.endHour,
    required this.intervalHours,
    required this.onAllDayChanged,
    required this.onStartHourChanged,
    required this.onEndHourChanged,
    required this.onIntervalHoursChanged,
    this.intervalOptions = const [
      testingOneMinuteInterval,
      1,
      2,
      3,
      4,
      6,
      8,
      12,
    ],
  });

  final bool enabled;
  final bool allDay;
  final int startHour;
  final int endHour;
  final int intervalHours;
  final List<int> intervalOptions;
  final ValueChanged<bool> onAllDayChanged;
  final ValueChanged<int> onStartHourChanged;
  final ValueChanged<int> onEndHourChanged;
  final ValueChanged<int> onIntervalHoursChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Every'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: intervalHours,
              items: intervalOptions
                  .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(h == testingOneMinuteInterval
                            ? '1 min (test)'
                            : '$h hr'),
                      ))
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      if (value != null) onIntervalHoursChanged(value);
                    }
                  : null,
            ),
          ],
        ),
        if (intervalHours == testingOneMinuteInterval)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Fires once, 60 seconds from now, for testing — ignores the time window below. Toggle off/on or re-save to fire again.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          )
        else
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('All day (00:00–23:59)'),
            value: allDay,
            onChanged: enabled
                ? (value) {
                    if (value != null) onAllDayChanged(value);
                  }
                : null,
          ),
        if (!allDay && intervalHours != testingOneMinuteInterval)
          Row(
            children: [
              const Text('from'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: startHour,
                items: List.generate(24, (h) => h)
                    .map((h) => DropdownMenuItem(value: h, child: Text('$h:00')))
                    .toList(),
                onChanged: enabled
                    ? (value) {
                        if (value != null) onStartHourChanged(value);
                      }
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('to'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: endHour,
                items: List.generate(24, (h) => h)
                    .map((h) => DropdownMenuItem(value: h, child: Text('$h:00')))
                    .toList(),
                onChanged: enabled
                    ? (value) {
                        if (value != null) onEndHourChanged(value);
                      }
                    : null,
              ),
            ],
          ),
      ],
    );
  }
}
