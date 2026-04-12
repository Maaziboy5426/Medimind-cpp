import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/mental_health_service.dart';
import '../../../../services/mental_health_engine.dart';
import '../../../../services/speech_service.dart';
import '../../../../services/gemini_health_service.dart';
import '../../../../services/storage_provider.dart';
import '../../../../models/mental_health_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/widgets.dart';

class MentalHealthScreen extends ConsumerStatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  ConsumerState<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends ConsumerState<MentalHealthScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isAnalyzing = false;
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );
    _scoreController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isAnalyzing = true);

    // Call Gemini — falls back to local engine automatically
    final gemini = ref.read(geminiHealthServiceProvider);
    final result = await gemini.analyzeMood(text);

    final moodLog = MoodLog(
      date: DateTime.now(),
      moodLabel: result.moodLabel,
      confidence: result.confidence,
      textEntry: text,
      voiceEntry: '',
      stressScore: result.stressScore,
    );

    await ref.read(mentalHealthServiceProvider).saveMoodLog(moodLog);

    final stressRecord = StressRecord(
      date: DateTime.now(),
      sleepHours: 7.0,
      activityLevel: 5,
      hydrationLevel: 5,
      stressScore: result.stressScore,
    );
    await ref.read(mentalHealthServiceProvider).saveStressRecord(stressRecord);

    ref.invalidate(moodLogsProvider);
    ref.invalidate(mentalWellnessScoreProvider);
    ref.invalidate(streakProvider);

    _textController.clear();
    if (mounted) {
      setState(() => _isAnalyzing = false);
      final badge = result.fromAI ? '✨ AI' : '📱 Local';
      final msg = result.insight.isNotEmpty
          ? '$badge · ${result.moodLabel}: ${result.insight}'
          : '$badge · Mood: ${result.moodLabel} (Stress: ${result.stressScore}/100)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.cyanAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final moodLogsAsync = ref.watch(moodLogsProvider);
    final wellnessScoreAsync = ref.watch(mentalWellnessScoreProvider);
    final moodLogs = moodLogsAsync.value ?? [];
    final lastMood = moodLogs.isNotEmpty ? moodLogs.first : null;

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
                    horizontalPadding, 20, horizontalPadding, 12),
                child: Text(
                  'Mental Wellness Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WellnessScoreHero(animation: _scoreAnimation, scoreAsync: wellnessScoreAsync, lastMood: lastMood),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  isDesktop
                      ? [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _MoodInputCard(
                                    controller: _textController,
                                    focusNode: _focusNode,
                                    isAnalyzing: _isAnalyzing,
                                    onAnalyze: _submit,
                                    lastLog: lastMood,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(child: _MoodTrendGraph(logs: moodLogs)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _StressAnxietyCard(logs: moodLogs)),
                                const SizedBox(width: 16),
                                Expanded(child: _AIMentalInsightsCard(logs: moodLogs)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ]
                      : [
                          _MoodInputCard(
                            controller: _textController,
                            focusNode: _focusNode,
                            isAnalyzing: _isAnalyzing,
                            onAnalyze: _submit,
                            lastLog: lastMood,
                          ),
                          const SizedBox(height: 16),
                          _MoodTrendGraph(logs: moodLogs),
                          const SizedBox(height: 16),
                          _StressAnxietyCard(logs: moodLogs),
                          const SizedBox(height: 16),
                          _AIMentalInsightsCard(logs: moodLogs),
                          const SizedBox(height: 16),
                        ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 16, horizontalPadding, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _BreathingExerciseCard(),
                  const SizedBox(height: 16),
                  _MentalWellnessSuggestions(lastLog: lastMood),
                  const SizedBox(height: 16),
                  _VoiceMoodDetectionCard(),
                  const SizedBox(height: 16),
                  _MoodJournalCard(),
                  const SizedBox(height: 16),
                  _MentalHealthAlerts(logs: moodLogs),
                  const SizedBox(height: 16),
                  _DailyMoodStreakCard(),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WellnessScoreHero extends ConsumerWidget {
  _WellnessScoreHero({required this.animation, required this.scoreAsync, this.lastMood});
  final Animation<double> animation;
  final AsyncValue<double> scoreAsync;
  final MoodLog? lastMood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodLabel = lastMood?.moodLabel ?? 'Neutral';
    final stressLabel = lastMood == null
        ? 'Unknown'
        : (lastMood!.stressScore > 70 ? 'High' : (lastMood!.stressScore > 40 ? 'Medium' : 'Low'));
    final anxietyLabel = lastMood == null
        ? 'Unknown'
        : (lastMood!.stressScore > 60 ? 'Moderate' : 'Mild');

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Mental Wellness Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final score = scoreAsync.value ?? 75.0;
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
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cyanAccent,
                      ),
                    ),
                    StatusBadge(
                      label: score >= 80 ? 'Excellent' : (score >= 60 ? 'Stable' : 'Needs Care'),
                      type: score >= 80 ? StatusType.success : (score >= 60 ? StatusType.info : StatusType.error),
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
              _buildIndicatorItem(Icons.sentiment_satisfied_rounded, 'Mood', moodLabel),
              _buildIndicatorItem(Icons.bolt_rounded, 'Stress', stressLabel),
              _buildIndicatorItem(Icons.waves_rounded, 'Anxiety', anxietyLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem(IconData icon, String label, String value) {
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
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
      ],
    );
  }
}

class _MoodInputCard extends ConsumerWidget {
  const _MoodInputCard({
    required this.controller,
    required this.focusNode,
    required this.isAnalyzing,
    required this.onAnalyze,
    this.lastLog,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;
  final MoodLog? lastLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              const Icon(Icons.psychology_alt_rounded, color: AppTheme.cyanAccent, size: 22),
              const SizedBox(width: 8),
              const Text('Mood Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (lastLog != null)
                Text(_getEmoji(lastLog!.moodLabel), style: const TextStyle(fontSize: 26)),
            ],
          ),

          // ── Last result chip ──
          if (lastLog != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cyanAccent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Last result ', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                      Text(
                        '· ${DateFormat('hh:mm a').format(lastLog!.date)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      Text(
                        '${lastLog!.confidence}% confidence',
                        style: const TextStyle(fontSize: 11, color: AppTheme.cyanAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_getEmoji(lastLog!.moodLabel)}  ${lastLog!.moodLabel}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 10),
                  // Stress bar
                  Row(
                    children: [
                      const Text('Stress  ', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: lastLog!.stressScore / 100.0,
                            minHeight: 6,
                            backgroundColor: AppTheme.outline.withOpacity(0.4),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              lastLog!.stressScore > 70
                                  ? AppTheme.error
                                  : lastLog!.stressScore > 40
                                      ? AppTheme.warning
                                      : AppTheme.success,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${lastLog!.stressScore}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          // ── Input ──
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 3,
            style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe how you feel… (e.g. I feel anxious and overwhelmed today)',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
              fillColor: AppTheme.navy600.withOpacity(0.3),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.cyanAccent),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tip: Be descriptive — the more detail you share, the more accurate the analysis.',
            style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant.withOpacity(0.75)),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Analyze My Mood',
            onPressed: isAnalyzing ? null : onAnalyze,
            isLoading: isAnalyzing,
          ),
        ],
      ),
    );
  }

  String _getEmoji(String label) {
    switch (label.toLowerCase()) {
      case 'happy':       return '😊';
      case 'grateful':    return '🙏';
      case 'energetic':   return '⚡';
      case 'calm':        return '😌';
      case 'neutral':     return '😐';
      case 'anxious':     return '😰';
      case 'sad':         return '😢';
      case 'angry':       return '😠';
      case 'overwhelmed': return '😤';
      case 'depressed':   return '💔';
      default:            return '😐';
    }
  }
}

