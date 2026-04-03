import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medmind/models/app_backend_models.dart';
import 'package:medmind/services/local_database_service.dart';
import 'package:medmind/services/base_providers.dart';

// This file now ONLY contains the service classes and simple providers 
// that don't depend on storage_provider.dart to avoid circular imports.

class FirebaseService {
  final LocalDatabaseService _db;
  FirebaseService(this._db);

  AppUser? getCurrentUser() {
    return _db.getUser();
  }

  Future<void> updateProfile(AppUser user) async {
    await _db.saveUser(user);
  }

  Future<void> signUp(String email, String password, String name) async {
    final uid = 'user_${email.replaceAll('@', '_').replaceAll('.', '_')}';
    final user = AppUser(
      uid: uid, 
      email: email, 
      name: name,
      profileCompleted: false,
    );
    await _db.saveUser(user, password: password);
    
    // Seed initial data
    await _db.addActivity(ActivityLog(id: '1', steps: 4280, calories: 1840, distance: 3.2, activeMinutes: 45, date: DateTime.now()));
    await _db.addHealthMetric(HealthMetric(id: '1', heartRate: 72, spO2: 98, bodyTempC: 36.6, stressIndex: 20, timestamp: DateTime.now()));
  }

  Future<bool> logIn(String email, String password) async { 
    // First check if there's a stored user with matching credentials
    if (_db.validatePassword(email, password)) {
      return true;
    }
    // Allow a default test user for convenience
    if (email.trim() == 'test@medmind.com' && password == 'password123') {
      final existing = _db.getUser();
      if (existing == null || existing.email != 'test@medmind.com') {
        await signUp(email, password, 'Test User');
      }
      return true;
    }
    return false;
  }
  
  Future<void> logOut() async {
    // We don't necessarily need to clear the local user from DB on logout 
    // if we want to keep their profile data for the next login, 
    // but the session status is handled in AuthService.
  }
  Future<void> addWaterInput(String uid, int amountMl) async { }

  Future<void> logActivity(String uid, int steps, int calories) async {
    await _db.addActivity(ActivityLog(id: DateTime.now().toString(), steps: steps, calories: calories, distance: steps * 0.0007, activeMinutes: steps ~/ 100, date: DateTime.now()));
  }
}
