import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity_tracker_models.dart';

class ActivityTrackerService {
  static const String activityLogsBoxName = 'activityLogsBox';
  static const String nutritionLogsBoxName = 'nutritionLogsBox';
  static const String sleepLogsBoxName = 'sleepLogsBox';
  static const String hydrationLogsBoxName = 'hydrationLogsBox';
  static const String bodyMetricsBoxName = 'bodyMetricsBox';

  static Database? _database;

  static Future<void> init() async {
    await Hive.openBox(activityLogsBoxName);
    await Hive.openBox(nutritionLogsBoxName);
    await Hive.openBox(sleepLogsBoxName);
    await Hive.openBox(hydrationLogsBoxName);
    await Hive.openBox(bodyMetricsBoxName);

    if (!kIsWeb) {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'activity_history.db'),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE history_records(id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, date TEXT, value REAL)',
          );
        },
        version: 1,
      );
    }
  }

  // --- Activity Logs ---
  Future<void> saveActivityLog(UserActivityLog log) async {
    final box = Hive.box(activityLogsBoxName);
    final key = _dayKey(log.date);
    await box.put(key, log.toMap());
    
    // SQLite for history tracking
    if (!kIsWeb) {
      await _database?.insert('history_records', {
        'type': 'steps',
        'date': log.date.toIso8601String(),
        'value': log.steps.toDouble(),
      });
    }
  }

  UserActivityLog? getTodayActivity() {
    final box = Hive.box(activityLogsBoxName);
    final key = _dayKey(DateTime.now());
    final data = box.get(key);
    if (data == null) return null;
    return UserActivityLog.fromMap(data as Map);
  }

  List<UserActivityLog> getActivityHistory() {
    final box = Hive.box(activityLogsBoxName);
    final list = box.values.map((e) => UserActivityLog.fromMap(e as Map)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // --- Nutrition Logs ---
  Future<void> saveNutritionLog(NutritionLog log) async {
    final box = Hive.box(nutritionLogsBoxName);
    await box.add(log.toMap());
  }

  List<NutritionLog> getDailyNutrition(DateTime date) {
    final box = Hive.box(nutritionLogsBoxName);
    final target = _dayKey(date);
    return box.values
        .map((e) => NutritionLog.fromMap(e as Map))
        .where((log) => _dayKey(log.date) == target)
        .toList();
  }

  // --- Sleep Logs ---
  Future<void> saveSleepLog(UserSleepLog log) async {
    final box = Hive.box(sleepLogsBoxName);
    await box.add(log.toMap());
  }

  List<UserSleepLog> getSleepHistory() {
    final box = Hive.box(sleepLogsBoxName);
    final list = box.values.map((e) => UserSleepLog.fromMap(e as Map)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // --- Hydration Logs ---
  Future<void> saveHydrationLog(UserHydrationLog log) async {
    final box = Hive.box(hydrationLogsBoxName);
    await box.add(log.toMap());

    // SQLite for history mapping
    if (!kIsWeb) {
       await _database?.insert('history_records', {
        'type': 'hydration',
        'date': log.date.toIso8601String(),
        'value': log.waterMl.toDouble(),
      });
    }
  }

  int getTodayHydration() {
    final box = Hive.box(hydrationLogsBoxName);
    final target = _dayKey(DateTime.now());
    final daily = box.values
        .map((e) => UserHydrationLog.fromMap(e as Map))
        .where((l) => _dayKey(l.date) == target);
    
    return daily.fold(0, (sum, item) => sum + item.waterMl);
  }

  List<UserHydrationLog> getHydrationHistory() {
    final box = Hive.box(hydrationLogsBoxName);
    final list = box.values.map((e) => UserHydrationLog.fromMap(e as Map)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // --- Body Metrics ---
  Future<void> saveBodyMetrics(BodyMetrics metrics) async {
    final box = Hive.box(bodyMetricsBoxName);
    await box.add(metrics.toMap());
  }

  BodyMetrics? getLatestBodyMetrics() {
    final box = Hive.box(bodyMetricsBoxName);
    if (box.isEmpty) return null;
    final list = box.values.map((e) => BodyMetrics.fromMap(e as Map)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.first;
  }

  List<BodyMetrics> getBodyMetricsHistory() {
    final box = Hive.box(bodyMetricsBoxName);
    final list = box.values.map((e) => BodyMetrics.fromMap(e as Map)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  String _dayKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}

// Providers
final activityTrackerServiceProvider = Provider((ref) => ActivityTrackerService());

final todayActivityProvider = FutureProvider<UserActivityLog?>((ref) async {
  final service = ref.watch(activityTrackerServiceProvider);
  return service.getTodayActivity();
});

final activityHistoryProvider = FutureProvider<List<UserActivityLog>>((ref) async {
  final service = ref.watch(activityTrackerServiceProvider);
  return service.getActivityHistory();
});

final todayNutritionProvider = FutureProvider<List<NutritionLog>>((ref) async {
  final service = ref.watch(activityTrackerServiceProvider);
  return service.getDailyNutrition(DateTime.now());
});

final sleepHistoryProvider = FutureProvider<List<UserSleepLog>>((ref) async {
  final service = ref.watch(activityTrackerServiceProvider);
  return service.getSleepHistory();
});

final todayHydrationProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(activityTrackerServiceProvider);
  return service.getTodayHydration();
});

final hydrationHistoryProvider = FutureProvider<List<UserHydrationLog>>((ref) async {
  final service = ref.watch(activityTrackerServiceProvider);
  return service.getHydrationHistory();
});

final latestBodyMetricsProvider = FutureProvider<BodyMetrics?>((ref) async {
  final service = ref.watch(activityTrackerServiceProvider);
  return service.getLatestBodyMetrics();
});
