/// Gemini API key.
/// Override in production: flutter run --dart-define=GEMINI_API_KEY=your_key
const String geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'AIzaSyAz_ykjuu3-kvS8xP9phkfnBRl_2W9vlpM',
);
