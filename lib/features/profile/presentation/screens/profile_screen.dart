import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/storage_provider.dart';
import '../../../../services/profile_service.dart';
import '../../../../models/profile_models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    // Ensure a profile always exists, then sync name/email from signup data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final svc = ref.read(profileServiceProvider);
      await svc.createDefaultProfileIfNeeded();
      await svc.syncNameAndEmailFromAuth();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
      data: (user) {
        if (user == null) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.cyanAccent));
        }
        return _buildContent(user);
      },
    );
  }

  Widget _buildContent(UserProfile user) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.navy900, AppTheme.navy800],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProfileOverview(user),
                                  const SizedBox(height: 24),
                                  _buildPersonalHealthInfo(user),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHealthSummary(),
                                  const SizedBox(height: 24),
                                  _buildLifestyleInfo(user),
                                  const SizedBox(height: 24),
                                  _buildAccountActions(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        ..._buildMobileLayout(user),
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

  List<Widget> _buildMobileLayout(UserProfile user) {
    return [
      _buildProfileOverview(user),
      const SizedBox(height: 24),
      _buildHealthSummary(),
      const SizedBox(height: 24),
      _buildPersonalHealthInfo(user),
      const SizedBox(height: 24),
      _buildLifestyleInfo(user),
      const SizedBox(height: 24),
      _buildAccountActions(),
    ];
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(color: AppTheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildProfileOverview(UserProfile user) {
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return _buildCard(
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cyanAccent, width: 2),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.navy600,
              backgroundImage: (user.profilePicture != null && File(user.profilePicture!).existsSync())
                  ? FileImage(File(user.profilePicture!))
                  : null,
              child: (user.profilePicture == null || !File(user.profilePicture!).existsSync())
                  ? Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name,
            style: const TextStyle(color: AppTheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.email,
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.success.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('Active Member', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileSheet(user),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.cyanAccent,
                side: BorderSide(color: AppTheme.cyanAccent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalHealthInfo(UserProfile user) {
    final items = [
      {'label': 'Age',    'value': '${user.age} yrs',              'icon': Icons.cake_rounded},
      {'label': 'Gender', 'value': user.gender,                    'icon': Icons.person_outline_rounded},
      {'label': 'Height', 'value': '${user.height.round()} cm',   'icon': Icons.height_rounded},
      {'label': 'Weight', 'value': '${user.weight.round()} kg',   'icon': Icons.scale_rounded},
      {'label': 'BMI',    'value': user.bmi.toStringAsFixed(1),    'icon': Icons.monitor_weight_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Personal Health Info'),
        _buildCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: List.generate(items.length, (i) {
              final info = items[i];
              return Column(children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.navy600, borderRadius: BorderRadius.circular(8)),
                    child: Icon(info['icon'] as IconData, color: AppTheme.cyanAccent, size: 20),
                  ),
                  title: Text(info['label'] as String,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: Text(info['value'] as String,
                    style: const TextStyle(color: AppTheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                if (i < items.length - 1) Divider(color: AppTheme.outline, height: 1),
              ]);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLifestyleInfo(UserProfile user) {
    final items = [
      {'label': 'Activity',   'value': user.activityLevel,                  'icon': Icons.directions_run_rounded},
      {'label': 'Sleep Avg',  'value': '${user.sleepAverage} hrs',           'icon': Icons.bedtime_rounded},
      {'label': 'Smoking',    'value': user.smokingStatus ? 'Yes' : 'No',    'icon': Icons.smoke_free_rounded},
      {'label': 'Alcohol',    'value': user.alcoholConsumption ? 'Yes' : 'No', 'icon': Icons.local_bar_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Lifestyle Info'),
        _buildCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: List.generate(items.length, (i) {
              final info = items[i];
              return Column(children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.navy600, borderRadius: BorderRadius.circular(8)),
                    child: Icon(info['icon'] as IconData, color: AppTheme.cyanAccent, size: 20),
                  ),
                  title: Text(info['label'] as String,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: Text(info['value'] as String,
                    style: const TextStyle(color: AppTheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                if (i < items.length - 1) Divider(color: AppTheme.outline, height: 1),
              ]);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthSummary() {
    final activity      = ref.watch(activitiesStreamProvider).value;
    final wellnessScore = ref.watch(dashboardWellnessScoreProvider).value ?? 78.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Health Summary'),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('Wellness Score', '${wellnessScore.round()}', '/100',   Icons.health_and_safety_rounded, Colors.greenAccent),
            _buildStatCard('Today\'s Steps', '${activity?.steps ?? 0}',  'steps',  Icons.directions_walk_rounded,    AppTheme.cyanAccent),
            _buildStatCard('Active Minutes', '${activity?.activeMinutes ?? 0}', 'min', Icons.timer_rounded,            Colors.orangeAccent),
            _buildStatCard('Distance',       '${activity?.distance.toStringAsFixed(1) ?? '0.0'}', 'km', Icons.map_rounded, Colors.lightBlueAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy600, AppTheme.navy700],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text(title, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            Icon(icon, color: color, size: 18),
          ]),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: const TextStyle(color: AppTheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(unit, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAccountActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account'),
        _buildCard(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).logout();
                ref.invalidate(authStateProvider);
                if (mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navy600,
                foregroundColor: AppTheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditProfileSheet(UserProfile user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => _EditProfileSheet(user: user, scrollController: scrollCtrl),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile user;
  final ScrollController scrollController;

  const _EditProfileSheet({required this.user, required this.scrollController});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _sleepCtrl;

  String _gender          = 'Other';
  String _activityLevel   = 'Moderate';
  bool   _smoking         = false;
  bool   _alcohol         = false;
  String? _profilePicture;
  bool _saving            = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl    = TextEditingController(text: widget.user.name);
    _ageCtrl     = TextEditingController(text: widget.user.age.toString());
    _heightCtrl  = TextEditingController(text: widget.user.height.toStringAsFixed(0));
    _weightCtrl  = TextEditingController(text: widget.user.weight.toStringAsFixed(0));
    _sleepCtrl   = TextEditingController(text: widget.user.sleepAverage.toString());
    _gender        = widget.user.gender;
    _activityLevel = widget.user.activityLevel;
    _smoking       = widget.user.smokingStatus;
    _alcohol       = widget.user.alcoholConsumption;
    _profilePicture = widget.user.profilePicture;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _sleepCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image  = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _profilePicture = image.path);
  }

  Future<void> _save() async {
    final age   = int.tryParse(_ageCtrl.text) ?? 25;
    final ht    = double.tryParse(_heightCtrl.text) ?? 175.0;
    final wt    = double.tryParse(_weightCtrl.text) ?? 70.0;
    final sleep = double.tryParse(_sleepCtrl.text) ?? 7.0;

    if (age < 5 || age > 120 || ht <= 0 || wt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid values'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _saving = true);
    final updated = widget.user.copyWith(
      name:               _nameCtrl.text.trim(),
      age:                age,
      gender:             _gender,
      height:             ht,
      weight:             wt,
      activityLevel:      _activityLevel,
      sleepAverage:       sleep,
      smokingStatus:      _smoking,
      alcoholConsumption: _alcohol,
      profilePicture:     _profilePicture,
    );

    await ref.read(profileServiceProvider).updateProfile(updated);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.navy800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.onSurfaceVariant), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(color: AppTheme.outline),
          // Scrollable form
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              children: [
                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppTheme.navy600,
                          backgroundImage: (_profilePicture != null && File(_profilePicture!).existsSync())
                              ? FileImage(File(_profilePicture!))
                              : null,
                          child: (_profilePicture == null || !File(_profilePicture!).existsSync())
                              ? Text(initials, style: const TextStyle(fontSize: 30, color: AppTheme.cyanAccent, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppTheme.cyanAccent, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppTheme.navy900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded)),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(controller: _ageCtrl, decoration: const InputDecoration(labelText: 'Age', suffixText: 'yrs'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.navy700,
                    value: _gender,
                    items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _gender = v!),
                    decoration: const InputDecoration(labelText: 'Gender'),
                  )),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: TextField(controller: _heightCtrl, decoration: const InputDecoration(labelText: 'Height', suffixText: 'cm'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _weightCtrl, decoration: const InputDecoration(labelText: 'Weight', suffixText: 'kg'), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: AppTheme.navy700,
                  value: _activityLevel,
                  items: ['Sedentary', 'Lightly Active', 'Moderate', 'Very Active', 'Super Active']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _activityLevel = v!),
                  decoration: const InputDecoration(labelText: 'Activity Level', prefixIcon: Icon(Icons.directions_run_outlined)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sleepCtrl,
                  decoration: const InputDecoration(labelText: 'Average Sleep', suffixText: 'hrs', prefixIcon: Icon(Icons.bedtime_outlined)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Smoking', style: TextStyle(color: AppTheme.onSurface)),
                  value: _smoking,
                  onChanged: (v) => setState(() => _smoking = v),
                  activeColor: AppTheme.cyanAccent,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Alcohol Consumption', style: TextStyle(color: AppTheme.onSurface)),
                  value: _alcohol,
                  onChanged: (v) => setState(() => _alcohol = v),
                  activeColor: AppTheme.cyanAccent,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyanAccent,
                    foregroundColor: AppTheme.navy900,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy900))
                      : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
