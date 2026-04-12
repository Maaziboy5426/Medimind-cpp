import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/firebase_backend_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../services/storage_provider.dart';
import '../../../../services/settings_service.dart';
import '../../../../services/medicine_service.dart';
import '../../../../models/medicine_models.dart';
import '../../../../models/mood_models.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/activity_tracker_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _wellnessController;
  late Animation<double> _wellnessAnimation;

  @override
  void initState() {
    super.initState();
    _wellnessController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _wellnessAnimation = CurvedAnimation(
      parent: _wellnessController,
      curve: Curves.easeOutCubic,
    );
    _wellnessController.forward();
  }

  @override
  void dispose() {
    _wellnessController.dispose();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final horizontalPadding = constraints.maxWidth > 1200
            ? constraints.maxWidth * 0.15
            : AppConstants.defaultPadding;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, ${_userDisplayName()}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formattedDate(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  _WellnessHeroSection(animation: _wellnessAnimation),
                  const SizedBox(height: 12),
                  _HealthAlertsSection(),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: isDesktop
                  ? SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 220,
                      ),
                      delegate: SliverChildListDelegate([
                        _AIMentalInsightCard(),
                        _PhysicalVitalsCard(),
                        _ChronicDiseaseMonitoringCard(),
                        _DailyStreakGoalsCard(),
                      ]),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate([
                        _AIMentalInsightCard(),
                        const SizedBox(height: 16),
                        _PhysicalVitalsCard(),
                        const SizedBox(height: 16),
                        _ChronicDiseaseMonitoringCard(),
                        const SizedBox(height: 16),
                        _DailyStreakGoalsCard(),
                        const SizedBox(height: 16),
                      ]),
                    ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                isDesktop ? 20 : 0,
                horizontalPadding,
                40,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (isDesktop) const SizedBox(height: 4),
                  _MedicineInteractionCard(),
                  const SizedBox(height: 16),
                  _QuickActivitySummary(),
                  const SizedBox(height: 24),
                  _QuickActionsRow(),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WellnessHeroSection extends ConsumerWidget {
  const _WellnessHeroSection({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodLabel = ref.watch(moodHistoryProvider).isNotEmpty
        ? ref.watch(moodHistoryProvider).first.result.moodType.label
        : 'Calm';
    final physicalLabel = ref.watch(healthMetricsStreamProvider).value != null ? 'Stable' : 'Unknown';
    final activityLabel = (ref.watch(todayActivityProvider).value?.steps ?? 0) > 5000 ? 'Active' : 'Low';

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Wellness Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final score = ref.watch(dashboardWellnessScoreProvider).value ?? 78.0;
              return ProgressRing(
                progress: (score / 100.0) * animation.value,
                size: 200,
                strokeWidth: 14,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(score * animation.value).round()}',
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cyanAccent,
                      ),
                    ),
                    StatusBadge(
                      label: score >= 80 ? 'Excellent' : score >= 60 ? 'Good' : 'Needs Care',
                      type: score >= 60 ? StatusType.success : StatusType.warning,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIndicator(label: 'Mood', value: moodLabel, icon: Icons.sentiment_satisfied_alt_rounded),
              _buildIndicator(label: 'Physical', value: physicalLabel, icon: Icons.check_circle_outline_rounded),
              _buildIndicator(label: 'Activity', value: activityLabel, icon: Icons.bolt_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.cyanAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppTheme.cyanAccent),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _AIMentalInsightCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodHistory = ref.watch(moodHistoryProvider);
    final latestMood = moodHistory.isNotEmpty ? moodHistory.first : null;
    
    final sleepAsync = ref.watch(sleepHistoryProvider);
    final sleep = sleepAsync.value?.firstOrNull;
    
    String insightMsg = 'Maintain your healthy routine!';
    if (latestMood != null && latestMood.result.stressLevel > 7 
        && sleep != null && sleep.sleepDuration < 6) {
      insightMsg = 'AI Suggests: High stress and low sleep detected. Try a 5-minute breathing exercise.';
    } else if (latestMood?.result.moodType.label == 'Calm') {
      insightMsg = 'AI Suggests: You are in a calm state. Great time for focused work.';
    } else if (latestMood != null && latestMood.result.stressLevel > 7) {
      insightMsg = 'AI Suggests: Take a moment to relax and re-center yourself.';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: AppTheme.cyanAccent),
              const SizedBox(width: 8),
              Text(
                'AI Mental Insight',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetric('Last Mood', latestMood?.result.moodType.label ?? 'Unknown', latestMood != null ? '${latestMood.result.confidencePercent}% conf.' : ''),
              const Spacer(),
              _buildMetric('Stress Level', latestMood != null ? '${latestMood.result.stressLevel}/100' : 'Unknown', ''),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.navy600.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 20, color: AppTheme.cyanAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insightMsg,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, String subtext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
        if (subtext.isNotEmpty)
          Text(subtext, style: const TextStyle(fontSize: 10, color: AppTheme.cyanAccent)),
      ],
    );
  }
}