class _StressAnxietyCard extends ConsumerWidget {
  const _StressAnxietyCard({required this.logs});
  final List<MoodLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastLog = logs.isNotEmpty ? logs.first : null;
    final stressScore = lastLog?.stressScore ?? 50;
    
    // Simulate some logic for anxiety based on stress
    final anxietyScore = (stressScore * 0.8).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stress & Anxiety', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          _RiskBar(
            label: 'Stress Risk', 
            value: stressScore / 100.0, 
            status: stressScore > 70 ? 'High' : (stressScore > 30 ? 'Moderate' : 'Low'), 
            color: stressScore > 70 ? Colors.red : (stressScore > 30 ? Colors.yellow : Colors.green)
          ),
          const SizedBox(height: 20),
          _RiskBar(
            label: 'Anxiety Level', 
            value: anxietyScore / 100.0, 
            status: anxietyScore > 70 ? 'High' : (anxietyScore > 30 ? 'Moderate' : 'Low'), 
            color: anxietyScore > 70 ? Colors.red : (anxietyScore > 30 ? Colors.orange : Colors.green)
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Score', style: TextStyle(fontSize: 14)),
              Text('${((stressScore + anxietyScore) / 20).toStringAsFixed(1)} / 10', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskBar extends ConsumerWidget {
  const _RiskBar({required this.label, required this.value, required this.status, required this.color});
  final String label;
  final double value;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppTheme.outline.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _MoodTrendGraph extends ConsumerWidget {
  const _MoodTrendGraph({required this.logs});
  final List<MoodLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentLogs = logs.reversed.toList();
    final spots = List.generate(recentLogs.length, (index) {
      final log = recentLogs[index];
      final score = MentalHealthEngine.moodToScore(log.moodLabel).toDouble();
      return FlSpot(index.toDouble(), score);
    });

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mood Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? const Center(
                    child: Text('No data yet', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) {
                              if (v >= 0 && v < recentLogs.length) {
                                return Text(
                                  DateFormat('E').format(recentLogs[v.toInt()].date).toLowerCase(),
                                  style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                      maxY: 8,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppTheme.cyanAccent,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.cyanAccent.withOpacity(0.1),
                          ),
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AIMentalInsightsCard extends ConsumerWidget {
  const _AIMentalInsightsCard({required this.logs});
  final List<MoodLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = MentalHealthEngine.generateInsights(
      stressScore: logs.isNotEmpty ? logs.first.stressScore : 50,
      recentMoods: logs,
      sleepHours: 7.0, // Should come from stress records
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_rounded, color: AppTheme.cyanAccent, size: 22),
              SizedBox(width: 8),
              Text('AI Mental Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          for (var insight in insights) ...[
            Text(
              insight,
              style: const TextStyle(fontSize: 14, color: AppTheme.onSurface),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _MentalWellnessSuggestions extends ConsumerWidget {
  const _MentalWellnessSuggestions({this.lastLog});
  final MoodLog? lastLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stressScore = lastLog?.stressScore ?? 50;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mental Wellness Suggestions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _SuggestionItem(Icons.air_rounded, 'Try a 3-minute breathing exercise'),
          _SuggestionItem(Icons.directions_walk_rounded, 'Take a short walk outside'),
          _SuggestionItem(Icons.water_drop_rounded, 'Drink some water'),
          _SuggestionItem(Icons.phonelink_erase_rounded, 'Reduce screen time'),
        ],
      ),
    );
  }
}

class _SuggestionItem extends ConsumerWidget {
  const _SuggestionItem(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.cyanAccent, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _BreathingExerciseCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BreathingExerciseCard> createState() => _BreathingExerciseCardState();
}

class _BreathingExerciseCardState extends ConsumerState<_BreathingExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isActive = false;
  String _phase = 'Ready';
  int _secondsPassed = 0;
  Timer? _timer;
  int _stressBefore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..addListener(() {
        final t = _controller.value * 14;
        String p;
        if (t < 4) p = 'Inhale';
        else if (t < 8) p = 'Hold';
        else p = 'Exhale';
        if (_phase != p) setState(() => _phase = p);
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startSession() {
    _showStressPicker(context, true);
  }

  void _showStressPicker(BuildContext context, bool isBefore) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBefore ? 'How stressed do you feel?' : 'How stressed do you feel now?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(11, (i) => ListTile(
            title: Text('${i * 10}'),
            onTap: () {
              Navigator.pop(ctx);
              if (isBefore) {
                _stressBefore = i * 10;
                _beginExercise();
              } else {
                _endExercise(i * 10);
              }
            },
          )),
        ),
      ),
    );
  }

  void _beginExercise() {
    setState(() {
      _isActive = true;
      _secondsPassed = 0;
      _controller.repeat();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsPassed++);
      if (_secondsPassed >= 180) { // 3 minutes
        _stopSession();
      }
    });
  }

  void _stopSession() {
    _timer?.cancel();
    _controller.stop();
    setState(() {
      _isActive = false;
      _phase = 'Finished';
    });
    _showStressPicker(context, false);
  }

  Future<void> _endExercise(int stressAfter) async {
    final session = BreathingSession(
      date: DateTime.now(),
      duration: _secondsPassed,
      stressBefore: _stressBefore,
      stressAfter: stressAfter,
    );
    await ref.read(mentalHealthServiceProvider).saveBreathingSession(session);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Breathing session saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.air_rounded, color: AppTheme.cyanAccent),
              const SizedBox(width: 8),
              const Text('Breathing Exercise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              const Text('3 min session', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double scale = 1.0;
              if (_isActive) {
                 final t = _controller.value * 14;
                 if (t < 4) scale = 1.0 + 0.5 * (t / 4);
                 else if (t < 8) scale = 1.5;
                 else scale = 1.5 - 0.5 * ((t - 8) / 6);
              }
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cyanAccent.withOpacity(0.1 * scale),
                  border: Border.all(color: AppTheme.cyanAccent, width: 2),
                ),
                child: Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.cyanAccent),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(_phase, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
          const SizedBox(height: 16),
          if (_isActive) ...[
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 40),
               child: LinearProgressIndicator(
                 value: _secondsPassed / 180,
                 backgroundColor: AppTheme.outline,
                 color: AppTheme.cyanAccent,
                 minHeight: 4,
               ),
             ),
             const SizedBox(height: 8),
             Text('Progress: ${(_secondsPassed ~/ 60)}:${(_secondsPassed % 60).toString().padLeft(2, '0')} / 3:00', 
                  style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
             const SizedBox(height: 24),
          ],
          PrimaryButton(
            label: _isActive ? 'Stop' : 'Start 3-Minute Session',
            onPressed: _isActive ? _stopSession : _startSession,
            backgroundColor: _isActive ? AppTheme.error : AppTheme.cyanAccent,
          ),
        ],
      ),
    );
  }
}

