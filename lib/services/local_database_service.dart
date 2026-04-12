import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_backend_models.dart';

class LocalDatabaseService {
  final SharedPreferences _prefs;
  
  LocalDatabaseService(this._prefs);

  // Generic methods to save/load lists of maps
  Future<void> _saveList(String key, List<Map<String, dynamic>> data) async {
    await _prefs.setString(key, jsonEncode(data));
  }

  List<Map<String, dynamic>> _loadList(String key) {
    final str = _prefs.getString(key);
    if (str == null) return [];
    try {
      final decoded = jsonDecode(str);
      if (decoded is List) {
        return decoded.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      print('Error loading list $key: $e');
    }
    return [];
  }

  // --- AppUser ---
  Future<void> saveUser(AppUser user, {String? password}) async {
    await _prefs.setString('local_user', jsonEncode(user.toMap()));
    await _prefs.setString('local_user_uid', user.uid);
    if (password != null) {
      await _prefs.setString('local_user_password', password);
    }
  }

  AppUser? getUser() {
    final str = _prefs.getString('local_user');
    if (str == null) return null;
    final uid = _prefs.getString('local_user_uid') ?? 'local_uid';
    return AppUser.fromMap(jsonDecode(str), uid);
  }

  bool validatePassword(String email, String password) {
    final user = getUser();
    if (user == null) return false;
    if (user.email.toLowerCase() != email.toLowerCase().trim()) return false;
    final storedPw = _prefs.getString('local_user_password');
    return storedPw == password;
  }

  // --- Health Metrics ---
  Future<void> addHealthMetric(HealthMetric metric) async {
    final list = _loadList('local_health_metrics');
    list.add(metric.toMap());
    await _saveList('local_health_metrics', list);
  }

  List<HealthMetric> getHealthMetrics() {
    return _loadList('local_health_metrics')
        .map((m) => HealthMetric.fromMap(m, m['id'] ?? ''))
        .toList();
  }

  // --- Activities ---
  Future<void> addActivity(ActivityLog activity) async {
    final list = _loadList('local_activities');
    list.add(activity.toMap());
    await _saveList('local_activities', list);
  }

  List<ActivityLog> getActivities() {
    return _loadList('local_activities')
        .map((m) => ActivityLog.fromMap(m, m['id'] ?? ''))
        .toList();
  }

  // --- Medicines ---
  Future<void> saveMedicines(List<Medicine> medicines) async {
    final data = medicines.map((m) => m.toMap()).toList();
    await _saveList('local_medicines', data);
  }

  List<Medicine> getMedicines() {
    final list = _loadList('local_medicines');
    if (list.isEmpty) {
      // Seed initial mock data if empty
      return [
        Medicine(id: '1', name: 'Paracetamol', dosage: '500mg', time: '08:00 AM', frequency: 'Daily', isTaken: false),
        Medicine(id: '2', name: 'Vitamin D', dosage: '1000 IU', time: '02:00 PM', frequency: 'Daily', isTaken: false),
      ];
    }
    return list.map((m) => Medicine.fromMap(m, m['id'] ?? '')).toList();
  }

  // --- Appointments ---
  Future<void> saveAppointments(List<Appointment> appointments) async {
    final data = appointments.map((a) => a.toMap()).toList();
    await _saveList('local_appointments', data);
  }

  List<Appointment> getAppointments() {
    final list = _loadList('local_appointments');
    if (list.isEmpty) {
      return [
        Appointment(id: '1', doctorName: 'Dr. Sarah Johnson', specialization: 'Cardiologist', dateTime: DateTime.now().add(const Duration(days: 2)), status: 'Scheduled'),
        Appointment(id: '2', doctorName: 'Dr. Mark Wilson', specialization: 'Neurologist', dateTime: DateTime.now().add(const Duration(days: 5)), status: 'Scheduled'),
      ];
    }
    return list.map((m) => Appointment.fromMap(m, m['id'] ?? '')).toList();
  }

  // --- Community Posts ---
  Future<void> savePosts(List<CommunityPost> posts) async {
    final data = posts.map((p) => p.toMap()).toList();
    await _saveList('local_posts', data);
  }

  List<CommunityPost> getPosts() {
    final list = _loadList('local_posts');
    if (list.isEmpty) {
      return [
        CommunityPost(
          postID: '1', 
          userID: 'uid1', 
          username: 'Alex Rivera', 
          avatar: '', 
          content: 'Feeling much better after starting the new meditation routine!', 
          topic: 'Mental Wellness', 
          likesCount: 24, 
          createdAt: DateTime.now().subtract(const Duration(hours: 2))
        ),
        CommunityPost(
          postID: '2', 
          userID: 'uid2', 
          username: 'Maria Garcia', 
          avatar: '', 
          content: 'Anyone else finding the breathing exercises helpful for sleep?', 
          topic: 'Sleep Health', 
          likesCount: 15, 
          createdAt: DateTime.now().subtract(const Duration(hours: 5))
        ),
      ];
    }
    return list.map((m) => CommunityPost.fromMap(m)).toList();
  }

  // --- Achievements ---
  Future<void> saveAchievements(List<Achievement> achievements) async {
    final data = achievements.map((a) => a.toMap()).toList();
    await _saveList('local_achievements', data);
  }

  List<Achievement> getAchievements() {
    final list = _loadList('local_achievements');
    if (list.isEmpty) {
      return [
        Achievement(id: '1', title: 'Early Bird', description: 'Log your mood before 8 AM', isUnlocked: true, unlockedDate: DateTime.now().subtract(const Duration(days: 1))),
        Achievement(id: '2', title: 'Hydration Hero', description: 'Meet your water goal 3 days in a row', isUnlocked: false),
      ];
    }
    return list.map((m) => Achievement.fromMap(m, m['id'] ?? '')).toList();
  }
}
