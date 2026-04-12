import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/google_auth_config.dart';
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

  /// Uses Google Sign-In + Supabase [signInWithIdToken]. Requires
  /// [googleWebClientId] (Google Cloud “Web client” ID, also configured in Supabase).
  ///
  /// Returns `null` if the user closed the Google picker. Returns `false` on failure.
  Future<bool?> signInWithGoogle() async {
    if (googleWebClientId.isEmpty) {
      debugPrint(
        'Google Sign-In: set GOOGLE_WEB_CLIENT_ID (Google Cloud Web client ID).',
      );
      return false;
    }

    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: kIsWeb ? googleWebClientId : null,
        serverClientId: kIsWeb ? null : googleWebClientId,
      );

      final account = await googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        debugPrint('Google Sign-In: missing idToken; check Web client ID / SHA-1 for Android.');
        return false;
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );

      final session = response.session;
      if (session == null) return false;
      await _persistSession(session);
      return true;
    } on AuthException catch (e) {
      debugPrint('Google Sign-In (Supabase): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Google Sign-In: $e');
      return false;
    }
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
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
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
