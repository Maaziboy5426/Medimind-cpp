import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/physical_health_service.dart';
import '../../../../services/physical_health_engine.dart';
import '../../../../models/physical_health_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../services/storage_provider.dart';


class PhysicalHealthScreen extends ConsumerStatefulWidget {
  const PhysicalHealthScreen({super.key});

  @override
  ConsumerState<PhysicalHealthScreen> createState() => _PhysicalHealthScreenState();
}

class _PhysicalHealthScreenState extends ConsumerState<PhysicalHealthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _gaugeAnimation = CurvedAnimation(
      parent: _gaugeController,
      curve: Curves.easeOutCubic,
    );
    _gaugeController.forward();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
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
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.cyanAccent, size: 32),
                        onPressed: () => _showLogMetricsDialog(context),
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
                          mainAxisExtent: 400,
                        ),
                        delegate: SliverChildListDelegate([
                          _DiseaseRiskCard(),
                          _EarlySymptomCard(),
                          _ChronicMonitoringCard(),
                          _CancerRiskCard(animation: _gaugeAnimation),
                          _SymptomCheckerCard(),
                          _HealthRiskScoreCard(animation: _gaugeAnimation),
                        ]),
                      )
                    : SliverList(
                        delegate: SliverChildListDelegate([
                          _DiseaseRiskCard(),
                          const SizedBox(height: 20),
                          _EarlySymptomCard(),
                          const SizedBox(height: 20),
                          _ChronicMonitoringCard(),
                          const SizedBox(height: 20),
                          _CancerRiskCard(animation: _gaugeAnimation),
                          const SizedBox(height: 20),
                          _SymptomCheckerCard(),
                          const SizedBox(height: 20),
                          _HealthRiskScoreCard(animation: _gaugeAnimation),
                        ]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogMetricsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _LogMetricsSheet(),
    );
  }
}

class _DiseaseRiskCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risksAsync = ref.watch(riskPredictionsProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Disease Risk Prediction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          risksAsync.when(
            data: (risksList) {
              if (risksList.isEmpty) return const Text('Log metrics to calculate risks');
              final r = risksList.first;
              
              String getLevel(double p) => p < 30 ? 'Low Risk' : p < 70 ? 'Moderate Risk' : 'High Risk';
              Color getColor(double p) => p < 30 ? Colors.green : p < 70 ? Colors.orange : Colors.red;
              IconData getIcon(double p) => p < 30 ? Icons.trending_down_rounded : p < 70 ? Icons.trending_flat_rounded : Icons.trending_up_rounded;

              return Column(
                children: [
                  _RiskRow(
                    name: 'Heart Disease',
                    level: '${getLevel(r.heartRisk)} (${r.heartRisk.round()}%)',
                    color: getColor(r.heartRisk),
                    icon: getIcon(r.heartRisk),
                  ),
                  const Divider(height: 24, color: AppTheme.outline),
                  _RiskRow(
                    name: 'Diabetes',
                    level: '${getLevel(r.diabetesRisk)} (${r.diabetesRisk.round()}%)',
                    color: getColor(r.diabetesRisk),
                    icon: getIcon(r.diabetesRisk),
                  ),
                  const Divider(height: 24, color: AppTheme.outline),
                  _RiskRow(
                    name: 'Hypertension',
                    level: '${getLevel(r.hypertensionRisk)} (${r.hypertensionRisk.round()}%)',
                    color: getColor(r.hypertensionRisk),
                    icon: getIcon(r.hypertensionRisk),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          PrimaryButton(label: 'Calculate Trends', onPressed: () {
            ref.invalidate(riskPredictionsProvider);
          }),
        ],
      ),
    );
  }
}


class _RiskRow extends ConsumerWidget {
  const _RiskRow({required this.name, required this.level, required this.color, required this.icon});
  final String name;
  final String level;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 2),
            Text(level, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Icon(icon, color: color, size: 20),
      ],
    );
  }
}

