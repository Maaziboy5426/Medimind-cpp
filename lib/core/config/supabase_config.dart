/// Supabase project URL and anon key (safe to ship in the client; protect data with RLS).
/// Override for other environments:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://luvydiufkdvcrmghiqwo.supabase.co',
);

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1dnlkaXVma2R2Y3JtZ2hpcXdvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1NTUzNDgsImV4cCI6MjA4NjEzMTM0OH0.xQX1MSoFp5RuDeAfiGop29drXGkyiZZJlBWJGsarhRY',
);
