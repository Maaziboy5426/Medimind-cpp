import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import 'local_storage_service.dart';
import 'firebase_backend_service.dart';

class AuthService {
  AuthService(this._storage, this._firebaseService);

  final LocalStorageService _storage;
  final FirebaseService _firebaseService;

  static const String _keyLoginStatus = 'loginStatus';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserId = 'userId';
  static const String _keyAuthToken = 'authToken';

  Future<bool> isLoggedIn() async {
    return _storage.getBool(_keyLoginStatus) ?? false;
  }

  Future<bool> hasCompletedOnboarding() async {
    final user = _firebaseService.getCurrentUser();
    return user?.profileCompleted ?? false;
  }

  Future<bool> login(String email, String password) async {
    try {
      final success = await _firebaseService.logIn(email.trim(), password);
      if (success) {
        await _storage.setBool(_keyLoginStatus, true);
        await _storage.setString(_keyUserEmail, email.trim());
        await _storage.setString(_keyUserId, 'local_user_id');
        await _storage.setString(_keyAuthToken, 'local_mock_token');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
     try {
       await _firebaseService.signUp(email.trim(), password, name);
       // On signup, we also set login status true 
       // so they go to onboarding profile setup
       await _storage.setBool(_keyLoginStatus, true);
       await _storage.setString(_keyUserEmail, email.trim());
       return true;
     } catch (e) {
       return false;
     }
  }

  Future<void> logout() async {
    await _firebaseService.logOut();
    await _storage.setBool(_keyLoginStatus, false);
    await _storage.remove(_keyUserEmail);
    await _storage.remove(_keyUserId);
    await _storage.remove(_keyAuthToken);
  }

  String? getStoredUserEmail() {
    return _storage.getString(_keyUserEmail);
  }

  Future<void> completeWelcomeOnboarding() async {
    await _storage.setBool(AppConstants.storageKeyOnboardingComplete, true);
  }

  Future<void> completeHealthProfile() async {
    final user = _firebaseService.getCurrentUser();
    if (user != null) {
      await _firebaseService.updateProfile(user.copyWith(profileCompleted: true));
    }
  }
}


