# MedMind

Production-grade Flutter 3.x medical-tech app with Clean Architecture.

## Stack

- **State**: Riverpod
- **Navigation**: GoRouter
- **Charts**: fl_chart
- **Persistence**: SharedPreferences
- **Theme**: Dark (navy + cyan)

## Structure

```
lib/
  core/         # Theme, router, constants
  features/     # Feature-first screens & logic
  shared/       # Reusable widgets (AppCard, PrimaryButton, etc.)
  services/     # Local storage, etc.
  models/       # Data models
```

## Run

```bash
flutter pub get
flutter run
```

When you run `flutter run`, you’ll be prompted to pick a device. Typical options:

1. **Windows** – desktop app (needs Visual Studio toolchain; run `flutter doctor` if missing)
2. **Chrome** – run in browser (web)
3. **Android** – device or emulator (needs Android SDK / emulator)

Or run **`run.bat`** (Windows) for the same picker.

Frontend only — no backend.
