import 'dart:convert';

class AppSettings {
  final bool medicineReminder;
  final bool hydrationReminder;
  final bool activityAlerts;
  final bool sleepReminders;
  final bool aiInsights;

  final int dailyStepGoal;
  final double waterIntakeGoal;
  final int sleepGoal;
  final int calorieTarget;

  final bool darkMode;
  final String language;
  final String units;

  const AppSettings({
    this.medicineReminder = true,
    this.hydrationReminder = true,
    this.activityAlerts = true,
    this.sleepReminders = true,
    this.aiInsights = true,

    this.dailyStepGoal = 10000,
    this.waterIntakeGoal = 2.5,
    this.sleepGoal = 8,
    this.calorieTarget = 2200,

    this.darkMode = true,
    this.language = 'English',
    this.units = 'Metric',
  });

  AppSettings copyWith({
    bool? medicineReminder,
    bool? hydrationReminder,
    bool? activityAlerts,
    bool? sleepReminders,
    bool? aiInsights,
    int? dailyStepGoal,
    double? waterIntakeGoal,
    int? sleepGoal,
    int? calorieTarget,
    bool? darkMode,
    String? language,
    String? units,
  }) {
    return AppSettings(
      medicineReminder: medicineReminder ?? this.medicineReminder,
      hydrationReminder: hydrationReminder ?? this.hydrationReminder,
      activityAlerts: activityAlerts ?? this.activityAlerts,
      sleepReminders: sleepReminders ?? this.sleepReminders,
      aiInsights: aiInsights ?? this.aiInsights,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      waterIntakeGoal: waterIntakeGoal ?? this.waterIntakeGoal,
      sleepGoal: sleepGoal ?? this.sleepGoal,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      units: units ?? this.units,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineReminder': medicineReminder,
      'hydrationReminder': hydrationReminder,
      'activityAlerts': activityAlerts,
      'sleepReminders': sleepReminders,
      'aiInsights': aiInsights,
      'dailyStepGoal': dailyStepGoal,
      'waterIntakeGoal': waterIntakeGoal,
      'sleepGoal': sleepGoal,
      'calorieTarget': calorieTarget,
      'darkMode': darkMode,
      'language': language,
      'units': units,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      medicineReminder: map['medicineReminder'] ?? true,
      hydrationReminder: map['hydrationReminder'] ?? true,
      activityAlerts: map['activityAlerts'] ?? true,
      sleepReminders: map['sleepReminders'] ?? true,
      aiInsights: map['aiInsights'] ?? true,
      dailyStepGoal: map['dailyStepGoal']?.toInt() ?? 10000,
      waterIntakeGoal: map['waterIntakeGoal']?.toDouble() ?? 2.5,
      sleepGoal: map['sleepGoal']?.toInt() ?? 8,
      calorieTarget: map['calorieTarget']?.toInt() ?? 2200,
      darkMode: map['darkMode'] ?? true,
      language: map['language'] ?? 'English',
      units: map['units'] ?? 'Metric',
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) => AppSettings.fromMap(json.decode(source));
}
