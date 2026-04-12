import '../models/physical_health_models.dart';

class PhysicalHealthEngine {
  
  // --- Feature 1 & 4: Risk Calculations ---
  
  static RiskPrediction calculateAllRisks({
    required int age,
    required double bmi,
    required int activityLevel, // 1-10
    required bool familyHistory,
    required double sleepHours,
    required bool smokingStatus,
    required bool alcoholConsumption,
  }) {
    double diabetesRisk = 20.0;
    double heartRisk = 20.0;
    double hypertensionRisk = 20.0;
    double cancerRisk = 0.0;

    // Diabetes Risk logic
    if (bmi > 30) diabetesRisk += 30;
    if (age > 45) diabetesRisk += 20;
    if (activityLevel < 4) diabetesRisk += 15;

    // Heart Disease Risk logic
    if (activityLevel < 4) heartRisk += 30;
    if (smokingStatus) heartRisk += 25;
    if (bmi > 30) heartRisk += 15;

    // Hypertension Risk logic
    if (sleepHours < 6) hypertensionRisk += 30;
    if (bmi > 30) hypertensionRisk += 20;
    if (activityLevel < 4) hypertensionRisk += 10;

    // Cancer Risk logic (Feature 4 - Weighted Scoring)
    if (smokingStatus) cancerRisk += 30;
    if (familyHistory) cancerRisk += 20;
    if (bmi > 30) cancerRisk += 10;
    if (alcoholConsumption) cancerRisk += 10;
    if (age > 50) cancerRisk += 20;
    if (activityLevel < 4) cancerRisk += 10;

    return RiskPrediction(
      date: DateTime.now(),
      diabetesRisk: diabetesRisk.clamp(0, 100),
      heartRisk: heartRisk.clamp(0, 100),
      hypertensionRisk: hypertensionRisk.clamp(0, 100),
      cancerRisk: cancerRisk.clamp(0, 100),
    );
  }

  // --- Feature 2 & 5: Symptom Checker ---

  static final Map<String, List<String>> _symptomConditionMap = {
    "fever,cough": ["Flu", "Viral Infection", "Common Cold"],
    "headache,fatigue": ["Migraine", "Stress", "Tension Headache"],
    "chest pain,shortness of breath": ["Cardiac risk", "Angina", "Panic Attack"],
    "fever,fatigue": ["Viral Infection", "Mononucleosis", "Flu"],
    "cough,shortness of breath": ["Bronchitis", "Asthma", "Pneumonia"],
  };

  static Map<String, dynamic> checkSymptoms(List<String> symptoms, String severity) {
    symptoms.sort();
    String key = symptoms.join(',').toLowerCase();
    
    // Find partial matches if exact doesn't exist
    List<String> conditions = [];
    for (var entry in _symptomConditionMap.entries) {
      int matchCount = 0;
      final keys = entry.key.split(',');
      for (var s in symptoms) {
        if (keys.contains(s.toLowerCase())) matchCount++;
      }
      if (matchCount >= 1) {
        conditions.addAll(entry.value);
      }
    }
    
    conditions = conditions.toSet().toList(); // Remove duplicates
    if (conditions.length > 3) conditions = conditions.sublist(0, 3);
    if (conditions.isEmpty) conditions = ["Consult a professional for diagnosis"];

    String riskLevel = "Low";
    String suggestion = "Home care";

    if (severity.toLowerCase() == "high") {
      riskLevel = "High";
      suggestion = "Urgent care";
    } else if (severity.toLowerCase() == "medium" || conditions.contains("Cardiac risk")) {
      riskLevel = "Moderate";
      suggestion = "Consult doctor";
    }

    return {
      "conditions": conditions,
      "riskLevel": riskLevel,
      "suggestion": suggestion,
    };
  }

  // --- Feature 6: Health Score ---

  static HealthScore calculateHealthScore({
    required double bmi,
    required int activityLevel,
    required double sleepHours,
    required int hydration,
    required String bp, // "120/80"
    required int sugar,
    required int cholesterol,
  }) {
    // BMI score (Ideal 18.5-24.9)
    double bmiScore = 100;
    if (bmi < 18.5 || bmi > 25) bmiScore = 80;
    if (bmi > 30 || bmi < 16) bmiScore = 50;

    // Activity score (1-10)
    double actScore = activityLevel * 10.0;

    // Sleep score (Ideal 7-9 hours)
    double slpScore = (sleepHours >= 7 && sleepHours <= 9) ? 100 : (sleepHours / 8) * 100;
    slpScore = slpScore.clamp(0, 100);

    // Hydration score (Ideal 8-10 glasses)
    double hydScore = (hydration / 10.0) * 100.0;
    hydScore = hydScore.clamp(0, 100);

    // Chronic Health Score
    double chrScore = 100;
    try {
      final parts = bp.split('/');
      if (parts.length == 2) {
        int sys = int.parse(parts[0]);
        int dia = int.parse(parts[1]);
        if (sys > 140 || dia > 90) chrScore -= 20;
        if (sys > 160 || dia > 100) chrScore -= 20;
      }
    } catch (_) {}
    if (sugar > 126) chrScore -= 20;
    if (sugar > 200) chrScore -= 20;
    if (cholesterol > 200) chrScore -= 20;
    chrScore = chrScore.clamp(0, 100);

    double totalScore = (0.25 * bmiScore) +
        (0.25 * actScore) +
        (0.20 * slpScore) +
        (0.15 * hydScore) +
        (0.15 * chrScore);

    return HealthScore(
      date: DateTime.now(),
      score: totalScore.clamp(0, 100),
      activityScore: actScore,
      sleepScore: slpScore,
      nutritionScore: 80.0, // Default for now
      hydrationScore: hydScore,
    );
  }

  // --- Feature 9: Prevention Tips ---

  static List<String> generatePreventionTips({
    required double bmi,
    required String bp,
    required int sugar,
    required int activityLevel,
  }) {
    List<String> tips = [];

    if (bmi > 30) tips.add("Focus on weight management and portion control.");
    if (activityLevel < 4) tips.add("Suggest daily walking for at least 30 minutes.");
    
    try {
      final sys = int.parse(bp.split('/').first);
      if (sys > 140) tips.add("Reduce sodium intake to manage high blood pressure.");
    } catch (_) {}

    if (sugar > 126) tips.add("Monitor sugar levels closely and consult a nutritionist.");
    
    if (tips.isEmpty) {
      tips.add("Continue your healthy lifestyle and regular checkups.");
    }

    return tips;
  }
}