class _EarlySymptomCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(symptomHistoryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.biotech_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Early Symptom Prediction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) return const Text('No recent symptoms logged.', style: TextStyle(fontSize: 12));
              final last = history.last;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Latest Symptoms:', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: last.symptoms.map((s) => StatusBadge(label: s, type: StatusType.info)).toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.navy600.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Diagnosis Result:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                        const SizedBox(height: 4),
                        Text('Potential: ${last.possibleConditions.isNotEmpty ? last.possibleConditions.first : "None"}', 
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Risk Level: ${last.severity}', 
                             style: TextStyle(fontSize: 12, 
                                            color: last.severity == 'High' ? Colors.red : (last.severity == 'Moderate' ? Colors.orange : Colors.green), 
                                            fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          PrimaryButton(label: 'Check Symptoms', onPressed: () => _showSymptomDialog(context, ref)),
        ],
      ),
    );
  }

  void _showSymptomDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _SymptomCheckSheet(),
    );
  }
}

class _ChronicMonitoringCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(chronicEntriesProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Chronic Disease Monitoring', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          historyAsync.when(
            data: (history) {
              final last = history.isNotEmpty ? history.first : null;
              final bp = last?.bloodPressure ?? '120/80';
              final sugar = last?.bloodSugar ?? 100;
              final chol = last?.cholesterol ?? 180;

              return Column(
                children: [
                  _MonitoringItem(
                    label: 'Latest BP', 
                    value: bp, 
                    unit: 'mmHg',
                    isWarning: int.tryParse(bp.split('/').first) != null && int.parse(bp.split('/').first) > 140,
                  ),
                  const SizedBox(height: 16),
                  _MonitoringItem(
                    label: 'Blood Sugar', 
                    value: sugar.toString(), 
                    unit: 'mg/dL',
                    isWarning: sugar > 126,
                  ),
                  const SizedBox(height: 16),
                  _MonitoringItem(
                    label: 'Cholesterol', 
                    value: chol.toString(), 
                    unit: 'mg/dL',
                    isWarning: chol > 200,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          PrimaryButton(label: 'Log Vitals', onPressed: () => _showLogVitalsDialog(context, ref)),
        ],
      ),
    );
  }
  
  void _showLogVitalsDialog(BuildContext context, WidgetRef ref) {
     showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _LogVitalsSheet(),
    );
  }
}

class _MonitoringItem extends ConsumerWidget {
  const _MonitoringItem({required this.label, required this.value, required this.unit, this.isWarning = false});
  final String label;
  final String value;
  final String unit;
  final bool isWarning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isWarning ? Colors.red : AppTheme.onSurface)),
            const SizedBox(width: 4),
            Text(unit, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}

class _CancerRiskCard extends ConsumerWidget {
  const _CancerRiskCard({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risksAsync = ref.watch(riskPredictionsProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.radar_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Cancer Risk Prediction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          risksAsync.when(
            data: (risksList) {
              final val = risksList.isNotEmpty ? risksList.first.cancerRisk : 0.0;
              final level = val < 30 ? 'Low Risk' : val < 70 ? 'Moderate Risk' : 'High Risk';
              final color = val < 30 ? Colors.green : val < 70 ? Colors.orange : Colors.red;

              return Center(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return ProgressRing(
                      progress: (val / 100.0) * animation.value,
                      size: 140,
                      strokeWidth: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(val * animation.value).round()}%',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.cyanAccent)),
                          Text(level,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 20),
          const Text('Primary Factors:', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            children: [
              StatusBadge(label: 'Genetic Markers', type: StatusType.warning),
              StatusBadge(label: 'Environment', type: StatusType.success),
              StatusBadge(label: 'Lifestyle', type: StatusType.info),
            ],
          ),
          const Spacer(),
          PrimaryButton(label: 'Prevention Tips', onPressed: () => _showTipsDialog(context, ref)),
        ],
      ),
    );
  }
  
  void _showTipsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.navy800,
        title: const Text('AI Health Recommendations'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Maintain a balanced diet rich in antioxidants.'),
            SizedBox(height: 8),
            Text('• Schedule regular screenings as recommended by age.'),
            SizedBox(height: 8),
            Text('• Avoid known environmental carcinogens.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))
        ],
      ),
    );
  }
}