class _VoiceMoodDetectionCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VoiceMoodDetectionCard> createState() => _VoiceMoodDetectionCardState();
}

class _VoiceMoodDetectionCardState extends ConsumerState<_VoiceMoodDetectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isListening = false;
  String _recognizedText = '';
  String _detectedMood = 'None';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    final speech = ref.read(speechServiceProvider);
    if (_isListening) {
      await speech.stopListening();
      setState(() => _isListening = false);
      _analyzeVoiceMood();
    } else {
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });
      await speech.startListening((text) {
        setState(() => _recognizedText = text);
      });
    }
  }

  void _analyzeVoiceMood() {
    if (_recognizedText.isEmpty) return;
    final sentiment = MentalHealthEngine.analyzeSentiment(_recognizedText);
    String mood = 'Neutral';
    if (sentiment > 1) mood = 'Happy';
    else if (sentiment < -1) mood = 'Stressed';
    
    setState(() => _detectedMood = mood);
    
    // Save to Hive
    ref.read(mentalHealthServiceProvider).saveMoodLog(MoodLog(
      date: DateTime.now(),
      moodLabel: mood,
      confidence: 80,
      textEntry: '',
      voiceEntry: _recognizedText,
      stressScore: mood == 'Stressed' ? 65 : 35,
    )).then((_) {
      ref.invalidate(moodLogsProvider);
      ref.invalidate(mentalWellnessScoreProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: AppTheme.cyanAccent),
              const SizedBox(width: 8),
              const Text('Voice Mood Detection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (_isListening)
                const StatusBadge(label: 'Listening...', type: StatusType.info),
            ],
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: _toggleListening,
            borderRadius: BorderRadius.circular(50),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cyanAccent.withOpacity(_isListening ? 0.1 + 0.1 * _pulseController.value : 0.1),
                    border: Border.all(
                      color: AppTheme.cyanAccent.withOpacity(_isListening ? 0.3 + 0.4 * _pulseController.value : 0.2),
                      width: _isListening ? 2 + 2 * _pulseController.value : 2,
                    ),
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 48,
                    color: AppTheme.cyanAccent,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(_isListening ? 'Listening: $_recognizedText' : 'Tap to analyze your voice mood', 
               textAlign: TextAlign.center,
               style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricMini(label: 'Emotion', value: _detectedMood),
              const _MetricMini(label: 'Confidence', value: '88%'),
              _MetricMini(label: 'Stress', value: _detectedMood == 'Stressed' ? 'High' : 'Low'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricMini extends ConsumerWidget {
  const _MetricMini({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
      ],
    );
  }
}

class _MoodJournalCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MoodJournalCard> createState() => _MoodJournalCardState();
}

class _MoodJournalCardState extends ConsumerState<_MoodJournalCard> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSaving = true);
    
    final sentiment = MentalHealthEngine.analyzeSentiment(text);
    final entry = JournalEntry(
      date: DateTime.now(),
      text: text,
      sentimentScore: sentiment,
    );
    
    await ref.read(mentalHealthServiceProvider).saveJournalEntry(entry);
    ref.invalidate(mentalWellnessScoreProvider);
    
    _controller.clear();
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal entry saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mood Journal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write a short journal entry...',
              fillColor: AppTheme.navy600.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save Entry', 
            onPressed: _isSaving ? null : _save,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }
}

