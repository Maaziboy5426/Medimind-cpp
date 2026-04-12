import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/health_profile_setup_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/main_shell/presentation/screens/main_shell_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/mental_health/presentation/screens/mental_health_screen.dart';
import '../../features/physical_health/presentation/screens/physical_health_screen.dart';
import '../../features/activity_tracker/presentation/screens/activity_tracker_screen.dart';
import '../../features/health_chat/presentation/screens/health_chat_screen.dart';
import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/health_community/presentation/screens/health_community_screen.dart';
import '../../features/medicine_reminder/presentation/screens/medicine_reminder_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../services/storage_provider.dart';
import '../../shared/widgets/widgets.dart';
import '../constants/app_constants.dart';


final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // If it is loading, don't redirect yet to avoid using stale data
      if (authState.isLoading) return null;

      final auth = authState.value;
      if (auth == null) return null; // Wait for provider

      final path = state.uri.path;
      if (path == '/splash') return null;

      // 1. Check Welcome Onboarding (Skip if already logged in)
      if (!auth.isLoggedIn && !auth.onboardingWelcomeComplete && path != '/onboarding') {
        return '/onboarding';
      }

      // 2. Check Auth
      if (!auth.isLoggedIn) {
        if (path == '/login' || path == '/signup' || path == '/onboarding') return null;
        return '/login';
      }

      // 3. Check Health Profile Completion
      if (!auth.profileCompleted && path != '/onboarding-profile') {
        return '/onboarding-profile';
      }

      // 4. Redirect away from Auth pages if logged in
      if (auth.isLoggedIn && (path == '/login' || path == '/signup' || path == '/onboarding')) {
        return auth.profileCompleted ? '/' : '/onboarding-profile';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding-profile',
        name: 'onboarding-profile',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state,
          const HealthProfileSetupScreen(),
        ),
      ),

      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state,
          const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => _buildPageWithTransition(
          state,
          const SignupScreen(),
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/mental-health',
            name: 'mental-health',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const MentalHealthScreen(),
            ),
          ),
          GoRoute(
            path: '/physical-health',
            name: 'physical-health',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const PhysicalHealthScreen(),
            ),
          ),
          GoRoute(
            path: '/activity-tracker',
            name: 'activity-tracker',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const ActivityTrackerScreen(),
            ),
          ),
          GoRoute(
            path: '/health-chat',
            name: 'health-chat',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const HealthChatScreen(),
            ),
          ),
          GoRoute(
            path: '/medicine-reminder',
            name: 'medicine-reminder',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const MedicineReminderScreen(),
            ),
          ),
          GoRoute(
            path: '/health-community',
            name: 'health-community',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const HealthCommunityScreen(),
            ),
          ),

          GoRoute(
            path: '/achievements',
            name: 'achievements',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const AchievementsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _buildPageWithTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration(milliseconds: AppConstants.navAnimationMs),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
          child: child,
        ),
      );
    },
  );
}
