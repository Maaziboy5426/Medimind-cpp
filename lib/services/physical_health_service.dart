import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/physical_health_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhysicalHealthService {
  static const String healthMetricsBoxName = 'healthMetricsBox';
  static const String symptomLogsBoxName = 'symptomLogsBox';
  static const String riskPredictionsBoxName = 'riskPredictionsBox';
  static const String chronicDiseaseLogsBoxName = 'chronicDiseaseLogsBox';
  static const String healthScoreHistoryBoxName = 'healthScoreHistoryBox';

  static Database? _database;

  static Future<void> init() async {
    // Hive Initialization
    await Hive.openBox(healthMetricsBoxName);
    await Hive.openBox(symptomLogsBoxName);
    await Hive.openBox(riskPredictionsBoxName);
    await Hive.openBox(chronicDiseaseLogsBoxName);
    await Hive.openBox(healthScoreHistoryBoxName);

    // SQLite Initialization for "health records"
    if (!kIsWeb) {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'health_records.db'),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE health_records(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, weight REAL, height REAL, bmi REAL, bp TEXT, sugar INTEGER, cholesterol INTEGER)',
          );
        },
        version: 1,
      );
    }
  }

  // --- SQLite Records ---
  Future<void> saveHealthRecord(PhysicalHealthMetric metric) async {
    await _database?.insert(
      'health_records',
      {
        'date': metric.date.toIso8601String(),
        'weight': metric.weight,
        'height': metric.height,
        'bmi': metric.bmi,
        'bp': metric.bloodPressure,
        'sugar': metric.bloodSugar,
        'cholesterol': metric.cholesterol,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Also save to Hive for consistency as requested
    await saveHealthMetric(metric);
  }

  // --- Hive Methods ---

  Future<void> saveHealthMetric(PhysicalHealthMetric metric) async {
    final box = Hive.box(healthMetricsBoxName);
    await box.add(metric.toMap());
  }

  List<PhysicalHealthMetric> getHealthMetrics() {
    final box = Hive.box(healthMetricsBoxName);
    return box.values.map((e) => PhysicalHealthMetric.fromMap(e as Map)).toList();
  }

  Future<void> saveSymptomLog(SymptomLog log) async {
    final box = Hive.box(symptomLogsBoxName);
    await box.add(log.toMap());
  }

  List<SymptomLog> getSymptomHistory() {
    final box = Hive.box(symptomLogsBoxName);
    return box.values.map((e) => SymptomLog.fromMap(e as Map)).toList();
  }

  Future<void> saveRiskPrediction(RiskPrediction prediction) async {
    final box = Hive.box(riskPredictionsBoxName);
    await box.add(prediction.toMap());
  }

  List<RiskPrediction> getRiskHistory() {
    final box = Hive.box(riskPredictionsBoxName);
    return box.values.map((e) => RiskPrediction.fromMap(e as Map)).toList();
  }

  Future<void> saveChronicLog(ChronicDiseaseLog log) async {
    final box = Hive.box(chronicDiseaseLogsBoxName);
    await box.add(log.toMap());
  }

  List<ChronicDiseaseLog> getChronicHistory() {
    final box = Hive.box(chronicDiseaseLogsBoxName);
    return box.values.map((e) => ChronicDiseaseLog.fromMap(e as Map)).toList();
  }

  Future<void> saveHealthScore(HealthScore score) async {
    final box = Hive.box(healthScoreHistoryBoxName);
    await box.add(score.toMap());
  }

  List<HealthScore> getHealthScoreHistory() {
    final box = Hive.box(healthScoreHistoryBoxName);
    final list = box.values.map((e) => HealthScore.fromMap(e as Map)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}

// Providers
final physicalHealthServiceProvider = Provider((ref) => PhysicalHealthService());

final healthMetricsProvider = FutureProvider<List<PhysicalHealthMetric>>((ref) async {
  final service = ref.watch(physicalHealthServiceProvider);
  return service.getHealthMetrics();
});

final symptomHistoryProvider = FutureProvider<List<SymptomLog>>((ref) async {
  final service = ref.watch(physicalHealthServiceProvider);
  return service.getSymptomHistory();
});

final riskPredictionsProvider = FutureProvider<List<RiskPrediction>>((ref) async {
  final service = ref.watch(physicalHealthServiceProvider);
  return service.getRiskHistory();
});

final chronicEntriesProvider = FutureProvider<List<ChronicDiseaseLog>>((ref) async {
  final service = ref.watch(physicalHealthServiceProvider);
  return service.getChronicHistory();
});

final healthScoreHistoryProvider = FutureProvider<List<HealthScore>>((ref) async {
  final service = ref.watch(physicalHealthServiceProvider);
  return service.getHealthScoreHistory();
});

final currentHealthScoreProvider = FutureProvider<HealthScore?>((ref) async {
  final service = ref.watch(physicalHealthServiceProvider);
  final history = service.getHealthScoreHistory();
  return history.isNotEmpty ? history.first : null;
});
