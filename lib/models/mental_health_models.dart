import 'dart:convert';

class MoodLog {
  final DateTime date;
  final String moodLabel;
  final int confidence;
  final String textEntry;
  final String voiceEntry;
  final int stressScore;

  MoodLog({
    required this.date,
    required this.moodLabel,
    required this.confidence,
    required this.textEntry,
    required this.voiceEntry,
    required this.stressScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'moodLabel': moodLabel,
      'confidence': confidence,
      'textEntry': textEntry,
      'voiceEntry': voiceEntry,
      'stressScore': stressScore,
    };
  }

  factory MoodLog.fromMap(Map<dynamic, dynamic> map) {
    return MoodLog(
      date: DateTime.parse(map['date']),
      moodLabel: map['moodLabel'] ?? '',
      confidence: map['confidence'] ?? 0,
      textEntry: map['textEntry'] ?? '',
      voiceEntry: map['voiceEntry'] ?? '',
      stressScore: map['stressScore'] ?? 0,
    );
  }
}

class JournalEntry {
  final DateTime date;
  final String text;
  final int sentimentScore;

  JournalEntry({
    required this.date,
    required this.text,
    required this.sentimentScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'text': text,
      'sentimentScore': sentimentScore,
    };
  }

  factory JournalEntry.fromMap(Map<dynamic, dynamic> map) {
    return JournalEntry(
      date: DateTime.parse(map['date']),
      text: map['text'] ?? '',
      sentimentScore: map['sentimentScore'] ?? 0,
    );
  }
}

class BreathingSession {
  final DateTime date;
  final int duration; // in seconds
  final int stressBefore;
  final int stressAfter;

  BreathingSession({
    required this.date,
    required this.duration,
    required this.stressBefore,
    required this.stressAfter,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'duration': duration,
      'stressBefore': stressBefore,
      'stressAfter': stressAfter,
    };
  }

  factory BreathingSession.fromMap(Map<dynamic, dynamic> map) {
    return BreathingSession(
      date: DateTime.parse(map['date']),
      duration: map['duration'] ?? 0,
      stressBefore: map['stressBefore'] ?? 0,
      stressAfter: map['stressAfter'] ?? 0,
    );
  }
}

class StressRecord {
  final DateTime date;
  final double sleepHours;
  final int activityLevel; // 1-10
  final int hydrationLevel; // 1-10
  final int stressScore;

  StressRecord({
    required this.date,
    required this.sleepHours,
    required this.activityLevel,
    required this.hydrationLevel,
    required this.stressScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'sleepHours': sleepHours,
      'activityLevel': activityLevel,
      'hydrationLevel': hydrationLevel,
      'stressScore': stressScore,
    };
  }

  factory StressRecord.fromMap(Map<dynamic, dynamic> map) {
    return StressRecord(
      date: DateTime.parse(map['date']),
      sleepHours: (map['sleepHours'] ?? 0.0).toDouble(),
      activityLevel: map['activityLevel'] ?? 0,
      hydrationLevel: map['hydrationLevel'] ?? 0,
      stressScore: map['stressScore'] ?? 0,
    );
  }
}
