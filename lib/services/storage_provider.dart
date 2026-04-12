import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:medmind/services/local_storage_service.dart';
import 'package:medmind/services/auth_service.dart';
import 'package:medmind/services/mood_storage_service.dart';
import 'package:medmind/services/chat_storage_service.dart';
import 'package:medmind/services/gemini_health_service.dart';
import 'package:medmind/models/mood_models.dart';
import 'package:medmind/models/chat_models.dart';
import 'package:medmind/services/ai_engine_service.dart';
import 'package:medmind/services/firebase_backend_service.dart';
import 'package:medmind/services/local_database_service.dart';
import 'package:medmind/models/app_backend_models.dart';
import 'package:medmind/core/constants/app_constants.dart';
import 'package:medmind/services/base_providers.dart';
import 'package:medmind/services/activity_tracker_service.dart';

// --- Base Services ---

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalDatabaseService(prefs);
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService(ref.watch(localDatabaseServiceProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return AuthService(storage, firebase);
});

// --- Auth State ---

final authStateProvider = FutureProvider<AuthState>((ref) async {
  final auth = ref.watch(authServiceProvider);
  final onboardingWelcomeComplete = await ref.watch(localStorageServiceProvider).getBool(AppConstants.storageKeyOnboardingComplete) ?? false;
  final isLoggedIn = await auth.isLoggedIn();
  final profileCompleted = await auth.hasCompletedOnboarding();
  
  return AuthState(
    onboardingWelcomeComplete: onboardingWelcomeComplete, 
    isLoggedIn: isLoggedIn,
    profileCompleted: profileCompleted,
  );
});

class AuthState {
  const AuthState({
    required this.onboardingWelcomeComplete, 
    required this.isLoggedIn,
    required this.profileCompleted,
  });
  final bool onboardingWelcomeComplete;
  final bool isLoggedIn;
  final bool profileCompleted;
}

// --- Data Streams ---


final activitiesStreamProvider = StreamProvider<ActivityLog?>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  final list = db.getActivities();
  if (list.isEmpty) return Stream.value(null);
  return Stream.value(list.last);
});

final medicinesStreamProvider = StreamProvider<List<Medicine>>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  return Stream.value(db.getMedicines());
});

final appointmentsStreamProvider = StreamProvider<List<Appointment>>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  return Stream.value(db.getAppointments());
});

final postsStreamProvider = StreamProvider<List<CommunityPost>>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  return Stream.value(db.getPosts());
});

final achievementsStreamProvider = StreamProvider<List<Achievement>>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  return Stream.value(db.getAchievements());
});

final todayMealsStreamProvider = StreamProvider<List<Meal>>((ref) {
  return Stream.value([]);
});

final healthMetricsStreamProvider = StreamProvider<HealthMetric?>((ref) {
  final db = ref.watch(localDatabaseServiceProvider);
  final list = db.getHealthMetrics();
  if (list.isEmpty) return Stream.value(null);
  return Stream.value(list.last);
});

// --- Health Intelligence ---

final dashboardWellnessScoreProvider = FutureProvider<double>((ref) async {
  final metric = ref.watch(healthMetricsStreamProvider).value;
  final activityAsync = ref.watch(todayActivityProvider);
  final hydrationAsync = ref.watch(todayHydrationProvider);
  final sleepAsync = ref.watch(sleepHistoryProvider);

  final activity = activityAsync.value;
  final hydration = hydrationAsync.value ?? 1500;
  final sleepHistory = sleepAsync.value;
  final sleepHrs = sleepHistory != null && sleepHistory.isNotEmpty
      ? sleepHistory.first.sleepDuration
      : 7.2;

  // Compute score locally — no backend required.
  // Each component contributes up to 25 points (total = 100).
  final sleepScore = (sleepHrs.clamp(0, 9) / 9.0) * 25;
  final stepScore = ((activity?.steps ?? 4000).clamp(0, 10000) / 10000.0) * 25;
  final hydrationScore = (hydration.clamp(0, 2500) / 2500.0) * 25;
  final hrRaw = metric?.heartRate ?? 72;
  // Heart-rate score: ideal = 60-80 bpm, penalise outliers
  final hrScore = (hrRaw >= 60 && hrRaw <= 80)
      ? 25.0
      : (hrRaw >= 50 && hrRaw <= 100 ? 15.0 : 5.0);

  return (sleepScore + stepScore + hydrationScore + hrScore).clamp(0, 100);
});

// --- Mood & AI Services ---

final moodStorageServiceProvider = Provider<MoodStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MoodStorageService(prefs);
});

final moodHistoryProvider = StateNotifierProvider<MoodHistoryNotifier, List<MoodEntry>>((ref) {
  final storage = ref.watch(moodStorageServiceProvider);
  return MoodHistoryNotifier(storage);
});

class MoodHistoryNotifier extends StateNotifier<List<MoodEntry>> {
  MoodHistoryNotifier(this._storage) : super([]) {
    _load();
  }
  final MoodStorageService _storage;
  Future<void> _load() async {
    state = await _storage.loadHistory();
  }
  Future<void> addEntry(MoodEntry entry) async {
    state = [entry, ...state];
    await _storage.addEntry(entry);
  }
}

final lastMoodResultProvider = StateProvider<MoodResult?>((ref) => null);

final chatStorageServiceProvider = Provider<ChatStorageService>((ref) {
  return ChatStorageService();
});

final geminiHealthServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final aiEngineServiceProvider = Provider<AiEngineService>((ref) {
  return AiEngineService();
});

final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  final storage = ref.watch(chatStorageServiceProvider);
  final gemini = ref.watch(geminiHealthServiceProvider);
  return ChatMessagesNotifier(storage, gemini);
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier(this._storage, this._gemini) : super([]) {
    _load();
  }
  final ChatStorageService _storage;
  final GeminiService _gemini;

  Future<void> _load() async {
    final loaded = await _storage.loadMessages();
    state = loaded;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMsg = ChatMessage(
      messageID: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );
    
    state = [...state, userMsg];
    await _storage.saveMessages(state);

    final responseText = await _gemini.sendMessage(userMsg.content, state.sublist(0, state.length - 1));
    
    final aiMsg = ChatMessage(
      messageID: '${DateTime.now().millisecondsSinceEpoch}_ai',
      role: ChatRole.ai,
      content: responseText,
      timestamp: DateTime.now(),
    );

    state = [...state, aiMsg];
    await _storage.saveMessages(state);
  }

  Future<void> clearChat() async {
    await _storage.clearHistory();
    state = [];
  }
}
