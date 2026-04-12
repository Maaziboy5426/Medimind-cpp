class ActivityTrackerEngine {
  static double calculateBMI(double heightCm, double weightKg) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static String getBMIStatus(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  static double calculateSleepDuration(DateTime start, DateTime end) {
    return end.difference(start).inMinutes / 60.0;
  }

  static String getSleepQuality(double hours) {
    if (hours >= 7) return 'Good';
    if (hours >= 6) return 'Fair';
    return 'Poor';
  }

  static Map<String, double> estimateSleepStages(double totalHours) {
    // Basic clinical averages: 20-25% REM, 15-20% Deep
    return {
      'rem': totalHours * 0.22,
      'deep': totalHours * 0.18,
      'light': totalHours * 0.60,
    };
  }

  static int calculateCaloriesFromSteps(int steps) {
    // Rough estimate: 0.04 calories per step
    return (steps * 0.04).round();
  }

  static double calculateDistanceKm(int steps) {
    // Rough estimate: 0.8 meters per step
    return (steps * 0.0008);
  }
}
