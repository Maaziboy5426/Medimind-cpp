import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AiEngineService {
  final String baseUrl;

  AiEngineService({this.baseUrl = 'http://localhost:8000'});

  Future<Map<String, dynamic>?> predictMood(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict-mood'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('AI Engine Error (predictMood): $e');
    }
    return null;
  }

  Future<double?> getWellnessScore({
    required double sleepHours,
    required String moodLabel,
    required int activitySteps,
    required int hydrationMl,
    required int heartRate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/health-score'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sleep_hours': sleepHours,
          'mood_label': moodLabel,
          'activity_steps': activitySteps,
          'hydration_ml': hydrationMl,
          'heart_rate': heartRate,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['wellness_score'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('AI Engine Error (health-score): $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> predictStress({
    required double sleepHours,
    required String moodLabel,
    required int activitySteps,
    required int hydrationMl,
    required int heartRate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict-stress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sleep_hours': sleepHours,
          'mood_label': moodLabel,
          'activity_steps': activitySteps,
          'hydration_ml': hydrationMl,
          'heart_rate': heartRate,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('AI Engine Error (predict-stress): $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> predictDiseaseRisks({
    required int age,
    required double bmi,
    required int lifestyleScore,
    required bool familyHistory,
    required List<String> symptoms,
    required double sleepHours,
    required int activitySteps,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict-disease'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'age': age,
          'bmi': bmi,
          'lifestyle_score': lifestyleScore,
          'family_history': familyHistory,
          'symptoms': symptoms,
          'sleep_hours': sleepHours,
          'activity_steps': activitySteps,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('AI Engine Error (predict-disease): $e');
    }
    return null;
  }

  Future<List<String>> checkSymptoms(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/symptom-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['top_conditions']);
      }
    } catch (e) {
      debugPrint('AI Engine Error (symptom-check): $e');
    }
    return [];
  }

  Future<List<String>> getRecommendations({
    required double sleepHours,
    required int activitySteps,
    required int hydrationMl,
    required String mood,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sleep_hours': sleepHours,
          'activity_steps': activitySteps,
          'hydration_ml': hydrationMl,
          'mood': mood,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['recommendations']);
      }
      return [];
    } catch (e) {
      debugPrint('AI Engine Error (recommendations): $e');
    }
    return [];
  }

  Future<double?> getCancerRisk({
    required bool smoking,
    required bool alcohol,
    required double bmi,
    required bool familyHistory,
    required int age,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cancer-risk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'smoking': smoking,
          'alcohol': alcohol,
          'bmi': bmi,
          'family_history': familyHistory,
          'age': age,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['risk_score'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('AI Engine Error (cancer-risk): $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> detectAnomaly(String metricName, List<double> values) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/detect-anomaly'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'metric_name': metricName, 'values': values}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('AI Engine Error (detect-anomaly): $e');
    }
    return null;
  }

  Future<double?> getMedicationRisk({
    required double adherenceRate,
    required int totalMeds,
    required int overdueCount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/medication-risk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adherence_rate': adherenceRate,
          'total_meds': totalMeds,
          'overdue_count': overdueCount,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['risk_score'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('AI Engine Error (medication-risk): $e');
    }
    return null;
  }
}
