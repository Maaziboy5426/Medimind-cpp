import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mental_health_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mental_health_engine.dart';

class MentalHealthService {
  static const String moodLogsBoxName = 'moodLogsBox';
  static const String stressHistoryBoxName = 'stressHistoryBox';
  static const String breathingSessionsBoxName = 'breathingSessionsBox';
  static const String journalEntriesBoxName = 'journalEntriesBox';

  static Future<void> init() async {
    await Hive.openBox(moodLogsBoxName);
    await Hive.openBox(stressHistoryBoxName);
    await Hive.openBox(breathingSessionsBoxName);
    await Hive.openBox(journalEntriesBoxName);
  }

  // --- Mood Logs ---
  Future<void> saveMoodLog(MoodLog log) async {
    final box = Hive.box(moodLogsBoxName);
    await box.add(log.toMap());
    await _updateStreak();
  }

  List<MoodLog> getRecentMoodLogs({int count = 7}) {
    final box = Hive.box(moodLogsBoxName);
    final logs = box.values.map((e) => MoodLog.fromMap(e as Map)).toList();
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs.take(count).toList();
  }

  // --- Stress Records ---
  Future<void> saveStressRecord(StressRecord record) async {
    final box = Hive.box(stressHistoryBoxName);
    await box.add(record.toMap());
  }

  List<StressRecord> getStressHistory() {
    final box = Hive.box(stressHistoryBoxName);
    return box.values.map((e) => StressRecord.fromMap(e as Map)).toList();
  }

  // --- Breathing Sessions ---
  Future<void> saveBreathingSession(BreathingSession session) async {
    final box = Hive.box(breathingSessionsBoxName);
    await box.add(session.toMap());
  }

  List<BreathingSession> getBreathingSessions() {
    final box = Hive.box(breathingSessionsBoxName);
    return box.values.map((e) => BreathingSession.fromMap(e as Map)).toList();
  }

  // --- Journal Entries ---
  Future<void> saveJournalEntry(JournalEntry entry) async {
    final box = Hive.box(journalEntriesBoxName);
    await box.add(entry.toMap());
  }

  List<JournalEntry> getJournalEntries() {
    final box = Hive.box(journalEntriesBoxName);
    return box.values.map((e) => JournalEntry.fromMap(e as Map)).toList();
  }

  // --- Streak Tracker ---
  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogDateStr = prefs.getString('last_mood_log_date');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int currentStreak = prefs.getInt('mood_streak') ?? 0;

    if (lastLogDateStr != null) {
      final lastLogDate = DateTime.parse(lastLogDateStr);
      final lastDate = DateTime(lastLogDate.year, lastLogDate.month, lastLogDate.day);
      
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        currentStreak++;
      } else if (difference > 1) {
        currentStreak = 1;
      }
      // If difference is 0, streak remains same (already logged today)
    } else {
      currentStreak = 1;
    }

    await prefs.setInt('mood_streak', currentStreak);
    await prefs.setString('last_mood_log_date', now.toIso8601String());
  }

  Future<int> getMoodStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('mood_streak') ?? 0;
  }
}

// Provider
final mentalHealthServiceProvider = Provider((ref) => MentalHealthService());

final moodLogsProvider = FutureProvider<List<MoodLog>>((ref) async {
  final service = ref.watch(mentalHealthServiceProvider);
  return service.getRecentMoodLogs();
});

final streakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(mentalHealthServiceProvider);
  return service.getMoodStreak();
});

final mentalWellnessScoreProvider = FutureProvider<double>((ref) async {
  final service = ref.watch(mentalHealthServiceProvider);
  final logs = service.getRecentMoodLogs();
  final stress = service.getStressHistory();
  final journals = service.getJournalEntries();
  
  if (logs.isEmpty) return 75.0; // Default

  // For the sake of the engine, we need some values
  final lastMood = logs.first;
  final lastStress = stress.isNotEmpty ? stress.last : StressRecord(date: DateTime.now(), sleepHours: 7.0, activityLevel: 5, hydrationLevel: 5, stressScore: 50);
  final lastJournal = journals.isNotEmpty ? journals.last.sentimentScore : 0;

  int moodScore = 3;
  switch (lastMood.moodLabel.toLowerCase()) {
    case 'happy': moodScore = 5; break;
    case 'calm': moodScore = 4; break;
    case 'neutral': moodScore = 3; break;
    case 'stressed': moodScore = 2; break;
    case 'depressed': moodScore = 1; break;
  }

  return MentalHealthEngine.calculateWellnessScore(
    moodScore: moodScore,
    sleepHours: lastStress.sleepHours,
    stressScore: lastStress.stressScore,
    activityLevel: lastStress.activityLevel,
    journalSentiment: lastJournal,
  );
});
