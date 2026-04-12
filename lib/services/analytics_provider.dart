import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:medmind/models/analytics_models.dart';
import 'package:medmind/services/activity_tracker_service.dart';
import 'package:medmind/services/storage_provider.dart';
import 'package:medmind/services/settings_service.dart';
import 'package:medmind/models/activity_tracker_models.dart';
import 'package:medmind/models/mood_models.dart';
import 'dart:math';

final analyticsRangeProvider = StateProvider<int>((ref) => 7);

final _triggerDepProvider = Provider<void>((ref) {
  // Used to optionally force refresh if stream changes
});

final analyticsSummaryProvider = Provider<AnalyticsSummary>((ref) {
  final range = ref.watch(analyticsRangeProvider);
  final settings = ref.watch(appSettingsProvider);
  final moods = ref.watch(moodHistoryProvider);

  // Note: we can't easily ref.watch Hive Streams cleanly here without nesting. 
  // However, Riverpod can watch ValueListenable from Hive.
  final tracker = ActivityTrackerService();
  
  // We can just query the boxes synchronously. 
  // For reactive updates, since the screen is an analytics screen, it tends to re-read on load. 
  // We will configure watch hooks for Hive boxes to auto trigger this provider if they change.
  
  final allActivity = tracker.getActivityHistory();
  final allSleep = tracker.getSleepHistory();
  final allHydration = tracker.getHydrationHistory();
  final nutritionBox = Hive.box(ActivityTrackerService.nutritionLogsBoxName);
  final allNutrition = nutritionBox.values.map((e) => NutritionLog.fromMap(e as Map)).toList();

  final now = DateTime.now();

  // 1. Calculate Wellness Trend (Last 7 days strictly as per diagram, or `range` days)
  List<FlSpot> wellnessTrend = [];
  List<FlSpot> moodTrend = [];
  
  double totalActivityPct = 0;
  double totalSleepPct = 0;
  double totalHydrationPct = 0;
  double totalNutritionPct = 0;

  int totalSteps = 0;
  double avgSleep = 0;
  int caloriesBurned = 0;
  double hydrationScoreSum = 0;
  int daysWithData = 0;
  
  List<String> insights = [];
  int lowSleepDays = 0;
  int lowHydrationDays = 0;

  for (int i = range - 1; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    
    // Find daily logs
    final dailyAct = allActivity.where((a) => a.date.year == d.year && a.date.month == d.month && a.date.day == d.day).toList();
    final dailySlp = allSleep.where((a) => a.date.year == d.year && a.date.month == d.month && a.date.day == d.day).toList();
    final dailyHyd = allHydration.where((a) => a.date.year == d.year && a.date.month == d.month && a.date.day == d.day).toList();
    final dailyNut = allNutrition.where((a) => a.date.year == d.year && a.date.month == d.month && a.date.day == d.day).toList();
    final dailyMood = moods.where((a) => a.timestamp.year == d.year && a.timestamp.month == d.month && a.timestamp.day == d.day).toList();

    int steps = dailyAct.fold(0, (s, a) => s + a.steps);
    int cals = dailyAct.fold(0, (s, a) => s + a.caloriesBurned);
    double sleepDur = dailySlp.fold(0.0, (s, a) => s + a.sleepDuration);
    int waterMl = dailyHyd.fold(0, (s, a) => s + a.waterMl);
    
    int moodVal = 3; // default calm
    if (dailyMood.isNotEmpty) {
      final typ = dailyMood.first.result.moodType;
      if (typ == MoodType.happy) moodVal = 4;
      else if (typ == MoodType.calm) moodVal = 3;
      else if (typ == MoodType.neutral) moodVal = 2;
      else moodVal = 1;
    }

    // Accumulate sum stats
    totalSteps += steps;
    caloriesBurned += cals;
    avgSleep += sleepDur;
    if (steps > 0 || sleepDur > 0 || waterMl > 0) daysWithData++;

    // Calculate sub-scores (0 to 100)
    double actScore = min(100.0, (steps / (settings.dailyStepGoal > 0 ? settings.dailyStepGoal : 10000)) * 100);
    double slpScore = min(100.0, (sleepDur / 8.0) * 100);
    double hydScore = min(100.0, (waterMl / ((settings.waterIntakeGoal > 0 ? settings.waterIntakeGoal : 2.5) * 1000)) * 100);
    double mntScore = (moodVal / 4.0) * 100.0;
    double medScore = 100.0; // Assume 100% adherence if not implemented fully yet

    hydrationScoreSum += hydScore;

    // AI logic tracking
    if (sleepDur > 0 && sleepDur < 6) lowSleepDays++; else lowSleepDays = 0;
    if (hydScore > 0 && hydScore < 100) lowHydrationDays++; else lowHydrationDays = 0;

    // Daily Wellness Score formula
    double wellness = (0.30 * actScore) + (0.25 * slpScore) + (0.20 * hydScore) + (0.15 * mntScore) + (0.10 * medScore);
    
    // Add points
    wellnessTrend.add(FlSpot((range - 1 - i).toDouble(), wellness));
    moodTrend.add(FlSpot((range - 1 - i).toDouble(), moodVal.toDouble()));

    // For breakdown chart
    totalActivityPct += actScore;
    totalSleepPct += slpScore;
    totalHydrationPct += hydScore;
    double nutScore = dailyNut.isNotEmpty ? 80.0 : 0; // Simple dummy nutrition representation
    totalNutritionPct += nutScore;
  }

  if (lowSleepDays >= 3) {
    insights.add("You are not getting enough sleep consistently. Try resting earlier.");
  }
  if (lowHydrationDays >= 2) {
    insights.add("Your hydration levels are dropping! Friendly reminder to drink water.");
  }
  if (wellnessTrend.isNotEmpty && wellnessTrend.last.y > 80) {
    insights.add("Fantastic! Your wellness levels are looking great this week. Keep it up!");
  } else if (insights.isEmpty) {
    insights.add("Your routines are relatively stable. Aim to hit those daily goals!");
  }

  // Activity Breakdown Proportions
  double sumBreakdown = totalActivityPct + totalSleepPct + totalHydrationPct + totalNutritionPct;
  if (sumBreakdown == 0) sumBreakdown = 1; // avoid / 0

  return AnalyticsSummary(
    wellnessTrend: wellnessTrend,
    moodTrend: moodTrend,
    activityBreakdown: (totalActivityPct / sumBreakdown) * 100,
    sleepBreakdown: (totalSleepPct / sumBreakdown) * 100,
    hydrationBreakdown: (totalHydrationPct / sumBreakdown) * 100,
    nutritionBreakdown: (totalNutritionPct / sumBreakdown) * 100,
    totalSteps: totalSteps,
    avgSleep: daysWithData > 0 ? (avgSleep / daysWithData) : 0.0,
    caloriesBurned: caloriesBurned,
    hydrationScore: daysWithData > 0 ? (hydrationScoreSum / range) : 0.0,
    aiInsights: insights,
  );
});
