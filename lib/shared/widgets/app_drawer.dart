import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/storage_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    
    final email = ref.read(authServiceProvider).getStoredUserEmail() ?? 'User';
    final userName = email.split('@').first;
    final displayName = userName.isNotEmpty 
        ? userName[0].toUpperCase() + userName.substring(1).toLowerCase()
        : 'User';

    return Drawer(
      backgroundColor: AppTheme.navy900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context, displayName, email),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/',
                  isActive: location == '/',
                ),
                _DrawerItem(
                  icon: Icons.psychology_rounded,
                  label: 'Mental Health',
                  route: '/mental-health',
                  isActive: location == '/mental-health',
                ),
                _DrawerItem(
                  icon: Icons.favorite_rounded,
                  label: 'Physical Health',
                  route: '/physical-health',
                  isActive: location == '/physical-health',
                ),
                _DrawerItem(
                  icon: Icons.track_changes_rounded,
                  label: 'Activity & Tracker',
                  route: '/activity-tracker',
                  isActive: location == '/activity-tracker',
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'AI Health Chat',
                  route: '/health-chat',
                  isActive: location == '/health-chat',
                ),
                _DrawerItem(
                  icon: Icons.medication_rounded,
                  label: 'Medicine Reminder',
                  route: '/medicine-reminder',
                  isActive: location == '/medicine-reminder',
                ),
                _DrawerItem(
                  icon: Icons.people_rounded,
                  label: 'Health Community',
                  route: '/health-community',
                  isActive: location == '/health-community',
                ),

                _DrawerItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Gamification & Achievements',
                  route: '/achievements',
                  isActive: location == '/achievements',
                ),
                _DrawerItem(
                  icon: Icons.analytics_rounded,
                  label: 'Health Reports',
                  route: '/analytics',
                  isActive: location == '/analytics',
                ),
                _DrawerItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  route: '/profile',
                  isActive: location == '/profile',
                ),
                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  route: '/settings',
                  isActive: location == '/settings',
                ),
              ],
            ),
          ),
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String email) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.navy800,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.cyanAccent.withOpacity(0.1),
            child: Icon(Icons.person_rounded, color: AppTheme.cyanAccent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MedMind',
                  style: TextStyle(
                    color: AppTheme.cyanAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Hello, $name',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.surfaceVariant, width: 1),
        ),
      ),
      child: _DrawerItem(
        icon: Icons.logout_rounded,
        label: 'Logout',
        route: '',
        isActive: false,
        onTap: () async {
          await ref.read(authServiceProvider).logout();
          ref.invalidate(authStateProvider);
          if (context.mounted) context.go('/login');
        },
        color: AppTheme.error,
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isActive ? AppTheme.cyanAccent : AppTheme.onSurfaceVariant);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap ?? () {
          Navigator.pop(context); // Close drawer
          context.go(route);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? AppTheme.cyanAccent.withOpacity(0.1) : Colors.transparent,
        leading: Icon(icon, color: effectiveColor, size: 24),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.cyanAccent : (color ?? AppTheme.onSurface),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
