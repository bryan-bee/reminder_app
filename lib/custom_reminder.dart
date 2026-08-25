class CustomReminder {
  /// Base notification id for this reminder. Each of its scheduled time
  /// slots uses baseId + slotIndex, so ids must be spaced far enough apart
  /// (see CustomRemindersStore.nextBaseId) to never collide between reminders.
  final int baseId;
  String title;
  String message;
  bool allDay;
  int startHour;
  int endHour;
  int intervalHours;
  bool enabled;
  String? lastScheduledDay;

  CustomReminder({
    required this.baseId,
    required this.title,
    required this.message,
    required this.allDay,
    required this.startHour,
    required this.endHour,
    required this.intervalHours,
    required this.enabled,
    this.lastScheduledDay,
  });

  Map<String, dynamic> toJson() => {
        'baseId': baseId,
        'title': title,
        'message': message,
        'allDay': allDay,
        'startHour': startHour,
        'endHour': endHour,
        'intervalHours': intervalHours,
        'enabled': enabled,
        'lastScheduledDay': lastScheduledDay,
      };

  factory CustomReminder.fromJson(Map<String, dynamic> json) => CustomReminder(
        baseId: json['baseId'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        allDay: json['allDay'] as bool? ?? false,
        startHour: json['startHour'] as int? ?? 8,
        endHour: json['endHour'] as int? ?? 20,
        intervalHours: json['intervalHours'] as int? ?? 4,
        enabled: json['enabled'] as bool,
        lastScheduledDay: json['lastScheduledDay'] as String?,
      );
}
