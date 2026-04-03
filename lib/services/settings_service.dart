import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_models.dart';
import '../services/base_providers.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// --- State Notifier ---
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }

  final SharedPreferences _prefs;
  static const _key = 'medmind_app_settings';

  void _loadSettings() {
    final data = _prefs.getString(_key);
    if (data != null) {
      state = AppSettings.fromJson(data);
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await _prefs.setString(_key, newSettings.toJson());
  }

  // Individual Update Helpers
  Future<void> updateMedicineReminder(bool value) async {
    await updateSettings(state.copyWith(medicineReminder: value));
  }

  Future<void> updateHydrationReminder(bool value) async {
    await updateSettings(state.copyWith(hydrationReminder: value));
  }

  Future<void> updateActivityAlerts(bool value) async {
    await updateSettings(state.copyWith(activityAlerts: value));
  }

  Future<void> updateSleepReminders(bool value) async {
    await updateSettings(state.copyWith(sleepReminders: value));
  }

  Future<void> updateAiInsights(bool value) async {
    await updateSettings(state.copyWith(aiInsights: value));
  }

  Future<void> updateDailyStepGoal(int val) async {
    await updateSettings(state.copyWith(dailyStepGoal: val));
  }

  Future<void> updateWaterIntakeGoal(double val) async {
    await updateSettings(state.copyWith(waterIntakeGoal: val));
  }

  Future<void> updateSleepGoal(int val) async {
    await updateSettings(state.copyWith(sleepGoal: val));
  }

  Future<void> updateCalorieTarget(int val) async {
    await updateSettings(state.copyWith(calorieTarget: val));
  }

  Future<void> updateDarkMode(bool value) async {
    await updateSettings(state.copyWith(darkMode: value));
  }

  Future<void> updateLanguage(String value) async {
    await updateSettings(state.copyWith(language: value));
  }

  Future<void> updateUnits(String value) async {
    await updateSettings(state.copyWith(units: value));
  }
}

// --- Providers ---
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppSettingsNotifier(prefs);
});

final settingsServiceProvider = Provider((ref) => SettingsService(ref));

class SettingsService {
  final Ref ref;
  SettingsService(this.ref);

  Future<void> exportData() async {
    // Generate JSON string from all local storage data
    // (Simulated for this implementation)
    print("Health data exported to JSON/CSV");
  }

  Future<void> deleteAccount() async {
    // Clear all Hive boxes and Preferences
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.clear();

    final lists = [
      'activityLogsBox',
      'nutritionLogsBox',
      'sleepLogsBox',
      'hydrationLogsBox',
      'bodyMetricsBox',
      'chatHistoryBox',
      'medicationsBox',
      'moodLogsBox',
    ];
    for(var box in lists) {
      if(Hive.isBoxOpen(box)) {
        await Hive.box(box).clear();
      }
    }
  }
}