class _SymptomCheckerCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(symptomHistoryProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Symptom Checker history', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) return const Text('No history available', style: TextStyle(fontSize: 12));
              final reversedHistory = history.reversed.toList();
              
              return Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reversedHistory.length > 3 ? 3 : reversedHistory.length,
                  itemBuilder: (context, index) {
                    final item = reversedHistory[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.symptoms.join(', '), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                          StatusBadge(label: item.severity, type: item.severity == 'High' ? StatusType.error : StatusType.warning),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const Spacer(),
          PrimaryButton(label: 'New Check', onPressed: () => _showSymptomDialog(context, ref)),
        ],
      ),
    );
  }

  void _showSymptomDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _SymptomCheckSheet(),
    );
  }
}

class _HealthRiskScoreCard extends ConsumerWidget {
  const _HealthRiskScoreCard({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(currentHealthScoreProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Text('Overall Health Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          scoreAsync.when(
            data: (score) {
              final val = score?.score ?? 78.0;
              return Center(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return ProgressRing(
                      progress: (val / 100.0) * animation.value,
                      size: 120,
                      strokeWidth: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(val * animation.value).round()}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                          Text(val > 80 ? 'Excellent' : (val > 60 ? 'Stable' : 'Risk Detected'), 
                               style: TextStyle(fontSize: 10, color: val > 60 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 20),
          const Text('Factors Breakdown:', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Consumer(builder: (context, ref, _) {
            final s = scoreAsync.value;
            return Column(
              children: [
                _FactorBar(label: 'Activity', progress: (s?.activityScore ?? 50.0) / 100),
                const SizedBox(height: 8),
                _FactorBar(label: 'Sleep', progress: (s?.sleepScore ?? 50.0) / 100),
                const SizedBox(height: 8),
                _FactorBar(label: 'Nutrition', progress: (s?.nutritionScore ?? 50.0) / 100),
                const SizedBox(height: 8),
                _FactorBar(label: 'Hydration', progress: (s?.hydrationScore ?? 50.0) / 100),
              ],
            );
          }),
          const Spacer(),
          PrimaryButton(label: 'History Trends', onPressed: () => _showHistoryTrends(context, ref)),
        ],
      ),
    );
  }
  
  void _showHistoryTrends(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navy800,
      builder: (ctx) => const Center(child: Text('History visualization coming soon', style: TextStyle(color: Colors.white))),
    );
  }
}

class _FactorBar extends ConsumerWidget {
  const _FactorBar({required this.label, required this.progress});
  final String label;
  final double progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        SizedBox(width: 65, child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.outline,
              color: AppTheme.cyanAccent.withOpacity(0.7),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}

class _LogMetricsSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LogMetricsSheet> createState() => _LogMetricsSheetState();
}

class _LogMetricsSheetState extends ConsumerState<_LogMetricsSheet> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _sleepController = TextEditingController();
  final _actLevelController = TextEditingController(text: '5');
  final _hydrationController = TextEditingController(text: '8');
  bool _smoking = false;
  bool _alcohol = false;

  @override
  void dispose() {
    _actLevelController.dispose();
    _hydrationController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Health Metrics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: AppTextField(controller: _weightController, label: 'Weight', hint: 'kg', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(controller: _heightController, label: 'Height', hint: 'cm', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _sleepController, label: 'Sleep', hint: 'Hours', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _NumericField(label: 'Activity Level (1-10)', controller: _actLevelController, hint: 'e.g. 5'),
          const SizedBox(height: 12),
          _NumericField(label: 'Hydration (glasses)', controller: _hydrationController, hint: 'e.g. 8'),
          CheckboxListTile(
            title: const Text('Smoker?', style: TextStyle(color: Colors.white)),
            value: _smoking, 
            onChanged: (v) => setState(() => _smoking = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('Alcohol Consumption?', style: TextStyle(color: Colors.white)),
            value: _alcohol, 
            onChanged: (v) => setState(() => _alcohol = v ?? false),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save & Calculate Risks', onPressed: _save),
        ],
      ),
    );
  }

  void _save() async {
    final w = double.tryParse(_weightController.text) ?? 70;
    final h = double.tryParse(_heightController.text) ?? 170;
    final bmi = w / ((h/100)*(h/100));
    final slp = double.tryParse(_sleepController.text) ?? 8;
    final act = int.tryParse(_actLevelController.text) ?? 5;
    final hyd = int.tryParse(_hydrationController.text) ?? 8;
    
    final metric = PhysicalHealthMetric(
      date: DateTime.now(),
      weight: w,
      height: h,
      bmi: bmi,
      bloodPressure: '120/80', // Default if not logged in vitals
      bloodSugar: 100,
      cholesterol: 180,
      activityLevel: act,
      sleepHours: slp,
      hydration: hyd,
    );

    final service = ref.read(physicalHealthServiceProvider);
    await service.saveHealthMetric(metric);

    // Calculate risks
    final risks = PhysicalHealthEngine.calculateAllRisks(
      age: 30, // Default or from profile
      bmi: bmi,
      activityLevel: act,
      familyHistory: true, // Default
      sleepHours: slp,
      smokingStatus: _smoking,
      alcoholConsumption: _alcohol,
    );
    await service.saveRiskPrediction(risks);

    // Calculate score
    final score = PhysicalHealthEngine.calculateHealthScore(
      bmi: bmi,
      activityLevel: act,
      sleepHours: slp,
      hydration: hyd,
      bp: '120/80',
      sugar: 100,
      cholesterol: 180,
    );
    await service.saveHealthScore(score);

    ref.invalidate(healthMetricsProvider);
    ref.invalidate(riskPredictionsProvider);
    ref.invalidate(currentHealthScoreProvider);
    Navigator.pop(context);
  }
}

class _SymptomCheckSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SymptomCheckSheet> createState() => _SymptomCheckSheetState();
}

class _SymptomCheckSheetState extends ConsumerState<_SymptomCheckSheet> {
  final List<String> _selected = [];
  String _severity = 'Low';

  final List<String> _options = ['Fever', 'Cough', 'Headache', 'Fatigue', 'Chest pain', 'Shortness of breath'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Check Symptoms', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _options.map((s) => FilterChip(
              label: Text(s),
              selected: _selected.contains(s),
              onSelected: (sel) => setState(() => sel ? _selected.add(s) : _selected.remove(s)),
              selectedColor: AppTheme.cyanAccent.withOpacity(0.3),
              checkmarkColor: AppTheme.cyanAccent,
            )).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Severity', style: TextStyle(color: Colors.white70)),
          DropdownButton<String>(
            value: _severity,
            dropdownColor: AppTheme.navy800,
            style: const TextStyle(color: Colors.white),
            items: ['Low', 'Moderate', 'High'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _severity = v!),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Run Analysis', onPressed: _selected.isEmpty ? null : _analyze),
        ],
      ),
    );
  }

  void _analyze() async {
    final result = PhysicalHealthEngine.checkSymptoms(_selected, _severity);
    final log = SymptomLog(
      date: DateTime.now(),
      symptoms: _selected,
      severity: result['riskLevel'],
      possibleConditions: List<String>.from(result['conditions']),
    );
    
    await ref.read(physicalHealthServiceProvider).saveSymptomLog(log);
    ref.invalidate(symptomHistoryProvider);
    Navigator.pop(context);
  }
}