class _MentalHealthAlerts extends ConsumerWidget {
  const _MentalHealthAlerts({required this.logs});
  final List<MoodLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> alerts = [];
    
    if (logs.isNotEmpty) {
      final last = logs.first;
      if (last.stressScore > 80) {
        alerts.add(_AlertCard('Critical stress detected! Try a breathing session.', Icons.warning_rounded, AppTheme.error));
      }
      
      // Check 3 day trend for alerts
      if (logs.length >= 3) {
        bool allLow = logs.take(3).every((l) => _moodScore(l.moodLabel) <= 2);
        if (allLow) {
          alerts.add(const _AlertCard('Low mood detected for 3 days. We suggest a wellness activity.', Icons.volunteer_activism_rounded, Colors.purpleAccent));
        }
      }
    }

    if (alerts.isEmpty) {
      alerts.add(const _AlertCard('No urgent alerts. Looking good!', Icons.check_circle_outline_rounded, Colors.green));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        ...alerts.expand((a) => [a, const SizedBox(height: 12)]),
      ],
    );
  }

  int _moodScore(String label) {
    switch (label.toLowerCase()) {
      case 'happy': return 5;
      case 'calm': return 4;
      case 'neutral': return 3;
      case 'stressed': return 2;
      case 'depressed': return 1;
      default: return 3;
    }
  }
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard(this.message, this.icon, this.color);
  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _DailyMoodStreakCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final streak = streakAsync.value ?? 0;

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mood Tracking Streak', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$streak Days 🔥', style: TextStyle(color: AppTheme.cyanAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final active = i < streak % 8; // Just for visual demo
              return Column(
                children: [
                  Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i], style: const TextStyle(fontSize: 10, color: AppTheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: active
                            ? const LinearGradient(
                                colors: [AppTheme.cyanAccent, Color(0xFF00A8CC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: active ? null : AppTheme.navy600,
                        border: Border.all(
                          color: active ? AppTheme.cyanAccent.withOpacity(0.5) : AppTheme.outline,
                          width: 1,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppTheme.cyanAccent.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                               ]
                            : null,
                      ),
                      child: active
                          ? const Icon(Icons.check_rounded, size: 20, color: AppTheme.navy900)
                          : null,
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
