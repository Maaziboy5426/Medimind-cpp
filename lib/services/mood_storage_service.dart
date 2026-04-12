import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_models.dart';

class MoodStorageService {
  MoodStorageService(this._prefs);

  final SharedPreferences _prefs;

  Future<List<MoodEntry>> loadHistory() async {
    try {
      final str = _prefs.getString('local_mood_history');
      if (str == null) return [];
      final list = jsonDecode(str) as List<dynamic>;
      return list.map((e) => MoodEntry.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addEntry(MoodEntry entry) async {
    final history = await loadHistory();
    history.insert(0, entry);
    await _prefs.setString('local_mood_history', jsonEncode(history.map((e) => e.toJson()).toList()));
  }
}

