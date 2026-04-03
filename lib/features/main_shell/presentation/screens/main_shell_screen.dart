import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/storage_provider.dart';

import '../../../../shared/widgets/widgets.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final title = _getTitleForLocation(location);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: AppTheme.cyanAccent, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.navy900,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: widget.child,
    );
  }

  String _getTitleForLocation(String location) {
    switch (location) {
      case '/': return 'MedMind';
      case '/mental-health': return 'Mental Health';
      case '/physical-health': return 'Physical Health';
      case '/activity-tracker': return 'Activity & Tracker';
      case '/health-chat': return 'AI Health Chat';
      case '/medicine-reminder': return 'Medicine Reminder';
      case '/health-community': return 'Health Community';

      case '/achievements': return 'Gamification & Achievements';
      case '/analytics': return 'Health Reports';
      case '/profile': return 'Profile';
      case '/settings': return 'Settings';
      default: return 'MedMind';
    }
  }
}
