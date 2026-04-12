import 'package:flutter/material.dart';

/// Global dark medical-tech theme: navy background + cyan accent.
class AppTheme {
  AppTheme._();

  static const Color _navy900 = Color(0xFF0A0E21);
  static const Color _navy800 = Color(0xFF0D1328);
  static const Color _navy700 = Color(0xFF121A32);
  static const Color _navy600 = Color(0xFF1A2342);
  static const Color _navy500 = Color(0xFF252D4A);
  static const Color _cyanAccent = Color(0xFF00D9FF);
  static const Color _cyanDim = Color(0xFF00A8CC);
  static const Color _surface = Color(0xFF151D35);
  static const Color _surfaceVariant = Color(0xFF1E2744);
  static const Color _onSurface = Color(0xFFE8EEF4);
  static const Color _onSurfaceVariant = Color(0xFFB0BCC8);
  static const Color _outline = Color(0xFF2D3A5C);
  static const Color _error = Color(0xFFE57373);
  static const Color _success = Color(0xFF4DB6AC);
  static const Color _warning = Color(0xFFFFA726);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _cyanAccent,
          onPrimary: _navy900,
          primaryContainer: _navy600,
          onPrimaryContainer: _cyanAccent,
          secondary: _cyanDim,
          onSecondary: _navy900,
          surface: _surface,
          onSurface: _onSurface,
          surfaceContainerHighest: _surfaceVariant,
          onSurfaceVariant: _onSurfaceVariant,
          outline: _outline,
          error: _error,
          onError: _navy900,
        ),
        scaffoldBackgroundColor: _navy900,
        appBarTheme: const AppBarTheme(
          backgroundColor: _navy900,
          elevation: 0,
          centerTitle: true,
          foregroundColor: _onSurface,
          titleTextStyle: TextStyle(
            color: _onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: _surfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _cyanAccent,
            foregroundColor: _navy900,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _navy800,
          selectedItemColor: _cyanAccent,
          unselectedItemColor: _onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _navy600,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _cyanAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: _onSurfaceVariant),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: _onSurface),
          displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _onSurface),
          displaySmall: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _onSurface),
          headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _onSurface),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _onSurface),
          titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: _onSurface),
          titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: _onSurface),
          titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _onSurface),
          bodyLarge: TextStyle(fontSize: 17, color: _onSurface),
          bodyMedium: TextStyle(fontSize: 15, color: _onSurface),
          bodySmall: TextStyle(fontSize: 13, color: _onSurfaceVariant),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _onSurface),
        ),
        dividerColor: _outline,
        iconTheme: const IconThemeData(color: _cyanAccent, size: 24),
      );

  static const Color navy900 = _navy900;
  static const Color navy800 = _navy800;
  static const Color navy700 = _navy700;
  static const Color cyanAccent = _cyanAccent;
  static const Color cyanDim = _cyanDim;
  static const Color surface = _surface;
  static const Color surfaceVariant = _surfaceVariant;
  static const Color onSurface = _onSurface;
  static const Color onSurfaceVariant = _onSurfaceVariant;
  static const Color navy600 = _navy600;
  static const Color outline = _outline;
  static const Color success = _success;
  static const Color error = _error;
  static const Color warning = _warning;
}
