import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
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

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _persistSession(Session session) async {
    await _firebaseService.ensureUserFromSupabaseSession(session.user);
    await _storage.setBool(_keyLoginStatus, true);
    await _storage.setString(_keyUserEmail, session.user.email ?? '');
    await _storage.setString(_keyUserId, session.user.id);
    await _storage.setString(_keyAuthToken, session.accessToken);
  }

  Future<void> _clearLocalSession() async {
    await _storage.setBool(_keyLoginStatus, false);
    await _storage.remove(_keyUserEmail);
    await _storage.remove(_keyUserId);
    await _storage.remove(_keyAuthToken);
  }

  Future<bool> isLoggedIn() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      await _persistSession(session);
      return true;
    }
    if (_storage.getBool(_keyLoginStatus) ?? false) {
      await _clearLocalSession();
    }
    return false;
  }

  Future<bool> hasCompletedOnboarding() async {
    final user = _firebaseService.getCurrentUser();
    return user?.profileCompleted ?? false;
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final session = response.session;
      if (session == null) return false;
      await _persistSession(session);
      return true;
    } on AuthException catch (e) {
      debugPrint('Supabase login: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Supabase login: $e');
      return false;
    }
  }

  /// Returns true if the user has an active session (signed in).
  /// Returns false if signup failed or the project requires email confirmation (no session yet).
  Future<bool> signUp(String email, String password, String name) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name},
      );
      if (response.session != null) {
        await _persistSession(response.session!);
        return true;
      }
      if (response.user != null) {
        debugPrint('Supabase signUp: user created; confirm email if required by project settings.');
        return false;
      }
      return false;
    } on AuthException catch (e) {
      debugPrint('Supabase signUp: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Supabase signUp: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    await _clearLocalSession();
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
