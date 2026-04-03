import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/profile_models.dart';
import 'auth_service.dart';
import 'storage_provider.dart';
import 'firebase_backend_service.dart';

const String profileBoxName = 'userProfileBox';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final auth    = ref.watch(authServiceProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return ProfileService(auth, firebase);
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final service = ref.watch(profileServiceProvider);
  return service.watchProfile();
});

class ProfileService {
  final AuthService _auth;
  final FirebaseService _firebase;
  ProfileService(this._auth, this._firebase);

  Box get _box => Hive.box(profileBoxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(profileBoxName)) {
      await Hive.openBox(profileBoxName);
    }
  }

  String get _currentUserId {
    final email = _auth.getStoredUserEmail();
    return email ?? 'default_user';
  }

  UserProfile? getProfile() {
    final data = _box.get(_currentUserId);
    if (data == null) return null;
    return UserProfile.fromMap(data as Map);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _box.put(_currentUserId, profile.toMap());
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _box.put(_currentUserId, profile.toMap());
  }

  Stream<UserProfile?> watchProfile() async* {
    yield getProfile();
    await for (final event in _box.watch(key: _currentUserId)) {
      if (event.value == null) {
        yield null;
      } else {
        yield UserProfile.fromMap(event.value as Map);
      }
    }
  }

  Future<void> createDefaultProfileIfNeeded() async {
    if (getProfile() != null) return;
    // Pull name & email from the AppUser saved during signup
    final dbUser = _firebase.getCurrentUser();
    final storedEmail = _auth.getStoredUserEmail() ?? '';
    final email = dbUser?.email.isNotEmpty == true ? dbUser!.email : storedEmail;
    final name = dbUser?.name.isNotEmpty == true
        ? dbUser!.name
        : storedEmail
            .split('@')
            .first
            .replaceAll(RegExp(r'[_.\-]'), ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .where((w) => w.isNotEmpty)
            .join(' ');

    final defaultProfile = UserProfile(
      userID:             _currentUserId,
      name:               name,
      email:              email,
      age:                25,
      gender:             'Other',
      height:             175.0,
      weight:             70.0,
      activityLevel:      'Moderate',
      sleepAverage:       7.0,
      smokingStatus:      false,
      alcoholConsumption: false,
      profilePicture:     null,
    );
    await saveProfile(defaultProfile);
  }

  /// Keeps name & email in sync with whatever was stored at signup.
  Future<void> syncNameAndEmailFromAuth() async {
    final profile = getProfile();
    if (profile == null) return;
    final dbUser = _firebase.getCurrentUser();
    final storedEmail = _auth.getStoredUserEmail() ?? '';
    final freshEmail = dbUser?.email.isNotEmpty == true ? dbUser!.email : storedEmail;
    final freshName  = dbUser?.name.isNotEmpty == true
        ? dbUser!.name
        : storedEmail
            .split('@')
            .first
            .replaceAll(RegExp(r'[_.\-]'), ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .where((w) => w.isNotEmpty)
            .join(' ');
    // Only write if something changed to avoid unnecessary Hive writes
    if (profile.name != freshName || profile.email != freshEmail) {
      await updateProfile(profile.copyWith(name: freshName, email: freshEmail));
    }
  }
}
