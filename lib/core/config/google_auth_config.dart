/// OAuth 2.0 **Web application** client ID from Google Cloud Console (the same
/// client ID you enter in Supabase → Authentication → Providers → Google).
///
/// Required for native Google Sign-In on Android/iOS (`serverClientId`) and for
/// web (`clientId`).
///
/// Example:
/// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=123456789-xxxx.apps.googleusercontent.com`
const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
