/// Gemini API key.
/// Override in production: flutter run --dart-define=GEMINI_API_KEY=your_key
const String geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'AIzaSyAyUzgWXC1EKg_dBXoCMTNqyZL6vQUXQ6c',
);
