import 'dart:math';

import '../models/physical_health_models.dart';

/// Mock AI: generates Low/Moderate/High risk for heart, diabetes, stress, cancer.
/// Better lifestyle factors (steps, sleep, water) tend to lower risk.
class DiseaseRiskSimulationService {
  static final _rng = Random(42);

  static List<DiseaseRisk> generate({
    int weeklyStepsAvg = 35000,
    double sleepHoursAvg = 7.0,
    int waterGlassesPerDay = 5,
  }) {
    final healthScore = _healthScore(
      steps: weeklyStepsAvg,
      sleep: sleepHoursAvg,
      water: waterGlassesPerDay,
    );
    return [
      _oneRisk('Heart disease', healthScore, 0.1),
      _oneRisk('Diabetes', healthScore, 0.2),
      _oneRisk('Stress-related illness', healthScore, -0.1),
      _oneRisk('Cancer indication', healthScore, 0.3),
    ];
  }

  static double _healthScore({
    required int steps,
    required double sleep,
    required int water,
  }) {
    final s = (steps / 50000).clamp(0.0, 1.0);
    final sl = ((sleep - 4) / 5).clamp(0.0, 1.0);
    final w = (water / 8).clamp(0.0, 1.0);
    return (s * 0.4 + sl * 0.35 + w * 0.25) + (_rng.nextDouble() * 0.2 - 0.1);
  }

  static DiseaseRisk _oneRisk(String name, double healthScore, double bias) {
    final score = (healthScore + bias).clamp(0.0, 1.0);
    RiskLevel level;
    int percentage;
    if (score >= 0.55) {
      level = RiskLevel.low;
      percentage = 15 + _rng.nextInt(20);
    } else if (score >= 0.3) {
      level = RiskLevel.moderate;
      percentage = 40 + _rng.nextInt(25);
    } else {
      level = RiskLevel.high;
      percentage = 65 + _rng.nextInt(25);
    }
    return DiseaseRisk(name: name, level: level, percentage: percentage.clamp(5, 95));
  }
}
