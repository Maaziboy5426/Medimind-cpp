import 'package:fl_chart/fl_chart.dart';

class AnalyticsSummary {
  final List<FlSpot> wellnessTrend;
  final double activityBreakdown;
  final double sleepBreakdown;
  final double hydrationBreakdown;
  final double nutritionBreakdown;
  final int totalSteps;
  final double avgSleep;
  final int caloriesBurned;
  final double hydrationScore;
  final List<FlSpot> moodTrend;
  final List<String> aiInsights;

  AnalyticsSummary({
    required this.wellnessTrend,
    required this.activityBreakdown,
    required this.sleepBreakdown,
    required this.hydrationBreakdown,
    required this.nutritionBreakdown,
    required this.totalSteps,
    required this.avgSleep,
    required this.caloriesBurned,
    required this.hydrationScore,
    required this.moodTrend,
    required this.aiInsights,
  });

  factory AnalyticsSummary.empty() {
    return AnalyticsSummary(
      wellnessTrend: [],
      activityBreakdown: 0,
      sleepBreakdown: 0,
      hydrationBreakdown: 0,
      nutritionBreakdown: 0,
      totalSteps: 0,
      avgSleep: 0,
      caloriesBurned: 0,
      hydrationScore: 0,
      moodTrend: [],
      aiInsights: [],
    );
  }
}
