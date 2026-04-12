import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/storage_provider.dart';
import 'services/base_providers.dart';

import 'services/mental_health_service.dart';
import 'services/physical_health_service.dart';
import 'services/activity_tracker_service.dart';
import 'services/profile_service.dart';
import 'services/chat_storage_service.dart';
import 'services/medicine_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Show a loading screen immediately
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent),
            SizedBox(height: 20),
            Text('Initializing MedMind...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    ),
  ));

  try {
    debugPrint('--- Starting App Initialization ---');

    debugPrint('Initializing Supabase...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    
    // Initialize Hive
    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    
    // Initialize SharedPreferences
    debugPrint('Initializing SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize Services
    debugPrint('Initializing MentalHealthService...');
    await MentalHealthService.init();
    
    debugPrint('Initializing PhysicalHealthService...');
    await PhysicalHealthService.init();

    debugPrint('Initializing ActivityTrackerService...');
    await ActivityTrackerService.init();

    debugPrint('Initializing ProfileService...');
    await ProfileService.init();

    debugPrint('Initializing ChatStorageService...');
    await ChatStorageService.init();

    debugPrint('Initializing MedicineService...');
    await MedicineService.init();
    
    debugPrint('--- Initialization Complete ---');

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MedMindApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('CRITICAL ERROR during initialization: $e');
    debugPrint('Stack Trace: $stack');
    
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text('App Failed to Start', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 24),
                const Text('Please clear browser cache or restart the app.', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MedMindApp extends ConsumerWidget {
  const MedMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'MedMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
