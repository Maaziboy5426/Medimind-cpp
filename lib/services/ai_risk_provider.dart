import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_provider.dart';
import 'base_providers.dart';
import 'package:medmind/services/activity_tracker_service.dart';
import 'package:medmind/services/profile_service.dart';
import 'package:medmind/services/settings_service.dart';

final diseaseRiskProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final aiService = ref.watch(aiEngineServiceProvider);
  final user = ref.watch(userProfileProvider).value;
  final activityAsync = ref.watch(todayActivityProvider);
  final metricsAsync = ref.watch(latestBodyMetricsProvider);

  if (user == null) return null;
  final activity = activityAsync.value;
  final metrics = metricsAsync.value;

  final currentBmi = metrics?.bmi ?? user.bmi;

  // Calculate lifestyle score
  int lifestyle = 5; // mid
  if (user.activityLevel == 'Very Active' || user.activityLevel == 'Super Active') lifestyle += 2;
  if (user.activityLevel == 'Lightly Active' || user.activityLevel == 'Sedentary') lifestyle -= 2;
  if (user.smokingStatus) lifestyle -= 2;
  if (user.alcoholConsumption) lifestyle -= 1;
  lifestyle = lifestyle.clamp(1, 10);

  bool familyHistory = false; // Add to model if needed later 

  return aiService.predictDiseaseRisks(
    age: metrics?.age ?? user.age,
    bmi: currentBmi,
    lifestyleScore: lifestyle,
    familyHistory: familyHistory,
    symptoms: const [],
    sleepHours: user.sleepAverage,
    activitySteps: activity?.steps ?? 0,
  );
});

final cancerRiskProvider = FutureProvider<double?>((ref) async {
  final aiService = ref.watch(aiEngineServiceProvider);
  final user = ref.watch(userProfileProvider).value;
  final metricsAsync = ref.watch(latestBodyMetricsProvider);

  if (user == null) return null;
  final metrics = metricsAsync.value;

  bool famHistory = false;

  return aiService.getCancerRisk(
      age: metrics?.age ?? user.age,
      bmi: metrics?.bmi ?? user.bmi,
      familyHistory: famHistory,
      smoking: user.smokingStatus,
      alcohol: user.alcoholConsumption,
  );
});

final aiRecommendationsProvider = FutureProvider<List<String>>((ref) async {
  final aiService = ref.watch(aiEngineServiceProvider);
  final user = ref.watch(userProfileProvider).value;
  final activityAsync = ref.watch(todayActivityProvider);
  final hydrationAsync = ref.watch(todayHydrationProvider);
  final settings = ref.watch(appSettingsProvider); // Use Settings for water intake fallback
  
  if (user == null) return [];
  final activity = activityAsync.value;
  final hydration = hydrationAsync.value ?? (settings.waterIntakeGoal * 1000).toInt();

  return aiService.getRecommendations(
    sleepHours: user.sleepAverage,
    activitySteps: activity?.steps ?? 0,
    hydrationMl: hydration,
    mood: 'Calm', // Could be dynamic if we fetch last mood
  );
});
