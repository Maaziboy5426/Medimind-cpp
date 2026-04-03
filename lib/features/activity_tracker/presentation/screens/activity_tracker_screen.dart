import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/firebase_backend_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../services/storage_provider.dart';
import '../../../../services/settings_service.dart';
import '../../../../services/activity_tracker_service.dart';
import '../../../../services/activity_tracker_engine.dart';
import '../../../../services/profile_service.dart';
import '../../../../models/activity_tracker_models.dart';
import '../../../../models/app_backend_models.dart' as backend;

class ActivityTrackerScreen extends ConsumerStatefulWidget {
  const ActivityTrackerScreen({super.key});

  @override
  ConsumerState<ActivityTrackerScreen> createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends ConsumerState<ActivityTrackerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _userDisplayName() {
    final email = ref.read(authServiceProvider).getStoredUserEmail();
    if (email == null || email.isEmpty) return 'User';
    final part = email.split('@').first;
    if (part.isEmpty) return 'User';
    return part.length > 1
        ? part[0].toUpperCase() + part.substring(1).toLowerCase()
        : part.toUpperCase();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formattedDate() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final n = DateTime.now();
    return '${months[n.month - 1]} ${n.day}, ${n.year}';
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
            AppTheme.navy900,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          final horizontalPadding = constraints.maxWidth > 1200
              ? constraints.maxWidth * 0.12
              : AppConstants.defaultPadding;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      horizontalPadding, 32, horizontalPadding, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()}, ${_userDisplayName()}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.cyanAccent.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Text(
                            _formattedDate(),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.onSurfaceVariant.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 40),
                sliver: isDesktop
                    ? SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          mainAxisExtent: 440,
                        ),
                        delegate: SliverChildListDelegate([
                          _NutritionTrackerCard(animation: _progressAnimation),
                          _DailyActivityCard(animation: _progressAnimation),
                          _SleepMonitoringCard(animation: _progressAnimation),
                          _HydrationTrackerCard(animation: _progressAnimation),
                          _BMICalculatorCard(animation: _progressAnimation),
                        ]),
                      )
                    : SliverList(
                        delegate: SliverChildListDelegate([
                          _NutritionTrackerCard(animation: _progressAnimation),
                          const SizedBox(height: 20),
                          _DailyActivityCard(animation: _progressAnimation),
                          const SizedBox(height: 20),
                          _SleepMonitoringCard(animation: _progressAnimation),
                          const SizedBox(height: 20),
                          _HydrationTrackerCard(animation: _progressAnimation),
                          const SizedBox(height: 20),
                          _BMICalculatorCard(animation: _progressAnimation),
                        ]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NutritionTrackerCard extends ConsumerWidget {
  const _NutritionTrackerCard({required this.animation});
  final Animation<double> animation;

  void _showAddMealDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _AddMealSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final calorieGoal = settings.calorieTarget;
    final nutritionAsync = ref.watch(todayNutritionProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Nutrition & Wellness Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          nutritionAsync.when(
            data: (logs) {
              final totalKcal = logs.fold(0, (sum, item) => sum + item.calories);
              final breakfast = logs.where((l) => l.mealType == 'Breakfast').fold(0, (sum, i) => sum + i.calories);
              final lunch = logs.where((l) => l.mealType == 'Lunch').fold(0, (sum, i) => sum + i.calories);
              final dinner = logs.where((l) => l.mealType == 'Dinner').fold(0, (sum, i) => sum + i.calories);
              final snacks = logs.where((l) => l.mealType == 'Snack').fold(0, (sum, i) => sum + i.calories);

              return Column(
                children: [
                  Center(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final progress = calorieGoal > 0 ? (totalKcal / calorieGoal).clamp(0.0, 1.0) * animation.value : 0.0;
                        return ProgressRing(
                          progress: progress,
                          size: 130,
                          strokeWidth: 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text((totalKcal * animation.value).round().toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                              Text('/ $calorieGoal kcal', style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Daily Breakdown:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  _MacroTile(label: 'Breakfast', value: '$breakfast kcal', color: Colors.blue),
                  _MacroTile(label: 'Lunch', value: '$lunch kcal', color: Colors.green),
                  _MacroTile(label: 'Dinner', value: '$dinner kcal', color: Colors.orange),
                  if (snacks > 0) _MacroTile(label: 'Snacks', value: '$snacks kcal', color: Colors.purple),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _AddButton(label: 'Meal', onPressed: () => _showAddMealDialog(context, ref))),
            ],
          ),
        ],
      ),
    );
  }
}

// ... _MacroTile and _AddButton stay similar ...

class _MacroTile extends ConsumerWidget {
  const _MacroTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.onSurface)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _AddButton extends ConsumerWidget {
  const _AddButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.cyanAccent,
        side: const BorderSide(color: AppTheme.outline),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text('+ $label', style: const TextStyle(fontSize: 11)),
    );
  }
}

class _DailyActivityCard extends ConsumerWidget {
  const _DailyActivityCard({required this.animation});
  final Animation<double> animation;

  void _showLogActivityDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _LogActivitySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(todayActivityProvider);
    final settings = ref.watch(appSettingsProvider);
    final goal = settings.dailyStepGoal;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_run_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Daily Activity Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          activityAsync.when(
            data: (activity) {
              final steps = activity?.steps ?? 0;
              final kcal = activity?.caloriesBurned ?? 0;
              final dist = activity?.distanceKm ?? 0.0;
              final mins = activity?.activeMinutes ?? 0;

              return Column(
                children: [
                  Center(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final progress = goal > 0 ? (steps / goal).clamp(0.0, 1.0) * animation.value : 0.0;
                        return ProgressRing(
                          progress: progress,
                          size: 130,
                          strokeWidth: 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text((steps * animation.value).round().toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                              const Text('Steps', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActivityMetric(icon: Icons.local_fire_department_rounded, label: 'Calories', value: kcal.toString(), unit: 'kcal'),
                      _ActivityMetric(icon: Icons.map_rounded, label: 'Distance', value: dist.toStringAsFixed(1), unit: 'km'),
                      _ActivityMetric(icon: Icons.timer_rounded, label: 'Active', value: mins.toString(), unit: 'min'),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          PrimaryButton(label: 'Log Activity', onPressed: () => _showLogActivityDialog(context, ref)),
        ],
      ),
    );
  }
}

class _ActivityMetric extends ConsumerWidget {
  const _ActivityMetric({required this.icon, required this.label, required this.value, required this.unit});
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.cyanAccent.withOpacity(0.7), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
      ],
    );
  }
}

class _SleepMonitoringCard extends ConsumerWidget {
  const _SleepMonitoringCard({required this.animation});
  final Animation<double> animation;

  void _showLogSleepDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _LogSleepSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(sleepHistoryProvider);
    final settings = ref.watch(appSettingsProvider);
    final sleepGoal = settings.sleepGoal.toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bedtime_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Sleep Monitoring', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          sleepAsync.when(
            data: (history) {
              final lastNight = history.isNotEmpty ? history.first : null;
              final duration = lastNight?.sleepDuration ?? 0.0;
              final quality = ActivityTrackerEngine.getSleepQuality(duration);
              final stages = ActivityTrackerEngine.estimateSleepStages(duration);

              return Column(
                children: [
                   Center(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final progress = sleepGoal > 0 ? (duration / sleepGoal).clamp(0.0, 1.0) * animation.value : 0.0;
                        return ProgressRing(
                          progress: progress,
                          size: 130,
                          strokeWidth: 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text((duration * animation.value).toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                              Text('of $sleepGoal hrs', style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars_rounded, size: 14, color: duration >= 7 ? Colors.green : Colors.orange),
                      const SizedBox(width: 8),
                      Text('Sleep Quality: $quality', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SleepMetric(label: 'Deep Sleep', value: '${(stages['deep']! * 60).round()}m'),
                      _SleepMetric(label: 'REM Sleep', value: '${(stages['rem']! * 60).round()}m'),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          PrimaryButton(label: 'Log Sleep', onPressed: () => _showLogSleepDialog(context, ref)),
        ],
      ),
    );
  }
}

class _SleepMetric extends ConsumerWidget {
  const _SleepMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _HydrationTrackerCard extends ConsumerWidget {
  const _HydrationTrackerCard({required this.animation});
  final Animation<double> animation;

  Future<void> _addWater(WidgetRef ref) async {
    final service = ref.read(activityTrackerServiceProvider);
    await service.saveHydrationLog(UserHydrationLog(date: DateTime.now(), waterMl: 250));
    ref.invalidate(todayHydrationProvider);
    ref.invalidate(hydrationHistoryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydrationAsync = ref.watch(todayHydrationProvider);
    final settings = ref.watch(appSettingsProvider);
    final goalMl = (settings.waterIntakeGoal * 1000).toInt();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Hydration Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          hydrationAsync.when(
            data: (currentMl) {
              return Column(
                children: [
                  Center(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final progress = goalMl > 0 ? (currentMl / goalMl).clamp(0.0, 1.0) * animation.value : 0.0;
                        return ProgressRing(
                          progress: progress,
                          size: 130,
                          strokeWidth: 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text((currentMl * animation.value).round().toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                              Text('/ $goalMl ml', style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: '+ 250ml',
                          onPressed: () => _addWater(ref),
                          backgroundColor: AppTheme.navy600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          PrimaryButton(label: 'View History', onPressed: () {}),
        ],
      ),
    );
  }
}

class _BMICalculatorCard extends ConsumerWidget {
  const _BMICalculatorCard({required this.animation});
  final Animation<double> animation;

  void _showUpdateBodyMetricsDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _BodyMetricsSheet(),
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(latestBodyMetricsProvider);
    final user = ref.watch(userProfileProvider).value;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Body Health Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          metricsAsync.when(
            data: (metrics) {
              final h = metrics?.height ?? user?.height ?? 175.0;
              final w = metrics?.weight ?? user?.weight ?? 70.0;
              final age = metrics?.age ?? user?.age ?? 25;
              final bmi = metrics?.bmi ?? (user != null ? user.bmi : ActivityTrackerEngine.calculateBMI(h, w));
              final status = ActivityTrackerEngine.getBMIStatus(bmi);

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _InfoBox(label: 'Height', value: '${h.round()} cm')),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoBox(label: 'Weight', value: '${w.round()} kg')),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoBox(label: 'Age', value: '$age yrs')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final progress = (bmi / 40.0).clamp(0.0, 1.0) * animation.value;
                        return ProgressRing(
                          progress: progress,
                          size: 110,
                          strokeWidth: 8,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text((bmi * animation.value).toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                              const Text('BMI', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                              Text(status, 
                                   style: TextStyle(fontSize: 10, color: bmi < 25 ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          PrimaryButton(label: 'Update Health Stats', onPressed: () => _showUpdateBodyMetricsDialog(context, ref)),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.navy600,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// --- Input Sheets ---

class _AddMealSheet extends ConsumerStatefulWidget {
  const _AddMealSheet();
  @override
  ConsumerState<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<_AddMealSheet> {
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String _mealType = 'Breakfast';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Meal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _mealType,
            dropdownColor: AppTheme.navy800,
            decoration: const InputDecoration(labelText: 'Meal Type'),
            items: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (val) => setState(() => _mealType = val!),
          ),
          const SizedBox(height: 16),
          AppTextField(controller: _kcalController, label: 'Calories (kcal)', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: AppTextField(controller: _proteinController, label: 'Protein (g)', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(controller: _carbsController, label: 'Carbs (g)', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(controller: _fatController, label: 'Fat (g)', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Save Meal',
            onPressed: () async {
              final log = NutritionLog(
                date: DateTime.now(),
                mealType: _mealType,
                calories: int.tryParse(_kcalController.text) ?? 0,
                protein: double.tryParse(_proteinController.text) ?? 0.0,
                carbs: double.tryParse(_carbsController.text) ?? 0.0,
                fat: double.tryParse(_fatController.text) ?? 0.0,
              );
              await ref.read(activityTrackerServiceProvider).saveNutritionLog(log);
              ref.invalidate(todayNutritionProvider);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LogActivitySheet extends ConsumerStatefulWidget {
  const _LogActivitySheet();
  @override
  ConsumerState<_LogActivitySheet> createState() => _LogActivitySheetState();
}

class _LogActivitySheetState extends ConsumerState<_LogActivitySheet> {
  final _stepsController = TextEditingController();
  final _minsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Daily Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AppTextField(controller: _stepsController, label: 'Steps', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          AppTextField(controller: _minsController, label: 'Active Minutes', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          const Text('Distance and Calories will be calculated automatically.', style: TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Save Activity',
            onPressed: () async {
              final steps = int.tryParse(_stepsController.text) ?? 0;
              final mins = int.tryParse(_minsController.text) ?? 0;
              final log = UserActivityLog(
                date: DateTime.now(),
                steps: steps,
                activeMinutes: mins,
                distanceKm: ActivityTrackerEngine.calculateDistanceKm(steps),
                caloriesBurned: ActivityTrackerEngine.calculateCaloriesFromSteps(steps),
              );
              await ref.read(activityTrackerServiceProvider).saveActivityLog(log);
              ref.invalidate(todayActivityProvider);
              ref.invalidate(activityHistoryProvider);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _LogSleepSheet extends ConsumerStatefulWidget {
  const _LogSleepSheet();
  @override
  ConsumerState<_LogSleepSheet> createState() => _LogSleepSheetState();
}

class _LogSleepSheetState extends ConsumerState<_LogSleepSheet> {
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Log Sleep', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Sleep Time'),
            trailing: Text(_startTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _startTime);
              if (picked != null) setState(() => _startTime = picked);
            },
          ),
          ListTile(
            title: const Text('Wakeup Time'),
            trailing: Text(_endTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _endTime);
              if (picked != null) setState(() => _endTime = picked);
            },
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Save Sleep Log',
            onPressed: () async {
              final now = DateTime.now();
              // Estimate dates (start is yesterday if end is today and they cross midnight)
              var start = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
              var end = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);
              
              if (end.isBefore(start)) {
                start = start.subtract(const Duration(days: 1));
              }

              final duration = ActivityTrackerEngine.calculateSleepDuration(start, end);
              final stages = ActivityTrackerEngine.estimateSleepStages(duration);

              final log = UserSleepLog(
                date: now,
                sleepStart: start,
                sleepEnd: end,
                sleepDuration: duration,
                deepSleep: stages['deep']!,
                remSleep: stages['rem']!,
              );
              await ref.read(activityTrackerServiceProvider).saveSleepLog(log);
              ref.invalidate(sleepHistoryProvider);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BodyMetricsSheet extends ConsumerStatefulWidget {
  const _BodyMetricsSheet();
  @override
  ConsumerState<_BodyMetricsSheet> createState() => _BodyMetricsSheetState();
}

class _BodyMetricsSheetState extends ConsumerState<_BodyMetricsSheet> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Update Body Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AppTextField(controller: _heightController, label: 'Height (cm)', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          AppTextField(controller: _weightController, label: 'Weight (kg)', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          AppTextField(controller: _ageController, label: 'Age', keyboardType: TextInputType.number),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Save Changes',
            onPressed: () async {
              final h = double.tryParse(_heightController.text) ?? 0.0;
              final w = double.tryParse(_weightController.text) ?? 0.0;
              final age = int.tryParse(_ageController.text) ?? 0;
              final bmi = ActivityTrackerEngine.calculateBMI(h, w);

              final metrics = BodyMetrics(
                date: DateTime.now(),
                height: h,
                weight: w,
                age: age,
                bmi: bmi,
              );
              await ref.read(activityTrackerServiceProvider).saveBodyMetrics(metrics);
              ref.invalidate(latestBodyMetricsProvider);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

