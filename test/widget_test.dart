import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medmind/main.dart';
import 'package:medmind/services/storage_provider.dart';
import 'package:medmind/services/base_providers.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MedMindApp(),
      ),
    );

    // Verify MedMind is present (title)
    expect(find.text('MedMind'), findsAtLeast(1));
  });
}
