import '../models/mood_models.dart';

/// Returns wellness suggestions based on mood result.
class MentalWellnessSuggestionsEngine {
  static List<String> getSuggestions(MoodResult result) {
    final list = <String>[];
    if (result.stressLevel >= 50) {
      list.addAll([
        'Try a 2-minute breathing exercise to lower stress.',
        'Step away from screens for a short walk.',
      ]);
    }
    if (result.anxietyLevel >= 50) {
      list.addAll([
        'Ground yourself: name 5 things you can see, 4 you can hear.',
        'Schedule a short break; even 5 minutes helps.',
      ]);
    }
    switch (result.moodType) {
      case MoodType.anxious:
      case MoodType.stressed:
        list.add('Consider the breathing exercise below when you have a moment.');
        break;
      case MoodType.sad:
        list.add('Reach out to someone you trust, or write down how you feel.');
        break;
      case MoodType.angry:
        list.add('Pause and take a few deep breaths before responding.');
        break;
      case MoodType.calm:
      case MoodType.happy:
        list.add('Keep doing what supports your wellbeing today.');
        break;
      case MoodType.neutral:
        list.add('A short walk or stretch can boost mood and energy.');
        break;
    }
    if (list.length < 3) {
      list.add('Stay hydrated and try to get enough sleep tonight.');
    }
    return list.take(4).toList();
  }
}
