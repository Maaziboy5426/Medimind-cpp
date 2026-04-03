import '../models/mental_health_models.dart';

class MentalHealthEngine {
  static double calculateWellnessScore({
    required int moodScore, // 1-5
    required double sleepHours,
    required int stressScore, // 0-100
    required int activityLevel, // 1-10
    required int journalSentiment, // -50 to 50 or similar
  }) {
    // WellnessScore = 
    // (0.30 * moodScoreWeighted) +
    // (0.25 * sleepScore) +
    // (0.20 * (100 - stressScore)) +
    // (0.15 * activityScore) +
    // (0.10 * journalSentimentNormalized)

    // Normalize mood score (1-5 to 0-100)
    final moodWeighted = (moodScore - 1) * 25.0;

    // Normalize sleep score (0-8+ to 0-100)
    final sleepScore = (sleepHours >= 8 ? 100.0 : (sleepHours / 8.0) * 100.0);

    // Normalize activity level (1-10 to 0-100)
    final activityScore = (activityLevel / 10.0) * 100.0;

    // Normalize journal sentiment (-10 to 10 to 0-100)
    final sentimentNormalized = ((journalSentiment + 10) / 20.0) * 100.0;

    double score = (0.30 * moodWeighted) +
        (0.25 * sleepScore) +
        (0.20 * (100 - stressScore)) +
        (0.15 * activityScore) +
        (0.10 * sentimentNormalized);

    return score.clamp(0.0, 100.0);
  }

  static int calculateStressScore({
    required double sleepHours,
    required int moodScore, // 1-5
    required int activityLevel, // 1-10
    required int hydrationLevel, // 1-10
  }) {
    int stress = 50; // Base stress

    if (sleepHours < 6) stress += 20;
    if (moodScore <= 2) stress += 20;
    if (activityLevel < 4) stress += 10;
    if (hydrationLevel < 4) stress += 10;
    
    // Bonuses to reduce stress
    if (sleepHours >= 8) stress -= 10;
    if (moodScore >= 4) stress -= 10;

    return stress.clamp(0, 100);
  }

  static int analyzeSentiment(String text) {
    int score = 0;
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    final positiveWords = ['happy', 'calm', 'good', 'great', 'content', 'relaxed', 'peaceful', 'joy', 'excited', 'positive'];
    final negativeWords = ['stressed', 'angry', 'sad', 'tired', 'bad', 'anxious', 'depressed', 'worried', 'fatigue', 'negative'];

    for (var word in words) {
      if (positiveWords.contains(word)) score += 2;
      if (negativeWords.contains(word)) score -= 2;
    }

    return score.clamp(-10, 10);
  }

  static List<String> generateInsights({
    required int stressScore,
    required List<MoodLog> recentMoods,
    required double sleepHours,
  }) {
    List<String> insights = [];

    if (stressScore > 70) {
      insights.add("Your stress score is quite high. Try a breathing exercise.");
    }

    if (recentMoods.length >= 3) {
      bool dropping = true;
      for (int i = 0; i < recentMoods.length - 1; i++) {
        int s1 = _moodToScore(recentMoods[i].moodLabel);
        int s2 = _moodToScore(recentMoods[i+1].moodLabel);
        if (s1 >= s2) {
          dropping = false;
          break;
        }
      }
      if (dropping) {
        insights.add("Your mood seems to be on a downward trend. Consider journaling your thoughts.");
      }
    }

    if (sleepHours < 5) {
      insights.add("You've been getting very little sleep. You may be experiencing fatigue.");
    }

    if (insights.isEmpty) {
      insights.add("You're doing great! Keep maintaining your healthy habits.");
    }

    return insights;
  }

  static int _moodToScore(String label) {
    switch (label.toLowerCase()) {
      case 'happy': return 5;
      case 'calm': return 4;
      case 'neutral': return 3;
      case 'stressed': return 2;
      case 'depressed': return 1;
      case 'anxious': return 2;
      case 'sad': return 1;
      case 'angry': return 2;
      default: return 3;
    }
  }
}
