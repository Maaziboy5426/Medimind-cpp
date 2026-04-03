import 'dart:convert';

class PhysicalHealthMetric {
  final DateTime date;
  final double weight;
  final double height;
  final double bmi;
  final String bloodPressure;
  final int bloodSugar;
  final int cholesterol;
  final int activityLevel; // 1-10
  final double sleepHours;
  final int hydration; // glasses or ml

  PhysicalHealthMetric({
    required this.date,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bloodPressure,
    required this.bloodSugar,
    required this.cholesterol,
    required this.activityLevel,
    required this.sleepHours,
    required this.hydration,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'bloodPressure': bloodPressure,
      'bloodSugar': bloodSugar,
      'cholesterol': cholesterol,
      'activityLevel': activityLevel,
      'sleepHours': sleepHours,
      'hydration': hydration,
    };
  }

  factory PhysicalHealthMetric.fromMap(Map<dynamic, dynamic> map) {
    return PhysicalHealthMetric(
      date: DateTime.parse(map['date']),
      weight: (map['weight'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
      bmi: (map['bmi'] ?? 0.0).toDouble(),
      bloodPressure: map['bloodPressure'] ?? '',
      bloodSugar: map['bloodSugar'] ?? 0,
      cholesterol: map['cholesterol'] ?? 0,
      activityLevel: map['activityLevel'] ?? 0,
      sleepHours: (map['sleepHours'] ?? 0.0).toDouble(),
      hydration: map['hydration'] ?? 0,
    );
  }
}

class SymptomLog {
  final DateTime date;
  final List<String> symptoms;
  final String severity;
  final List<String> possibleConditions;

  SymptomLog({
    required this.date,
    required this.symptoms,
    required this.severity,
    required this.possibleConditions,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'symptoms': symptoms,
      'severity': severity,
      'possibleConditions': possibleConditions,
    };
  }

  factory SymptomLog.fromMap(Map<dynamic, dynamic> map) {
    return SymptomLog(
      date: DateTime.parse(map['date']),
      symptoms: List<String>.from(map['symptoms'] ?? []),
      severity: map['severity'] ?? '',
      possibleConditions: List<String>.from(map['possibleConditions'] ?? []),
    );
  }
}

class RiskPrediction {
  final DateTime date;
  final double diabetesRisk;
  final double heartRisk;
  final double hypertensionRisk;
  final double cancerRisk;

  RiskPrediction({
    required this.date,
    required this.diabetesRisk,
    required this.heartRisk,
    required this.hypertensionRisk,
    required this.cancerRisk,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'diabetesRisk': diabetesRisk,
      'heartRisk': heartRisk,
      'hypertensionRisk': hypertensionRisk,
      'cancerRisk': cancerRisk,
    };
  }

  factory RiskPrediction.fromMap(Map<dynamic, dynamic> map) {
    return RiskPrediction(
      date: DateTime.parse(map['date']),
      diabetesRisk: (map['diabetesRisk'] ?? 0.0).toDouble(),
      heartRisk: (map['heartRisk'] ?? 0.0).toDouble(),
      hypertensionRisk: (map['hypertensionRisk'] ?? 0.0).toDouble(),
      cancerRisk: (map['cancerRisk'] ?? 0.0).toDouble(),
    );
  }
}

class ChronicDiseaseLog {
  final DateTime date;
  final String bloodPressure;
  final int bloodSugar;
  final int cholesterol;
  final String notes;

  ChronicDiseaseLog({
    required this.date,
    required this.bloodPressure,
    required this.bloodSugar,
    required this.cholesterol,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'bloodPressure': bloodPressure,
      'bloodSugar': bloodSugar,
      'cholesterol': cholesterol,
      'notes': notes,
    };
  }

  factory ChronicDiseaseLog.fromMap(Map<dynamic, dynamic> map) {
    return ChronicDiseaseLog(
      date: DateTime.parse(map['date']),
      bloodPressure: map['bloodPressure'] ?? '',
      bloodSugar: map['bloodSugar'] ?? 0,
      cholesterol: map['cholesterol'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }
}

class HealthScore {
  final DateTime date;
  final double score;
  final double activityScore;
  final double sleepScore;
  final double nutritionScore;
  final double hydrationScore;

  HealthScore({
    required this.date,
    required this.score,
    required this.activityScore,
    required this.sleepScore,
    required this.nutritionScore,
    required this.hydrationScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'score': score,
      'activityScore': activityScore,
      'sleepScore': sleepScore,
      'nutritionScore': nutritionScore,
      'hydrationScore': hydrationScore,
    };
  }

  factory HealthScore.fromMap(Map<dynamic, dynamic> map) {
    return HealthScore(
      date: DateTime.parse(map['date']),
      score: (map['score'] ?? 0.0).toDouble(),
      activityScore: (map['activityScore'] ?? 0.0).toDouble(),
      sleepScore: (map['sleepScore'] ?? 0.0).toDouble(),
      nutritionScore: (map['nutritionScore'] ?? 0.0).toDouble(),
      hydrationScore: (map['hydrationScore'] ?? 0.0).toDouble(),
    );
  }
}
enum RiskLevel { low, moderate, high }

class DiseaseRisk {
  final String name;
  final RiskLevel level;
  final int percentage;

  DiseaseRisk({required this.name, required this.level, required this.percentage});
}
