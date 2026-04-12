/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'MedMind';
  static const String storageKeyOnboardingComplete = 'onboarding_complete';
  static const String storageKeySelectedNavIndex = 'selected_nav_index';
  static const String storageKeyUserEmail = 'user_email';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyMoodHistory = 'mood_history';
  static const String storageKeyChatHistory = 'chat_history';

  static const int splashDurationMs = 2500;
  static const int splashPulsePeriodMs = 1500;

  static const double defaultPadding = 16.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const int navAnimationMs = 300;
}
