import 'dart:math';

import '../models/mood_models.dart';

/// Mock NLP: keyword + length based mood classification.
class MockNlpMoodService {
  static final _rng = Random();

  static MoodResult classify(String text) {
    if (text.trim().isEmpty) {
      return MoodResult(
        moodType: MoodType.neutral,
        confidencePercent: 50,
        stressLevel: 50,
        anxietyLevel: 50,
      );
    }
    final lower = text.trim().toLowerCase();
    final words = lower.split(RegExp(r'\s+'));
    int happyScore = 0, calmScore = 0, anxiousScore = 0, sadScore = 0, stressedScore = 0, angryScore = 0;

    const happyWords = ['happy', 'great', 'good', 'awesome', 'love', 'joy', 'excited', 'wonderful', 'amazing', 'fine', 'ok', 'okay', 'better'];
    const calmWords = ['calm', 'peaceful', 'relaxed', 'chill', 'serene', 'content', 'peace'];
    const anxiousWords = ['anxious', 'worried', 'nervous', 'scared', 'fear', 'panic', 'overwhelmed', 'stressed', 'stress'];
    const sadWords = ['sad', 'down', 'depressed', 'lonely', 'tired', 'exhausted', 'hopeless', 'cry', 'crying'];
    const stressedWords = ['stressed', 'pressure', 'busy', 'deadline', 'too much', 'cant', 'can\'t', 'overwhelmed'];
    const angryWords = ['angry', 'mad', 'frustrated', 'annoyed', 'irritated', 'hate', 'angry'];

    for (final w in words) {
      if (happyWords.any((e) => w.contains(e))) happyScore++;
      if (calmWords.any((e) => w.contains(e))) calmScore++;
      if (anxiousWords.any((e) => w.contains(e))) anxiousScore++;
      if (sadWords.any((e) => w.contains(e))) sadScore++;
      if (stressedWords.any((e) => w.contains(e))) stressedScore++;
      if (angryWords.any((e) => w.contains(e))) angryScore++;
    }

    MoodType type;
    if (happyScore > 0 && happyScore >= calmScore && happyScore >= sadScore) type = MoodType.happy;
    else if (calmScore > 0 && calmScore >= anxiousScore) type = MoodType.calm;
    else if (angryScore > 0 && angryScore >= stressedScore) type = MoodType.angry;
    else if (stressedScore > 0) type = MoodType.stressed;
    else if (anxiousScore > 0) type = MoodType.anxious;
    else if (sadScore > 0) type = MoodType.sad;
    else type = MoodType.neutral;

    final confidence = (65 + _rng.nextInt(32)).clamp(65, 98);
    final stress = _stressFromType(type, stressedScore, words.length);
    final anxiety = _anxietyFromType(type, anxiousScore, words.length);

    return MoodResult(
      moodType: type,
      confidencePercent: confidence,
      stressLevel: stress,
      anxietyLevel: anxiety,
    );
  }

  static int _stressFromType(MoodType type, int stressedScore, int wordCount) {
    final base = switch (type) {
      MoodType.stressed => 60 + _rng.nextInt(35),
      MoodType.anxious => 45 + _rng.nextInt(35),
      MoodType.angry => 55 + _rng.nextInt(30),
      MoodType.sad => 40 + _rng.nextInt(35),
      MoodType.happy => 5 + _rng.nextInt(25),
      MoodType.calm => 5 + _rng.nextInt(20),
      MoodType.neutral => 25 + _rng.nextInt(35),
    };
    return (base + stressedScore * 3).clamp(0, 100);
  }

  static int _anxietyFromType(MoodType type, int anxiousScore, int wordCount) {
    final base = switch (type) {
      MoodType.anxious => 65 + _rng.nextInt(30),
      MoodType.stressed => 45 + _rng.nextInt(35),
      MoodType.sad => 40 + _rng.nextInt(35),
      MoodType.angry => 35 + _rng.nextInt(30),
      MoodType.happy => 5 + _rng.nextInt(20),
      MoodType.calm => 5 + _rng.nextInt(15),
      MoodType.neutral => 20 + _rng.nextInt(35),
    };
    return (base + anxiousScore * 3).clamp(0, 100);
  }
}
