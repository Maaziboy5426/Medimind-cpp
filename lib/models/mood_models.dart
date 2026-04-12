/// Mood classification result from mock NLP.
class MoodResult {
  const MoodResult({
    required this.moodType,
    required this.confidencePercent,
    required this.stressLevel,
    required this.anxietyLevel,
  });

  final MoodType moodType;
  final int confidencePercent;
  final int stressLevel;   // 0-100
  final int anxietyLevel; // 0-100

  MoodResult copyWith({
    MoodType? moodType,
    int? confidencePercent,
    int? stressLevel,
    int? anxietyLevel,
  }) {
    return MoodResult(
      moodType: moodType ?? this.moodType,
      confidencePercent: confidencePercent ?? this.confidencePercent,
      stressLevel: stressLevel ?? this.stressLevel,
      anxietyLevel: anxietyLevel ?? this.anxietyLevel,
    );
  }
}

enum MoodType {
  happy,
  calm,
  neutral,
  anxious,
  sad,
  stressed,
  angry,
}

extension MoodTypeX on MoodType {
  String get label {
    switch (this) {
      case MoodType.happy: return 'Happy';
      case MoodType.calm: return 'Calm';
      case MoodType.neutral: return 'Neutral';
      case MoodType.anxious: return 'Anxious';
      case MoodType.sad: return 'Sad';
      case MoodType.stressed: return 'Stressed';
      case MoodType.angry: return 'Angry';
    }
  }

  String get emoji {
    switch (this) {
      case MoodType.happy: return '😊';
      case MoodType.calm: return '😌';
      case MoodType.neutral: return '😐';
      case MoodType.anxious: return '😰';
      case MoodType.sad: return '😢';
      case MoodType.stressed: return '😤';
      case MoodType.angry: return '😠';
    }
  }
}

/// Persisted mood entry (input + result + timestamp).
class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.inputText,
    required this.result,
    required this.timestamp,
  });

  final String id;
  final String inputText;
  final MoodResult result;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'inputText': inputText,
        'moodType': result.moodType.index,
        'confidencePercent': result.confidencePercent,
        'stressLevel': result.stressLevel,
        'anxietyLevel': result.anxietyLevel,
        'timestamp': timestamp.toIso8601String(),
      };

  static MoodEntry fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      inputText: json['inputText'] as String,
      result: MoodResult(
        moodType: MoodType.values[json['moodType'] as int],
        confidencePercent: json['confidencePercent'] as int,
        stressLevel: json['stressLevel'] as int,
        anxietyLevel: json['anxietyLevel'] as int,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
