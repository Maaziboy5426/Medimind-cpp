import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../services/storage_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.medication_rounded,
      title: 'Track your health',
      subtitle: 'Log medications and habits in one place and stay on top of your routine.',
    ),
    _OnboardingPage(
      icon: Icons.insights_rounded,
      title: 'See your progress',
      subtitle: 'Charts and insights help you understand patterns and improve adherence.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      title: 'Never miss a dose',
      subtitle: 'Smart reminders keep you on schedule and support your wellness goals.',
    ),
  ];

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  Future<void> _finish() async {
    debugPrint('OnboardingScreen: Finishing welcome onboarding...');
    try {
      await ref.read(authServiceProvider).completeWelcomeOnboarding();
      debugPrint('OnboardingScreen: Flag set successfully. Invalidating auth state...');
      ref.invalidate(authStateProvider);
      if (!mounted) return;
      debugPrint('OnboardingScreen: Navigating to /login');
      context.go('/login');
    } catch (e) {
      debugPrint('OnboardingScreen: Error finishing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy900,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _currentPage < _pages.length - 1
                    ? () => _pageController.animateToPage(
                          _pages.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        )
                    : _finish,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppTheme.surfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageView(page: _pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              child: Row(
                children: [
                  ...List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 6,
                      width: _currentPage == i ? 24 : 6,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppTheme.cyanAccent
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        } else {
                          _finish();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.cyanAccent,
                        foregroundColor: AppTheme.navy900,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                        ),
                      ),
                      child: Text(
                        _currentPage < _pages.length - 1 ? 'Next' : 'Get started',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.cyanAccent.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.cyanAccent.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                page.icon,
                size: 56,
                color: AppTheme.cyanAccent,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppTheme.surfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