class _LogVitalsSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LogVitalsSheet> createState() => _LogVitalsSheetState();
}

class _LogVitalsSheetState extends ConsumerState<_LogVitalsSheet> {
  final _bpController = TextEditingController(text: '120/80');
  final _sugarController = TextEditingController();
  final _cholController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Chronic Condition Monitoring', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          AppTextField(controller: _bpController, label: 'Blood Pressure', hint: 'e.g. 120/80'),
          const SizedBox(height: 12),
          AppTextField(controller: _sugarController, label: 'Blood Sugar', hint: 'mg/dL', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppTextField(controller: _cholController, label: 'Cholesterol', hint: 'mg/dL', keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save Vitals', onPressed: _save),
        ],
      ),
    );
  }

  void _save() async {
    final log = ChronicDiseaseLog(
      date: DateTime.now(),
      bloodPressure: _bpController.text,
      bloodSugar: int.tryParse(_sugarController.text) ?? 100,
      cholesterol: int.tryParse(_cholController.text) ?? 180,
      notes: '',
    );
    await ref.read(physicalHealthServiceProvider).saveChronicLog(log);
    ref.invalidate(chronicEntriesProvider);
    Navigator.pop(context);
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({required this.label, required this.controller, required this.hint});
  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: AppTheme.navy700,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
