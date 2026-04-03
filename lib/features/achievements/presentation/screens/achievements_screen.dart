import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medmind/core/theme/app_theme.dart';
import 'package:medmind/services/storage_provider.dart';
import 'package:medmind/models/app_backend_models.dart';
import 'package:medmind/shared/widgets/widgets.dart';
import 'package:medmind/services/settings_service.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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
    final achievements = ref.watch(achievementsStreamProvider).value ?? [];
    final settings = ref.watch(appSettingsProvider);
    final dailyStepGoal = settings.dailyStepGoal;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildLeftColumn(achievements, dailyStepGoal)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildRightColumn(achievements, dailyStepGoal)),
                      ],
                    )
                  else
                    ..._buildMobileLayout(achievements, dailyStepGoal),
                  const SizedBox(height: 24),
                  _buildMotivationInsights(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Track your wellness progress and unlock achievements",
          style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMobileLayout(List<Achievement> achievements, int dailyStepGoal) {
    return [
      _buildDailyStreak(),
      const SizedBox(height: 24),
      _buildAchievementBadges(achievements),
      const SizedBox(height: 24),
      _buildWellnessChallenges(dailyStepGoal),
      const SizedBox(height: 24),
      _buildMilestoneTracker(dailyStepGoal),
    ];
  }

  Widget _buildLeftColumn(List<Achievement> achievements, int dailyStepGoal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDailyStreak(),
        const SizedBox(height: 24),
        _buildWellnessChallenges(dailyStepGoal),
      ],
    );
  }

  Widget _buildRightColumn(List<Achievement> achievements, int dailyStepGoal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAchievementBadges(achievements),
        const SizedBox(height: 24),
        _buildMilestoneTracker(dailyStepGoal),
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

  Widget _buildDailyStreak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Daily Wellness Streak"),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceVariant,
                AppTheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cyanAccent.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            "6 Days",
                            style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Current Streak",
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Longest Streak: 12 Days",
                        style: TextStyle(
                          color: AppTheme.cyanAccent.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                         ),
                      ),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: 6 / 12,
                          strokeWidth: 8,
                          backgroundColor: AppTheme.outline,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: Colors.orangeAccent, size: 32),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.navy900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "\"You're on a 6 day healthy streak!\"",
                      style: TextStyle(
                        color: AppTheme.cyanAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ["M", "T", "W", "T", "F", "S", "S"].asMap().entries.map((entry) {
                        int idx = entry.key;
                        bool isActive = idx < 6; // 6 days active
                        return Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? Colors.orangeAccent : AppTheme.navy600,
                          ),
                          child: Center(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: isActive ? AppTheme.navy900 : AppTheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadges(List<Achievement> achievements) {
    // If we have real achievements, use them, otherwise mock.
    final displayAchievements = achievements.isNotEmpty ? achievements : [
      Achievement(id: '1', title: "First 1000 Steps", description: "Take 1000 steps in a day", isUnlocked: true),
      Achievement(id: '2', title: "7 Day Mood Tracking", description: "Track mood for 7 days in a row", isUnlocked: true),
      Achievement(id: '3', title: "Hydration Master", description: "Drink 8 glasses of water for 5 days", isUnlocked: false),
      Achievement(id: '4', title: "Sleep Champion", description: "Maintain sleep schedule", isUnlocked: true),
      Achievement(id: '5', title: "Fitness Starter", description: "Complete your first workout session", isUnlocked: false),
      Achievement(id: '6', title: "Consistency Hero", description: "Maintain a 5 day global streak", isUnlocked: true),
      Achievement(id: '7', title: "Wellness Explorer", description: "Use all main tracking features", isUnlocked: false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Achievement Badges"),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: displayAchievements.length,
            itemBuilder: (context, index) {
              final achievement = displayAchievements[index];
              final unlocked = achievement.isUnlocked;
              
              IconData icon = Icons.workspace_premium;
              if (achievement.title.contains("Steps")) icon = Icons.directions_walk;
              if (achievement.title.contains("Mood")) icon = Icons.emoji_emotions;
              if (achievement.title.contains("Hydration")) icon = Icons.water_drop;
              if (achievement.title.contains("Sleep")) icon = Icons.bedtime;
              if (achievement.title.contains("Fitness")) icon = Icons.fitness_center;
              if (achievement.title.contains("Explorer")) icon = Icons.explore;

              final child = Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: unlocked
                          ? LinearGradient(
                              colors: [AppTheme.cyanAccent, AppTheme.cyanDim],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: unlocked ? null : AppTheme.navy600,
                      boxShadow: unlocked
                          ? [
                              BoxShadow(
                                color: AppTheme.cyanAccent.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      icon,
                      color: unlocked ? AppTheme.navy900 : AppTheme.onSurfaceVariant.withOpacity(0.5),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unlocked ? AppTheme.onSurface : AppTheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );

              return Tooltip(
                message: achievement.description,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.navy800,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.outline),
                ),
                textStyle: const TextStyle(color: AppTheme.onSurface, fontSize: 12),
                child: child,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessChallenges(int dailyStepGoal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Wellness Challenges"),
        _buildChallengeCard(
          title: "Walk $dailyStepGoal steps daily for 7 days",
          progress: 5 / 7,
          icon: Icons.directions_walk,
        ),
        const SizedBox(height: 12),
        _buildChallengeCard(
          title: "Drink 8 glasses of water daily for 5 days",
          progress: 3 / 5,
          icon: Icons.water_drop,
        ),
        const SizedBox(height: 12),
        _buildChallengeCard(
          title: "Track mood for 7 consecutive days",
          progress: 2 / 7,
          icon: Icons.self_improvement,
        ),
        const SizedBox(height: 12),
        _buildChallengeCard(
          title: "Sleep 7+ hours for 5 nights",
          progress: 1 / 5,
          icon: Icons.bedtime,
        ),
      ],
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required double progress,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.navy600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.cyanAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Active",
                        style: TextStyle(
                          color: AppTheme.cyanAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppTheme.navy600,
                          color: AppTheme.cyanAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        color: AppTheme.cyanAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTracker(int dailyStepGoal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Milestone Tracker"),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline, width: 1.5),
          ),
          child: Column(
            children: [
              _buildMilestoneRow("Steps Goal", "4280 / $dailyStepGoal", 4280 / dailyStepGoal.toDouble(), AppTheme.cyanAccent),
              const SizedBox(height: 16),
              _buildMilestoneRow("Workout Progress", "3 / 5 days", 3 / 5, Colors.purpleAccent),
              const SizedBox(height: 16),
              _buildMilestoneRow("Sleep Consistency", "6 / 7 days", 6 / 7, Colors.indigoAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneRow(String title, String valueText, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppTheme.navy600,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationInsights() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.navy600.withOpacity(0.8),
            AppTheme.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cyanAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cyanAccent.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cyanAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppTheme.cyanAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "AI Motivation Insights",
                style: TextStyle(
                  color: AppTheme.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "• \"You are 40% closer to your weekly fitness goal.\"\n\n"
            "• \"Consistency is improving your health score.\"\n\n"
            "• \"Try completing today's hydration challenge.\"",
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