class _PhysicalVitalsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(healthMetricsStreamProvider).value;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Physical Vitals',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: () => context.go('/physical-health'),
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.cyanAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVitalTile('Heart Rate', metric?.heartRate.toString() ?? '--', 'bpm', Icons.favorite_rounded),
              _buildVitalTile('SpO2', metric?.spO2.toString() ?? '--', '%', Icons.water_drop_rounded),
              _buildVitalTile('Temp', metric?.bodyTempC.toString() ?? '--', '°C', Icons.thermostat_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTile(String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.cyanAccent),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
        Text(unit, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ChronicDiseaseMonitoringCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(latestBodyMetricsProvider).value;
    final vitals = ref.watch(healthMetricsStreamProvider).value;
    final activity = ref.watch(todayActivityProvider).value;

    String diabetesRisk = 'Low';
    bool diabetesLow = true;
    if (metrics != null && metrics.bmi > 25) {
      diabetesRisk = metrics.bmi > 30 ? 'High' : 'Moderate';
      diabetesLow = false;
    }

    String cardiacRisk = 'Low';
    bool cardiacLow = true;
    if (vitals != null && vitals.heartRate > 100) {
      cardiacRisk = vitals.heartRate > 120 ? 'High' : 'Moderate';
      cardiacLow = false;
    }

    String obesityRisk = 'Low';
    bool obesityLow = true;
    if (activity != null && activity.steps < 5000) {
      obesityRisk = activity.steps < 3000 ? 'High' : 'Moderate';
      obesityLow = false;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chronic Disease Monitoring',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildDiseaseRow('Heart Risk', cardiacRisk, cardiacLow),
          const Divider(height: 12, color: AppTheme.outline),
          _buildDiseaseRow('Diabetes Risk', diabetesRisk, diabetesLow),
          const Divider(height: 12, color: AppTheme.outline),
          _buildDiseaseRow('Obesity Risk', obesityRisk, obesityLow),
        ],
      ),
    );
  }

  Widget _buildDiseaseRow(String disease, String risk, bool isLow) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(disease,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.onSurface)),
        Row(
          children: [
            StatusBadge(
              label: risk,
              type: isLow ? StatusType.success : StatusType.warning,
            ),
            const SizedBox(width: 8),
            Icon(
              isLow ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 16,
              color: isLow ? AppTheme.success : AppTheme.error,
            ),
          ],
        ),
      ],
    );
  }
}

class _MedicineInteractionCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MedicineInteractionCard> createState() => _MedicineInteractionCardState();
}

class _MedicineInteractionCardState extends ConsumerState<_MedicineInteractionCard> {
  final TextEditingController _chatController = TextEditingController();
  String? _aiResponse;
  bool _isLoadingChat = false;

  void _askGemini() async {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isLoadingChat = true;
      _aiResponse = null;
    });

    final gemini = ref.read(geminiHealthServiceProvider);
    try {
      final res = await gemini.sendMessage(query, []);
      setState(() {
        _aiResponse = res;
      });
      _chatController.clear();
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiResponse = "Oops, I couldn't reach the AI. Let's try again later.";
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingChat = false);
      }
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextUp = ref.watch(nextUpProvider);
    final adherence = ref.watch(adherenceProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medicine Reminder',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${adherence.toInt()}% Adherence',
                style: const TextStyle(color: AppTheme.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (nextUp == null)
            const Text('No medications scheduled', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${nextUp.name} ${nextUp.dosage}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface)),
                      Text(nextUp.time,
                          style: const TextStyle(fontSize: 12, color: AppTheme.cyanAccent)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    ref.read(medicineServiceProvider).takeMedication(nextUp.medicationID);
                  },
                  child: const StatusBadge(label: 'Take Now', type: StatusType.info),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    size: 16, color: AppTheme.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    adherence >= 95 
                      ? 'AI Check: Perfect consistency! Keep it up.' 
                      : 'AI Check: No drug-food interactions for current meds',
                    style: const TextStyle(fontSize: 11, color: AppTheme.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_aiResponse != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.navy600.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
              ),
              child: Text(
                _aiResponse!,
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
              ),
            ),
          ],
          TextField(
            controller: _chatController,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Ask MedMind about your health...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
              suffixIcon: IconButton(
                onPressed: _isLoadingChat ? null : _askGemini,
                icon: _isLoadingChat 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyanAccent)) 
                    : const Icon(Icons.send_rounded, size: 20, color: AppTheme.cyanAccent),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
              filled: true,
              fillColor: AppTheme.navy700,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.outline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.outline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cyanAccent)),
            ),
            onSubmitted: (v) => _isLoadingChat ? null : _askGemini(),
          ),
        ],
      ),
    );
  }
}

