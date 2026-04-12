import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/settings_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/storage_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;


  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.navy900,
            AppTheme.navy800,
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Center on desktop
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildAccountSettings(),
                      const SizedBox(height: 24),
                      _buildNotificationSettings(),
                      const SizedBox(height: 24),
                      _buildHealthPreferences(),
                      const SizedBox(height: 24),
                      _buildAppPreferences(),
                      const SizedBox(height: 24),
                      _buildSecurityPrivacy(),
                      const SizedBox(height: 24),
                      _buildLogoutSection(),
                      const SizedBox(height: 24),
                      _buildAboutSection(),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Customize your MedMind experience",
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: child,
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.navy600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.cyanAccent, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppTheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.navy600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.cyanAccent, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.cyanAccent,
        activeTrackColor: AppTheme.cyanAccent.withOpacity(0.3),
        inactiveThumbColor: AppTheme.onSurfaceVariant,
        inactiveTrackColor: AppTheme.navy600,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.navy600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.cyanAccent, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.cyanAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit, color: AppTheme.onSurfaceVariant, size: 16),
        ],
      ),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildAccountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Account"),
        _buildCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTile(title: "Edit Profile", icon: Icons.person_outline, onTap: () {}),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(title: "Change Password", icon: Icons.lock_outline, onTap: () {}),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(title: "Manage Email", icon: Icons.email_outlined, onTap: () {}),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(title: "Privacy Settings", icon: Icons.shield_outlined, onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Notification Settings"),
        _buildCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSwitchTile(
                title: "Medicine reminders",
                icon: Icons.medication_outlined,
                value: settings.medicineReminder,
                onChanged: (val) => notifier.updateMedicineReminder(val),
              ),
              Divider(color: AppTheme.outline, height: 1),
              _buildSwitchTile(
                title: "Hydration reminders",
                icon: Icons.water_drop_outlined,
                value: settings.hydrationReminder,
                onChanged: (val) => notifier.updateHydrationReminder(val),
              ),
              Divider(color: AppTheme.outline, height: 1),
              _buildSwitchTile(
                title: "Activity alerts",
                icon: Icons.directions_walk_outlined,
                value: settings.activityAlerts,
                onChanged: (val) => notifier.updateActivityAlerts(val),
              ),
              Divider(color: AppTheme.outline, height: 1),
              _buildSwitchTile(
                title: "Sleep reminders",
                icon: Icons.bedtime_outlined,
                value: settings.sleepReminders,
                onChanged: (val) => notifier.updateSleepReminders(val),
              ),
              Divider(color: AppTheme.outline, height: 1),
              _buildSwitchTile(
                title: "AI health insights",
                icon: Icons.auto_awesome_outlined,
                value: settings.aiInsights,
                onChanged: (val) => notifier.updateAiInsights(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthPreferences() {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Health Preferences"),
        _buildCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildActionTile(
                  title: "Daily step goal", icon: Icons.directions_walk, value: "${settings.dailyStepGoal} steps", 
                  onTap: () => _showEditDialog("Daily step goal", settings.dailyStepGoal.toString(), (v) => notifier.updateDailyStepGoal(int.tryParse(v) ?? 10000))),
              Divider(color: AppTheme.outline, height: 1),
              _buildActionTile(title: "Water intake goal", icon: Icons.local_drink, value: "${settings.waterIntakeGoal} Liters",
                  onTap: () => _showEditDialog("Water intake goal", settings.waterIntakeGoal.toString(), (v) => notifier.updateWaterIntakeGoal(double.tryParse(v) ?? 2.5))),
              Divider(color: AppTheme.outline, height: 1),
              _buildActionTile(title: "Sleep goal", icon: Icons.brightness_3, value: "${settings.sleepGoal} Hours",
                  onTap: () => _showEditDialog("Sleep goal", settings.sleepGoal.toString(), (v) => notifier.updateSleepGoal(int.tryParse(v) ?? 8))),
              Divider(color: AppTheme.outline, height: 1),
              _buildActionTile(title: "Calorie target", icon: Icons.local_fire_department, value: "${settings.calorieTarget} kcal",
                  onTap: () => _showEditDialog("Calorie target", settings.calorieTarget.toString(), (v) => notifier.updateCalorieTarget(int.tryParse(v) ?? 2200))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppPreferences() {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("App Preferences"),
        _buildCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSwitchTile(
                title: "Dark Mode",
                icon: Icons.dark_mode_outlined,
                value: settings.darkMode,
                onChanged: (val) => notifier.updateDarkMode(val),
              ),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(
                title: "Language",
                icon: Icons.language,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(settings.language, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
                  ],
                ),
                onTap: () => _showEditDialog("Language", settings.language, (v) => notifier.updateLanguage(v)),
              ),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(
                title: "Units",
                icon: Icons.square_foot,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(settings.units, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
                  ],
                ),
                onTap: () => _showEditDialog("Units (Metric/Imperial)", settings.units, (v) => notifier.updateUnits(v)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityPrivacy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Security & Privacy"),
        _buildCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTile(title: "Two-factor authentication", icon: Icons.security, onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA Enabled (Simulated)')));
              }),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(title: "Data export", icon: Icons.download_outlined, onTap: () async {
                await ref.read(settingsServiceProvider).exportData();
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data exported as JSON successfully.')));
              }),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(
                title: "Delete account",
                icon: Icons.delete_outline,
                titleColor: AppTheme.error,
                iconColor: AppTheme.error,
                trailing: const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                onTap: () async {
                  await ref.read(settingsServiceProvider).deleteAccount();
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local Data Cleared. Restart required.')));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("About MedMind"),
        _buildCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildListTile(
                title: "App Version",
                icon: Icons.info_outline,
                trailing: const Text("1.0.4 (Build 42)", style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
              ),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(title: "Privacy Policy", icon: Icons.policy_outlined, onTap: () {}),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(title: "Terms of Service", icon: Icons.description_outlined, onTap: () {}),
              Divider(color: AppTheme.outline, height: 1),
              _buildListTile(title: "Contact Support", icon: Icons.support_agent, onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(String title, String currentValue, Function(String) onSave) {
    String value = currentValue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        title: Text('Edit $title', style: const TextStyle(color: AppTheme.onSurface)),
        content: TextFormField(
          initialValue: currentValue,
          onChanged: (val) => value = val,
          style: const TextStyle(color: AppTheme.onSurface),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.outline)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.cyanAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              onSave(value);
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Session"),
        _buildCard(
          padding: EdgeInsets.zero,
          child: _buildListTile(
            title: "Logout",
            icon: Icons.logout_rounded,
            titleColor: AppTheme.error,
            iconColor: AppTheme.error,
            onTap: () async {
              await ref.read(authServiceProvider).logout();
              ref.invalidate(authStateProvider);
              if (mounted) context.go('/login');
            },
          ),
        ),
      ],
    );
  }
}