class _DailyStreakGoalsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(todayActivityProvider).value;
    final hydration = ref.watch(todayHydrationProvider).value ?? 0;
    
    final historyAsync = ref.watch(activityHistoryProvider);
    int workoutDays = 0;
    if (historyAsync.value != null) {
      workoutDays = historyAsync.value!.where((e) => e.activeMinutes > 30).length;
    }

    final appSettings = ref.watch(appSettingsProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Streak & Goals',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildGoalProgress('Steps Goal', activity?.steps ?? 0, appSettings.dailyStepGoal),
          const SizedBox(height: 12),
          _buildGoalProgress('Hydration Goal', hydration, (appSettings.waterIntakeGoal * 1000).toInt()),
          const SizedBox(height: 12),
          _buildGoalProgress('Workout Days', workoutDays, 5),
        ],
      ),
    );
  }

  Widget _buildGoalProgress(String label, int current, int target) {
    final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.onSurface)),
            Text('$current / $target',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.cyanAccent)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.outline,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyanAccent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _QuickActivitySummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(todayActivityProvider).value;
    final sleepAsync = ref.watch(sleepHistoryProvider);
    final sleep = sleepAsync.value?.firstOrNull;
    
    String sleepStr = '0h 0m';
    if (sleep != null) {
      final hours = sleep.sleepDuration.floor();
      final mins = ((sleep.sleepDuration - hours) * 60).round();
      sleepStr = '${hours}h ${mins}m';
    }

    return AppCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActivityIcon(Icons.directions_walk_rounded, activity?.steps.toString() ?? '0', 'Steps'),
          _buildActivityIcon(Icons.local_fire_department_rounded, activity?.caloriesBurned.toString() ?? '0', 'kcal'),
          _buildActivityIcon(Icons.bedtime_rounded, sleepStr, 'Sleep'),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.cyanAccent),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
      ],
    );
  }
}

class _HealthAlertsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(sleepHistoryProvider);
    final hydration = ref.watch(todayHydrationProvider).value ?? 0;
    final adherence = ref.watch(adherenceProvider);
    
    List<String> alerts = [];
    
    if (sleepAsync.value != null && sleepAsync.value!.isNotEmpty) {
      if (sleepAsync.value!.first.sleepDuration < 5.0) {
        alerts.add('Sleep under 5 hours detected. Prioritize rest today.');
      }
    }
    
    if (hydration < 1000) {
      alerts.add('Hydration is critically low. Drink more water.');
    }
    
    if (adherence < 80.0) {
      alerts.add('You have missed some medications. Please check your schedule.');
    }
    
    if (alerts.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
              const SizedBox(width: 8),
              Text(
                'Health Alerts',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: alerts.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a, style: const TextStyle(color: AppTheme.onSurface, fontSize: 13)),
                  )
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionButton(Icons.medication_rounded, 'Medicines', () {}),
          _ActionButton(Icons.medical_services_rounded, 'Doctor', () {}),
          _ActionButton(Icons.forum_rounded, 'Forum', () {}),
          _ActionButton(Icons.chat_bubble_rounded, 'AI Chat', () {}),
          _ActionButton(Icons.emergency_rounded, 'SOS', () {}, isEmergency: true),
        ],
      ),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isEmergency;

  const _ActionButton(this.icon, this.label, this.onTap, {this.isEmergency = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEmergency ? AppTheme.error : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEmergency ? AppTheme.error : AppTheme.outline,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isEmergency ? Colors.white : AppTheme.cyanAccent,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isEmergency ? AppTheme.error : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
