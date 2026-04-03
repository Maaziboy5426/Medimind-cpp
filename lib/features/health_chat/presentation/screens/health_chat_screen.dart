import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/chat_models.dart';
import '../../../../services/storage_provider.dart';
import '../../../../services/activity_tracker_service.dart';
import '../../../../shared/widgets/widgets.dart';

class HealthChatScreen extends ConsumerStatefulWidget {
  const HealthChatScreen({super.key});

  @override
  ConsumerState<HealthChatScreen> createState() => _HealthChatScreenState();
}

class _HealthChatScreenState extends ConsumerState<HealthChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  static const _quickSuggestions = [
    {'icon': Icons.bedtime_rounded, 'label': 'How can I sleep better?'},
    {'icon': Icons.psychology_rounded, 'label': 'I feel anxious today'},
    {'icon': Icons.water_drop_rounded, 'label': 'Tips for staying hydrated'},
    {'icon': Icons.fitness_center_rounded, 'label': 'What exercises help stress?'},
    {'icon': Icons.restaurant_rounded, 'label': 'Healthy eating tips'},
    {'icon': Icons.battery_charging_full_rounded, 'label': 'Why do I feel tired often?'},
    {'icon': Icons.access_time_rounded, 'label': 'How to improve my sleep cycle?'},
    {'icon': Icons.bolt_rounded, 'label': 'Best foods for energy'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    _textController.clear();
    await ref.read(chatMessagesProvider.notifier).sendMessage(text);
    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    const _IntroCard(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Conversations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: () => ref.read(chatMessagesProvider.notifier).clearChat(),
                            icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppTheme.error),
                            label: const Text('Clear Chat', style: TextStyle(color: AppTheme.error, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const _SectionHeader(title: 'Quick Suggestions'),
                    _buildSuggestions(),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                      child: Column(
                        children: [
                          if (messages.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text('No messages yet. Ask me anything!', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                            ),
                          ...messages.map((m) => _ChatBubble(message: m)),
                          if (_isLoading) _TypingBubble(),
                        ],
                      ),
                    ),

                    const _SectionHeader(title: 'Personalized Insights'),
                    _PersonalizedInsightsSection(),

                    const _SectionHeader(title: 'Quick Health Tools'),
                    _buildQuickTools(),
                    
                    const SizedBox(height: 100), // Space for input area
                  ],
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _quickSuggestions.map((s) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: AppTheme.navy600.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => _send(s['label'] as String),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.outline),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(s['icon'] as IconData, color: AppTheme.cyanAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        s['label'] as String,
                        style: const TextStyle(fontSize: 13, color: AppTheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickTools() {
    final tools = [
      {'icon': Icons.health_and_safety_rounded, 'label': 'Symptom Checker', 'route': '/physical-health'},
      {'icon': Icons.psychology_alt_rounded, 'label': 'Mental Health', 'route': '/mental-health'},
      {'icon': Icons.restaurant_rounded, 'label': 'Nutrition Advice', 'route': '/activity-tracker'},
      {'icon': Icons.fitness_center_rounded, 'label': 'Fitness Guidance', 'route': '/activity-tracker'},
      {'icon': Icons.medication_rounded, 'label': 'Medicine Questions', 'route': '/medicine-reminder'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tools.map((t) {
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 44) / 2,
            child: Material(
              color: AppTheme.navy600,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => context.go(t['route'] as String),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(t['icon'] as IconData, color: AppTheme.cyanAccent, size: 28),
                      const SizedBox(height: 12),
                      Text(
                        t['label'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.navy900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.navy700,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        hintText: 'Ask MedMind about your health...',
                        hintStyle: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(color: AppTheme.onSurface, fontSize: 15),
                      onSubmitted: _send,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppTheme.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppTheme.cyanAccent,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              onTap: () => _send(_textController.text),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: AppTheme.navy900, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalizedInsightsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(todayActivityProvider).value;
    final hydration = ref.watch(todayHydrationProvider).value ?? 0;
    final sleep = ref.watch(sleepHistoryProvider).value ?? [];
    
    final lastSleep = sleep.isNotEmpty ? sleep.first.sleepDuration : 8.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _InsightCard(
            title: 'Sleep Insight',
            description: lastSleep < 6 
                ? 'You slept less than recommended. Aim for 7-8 hours.' 
                : 'Your sleep duration is looking good!',
            icon: Icons.nightlight_round_rounded,
            color: Colors.indigoAccent,
          ),
          _InsightCard(
            title: 'Hydration Insight',
            description: hydration < 2000 
                ? 'You drank ${((1 - hydration/2000)*100).round()}% less water than your goal today.' 
                : 'Excellent hydration level today!',
            icon: Icons.water_drop_rounded,
            color: Colors.blueAccent,
          ),
          _InsightCard(
            title: 'Activity Insight',
            description: (activity?.steps ?? 0) < 5000 
                ? 'Try to take a short walk to reach your step goal.' 
                : 'Great job staying active today!',
            icon: Icons.bolt_rounded,
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cyanAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppTheme.cyanAccent, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask MedMind AI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.onSurface),
            ),
            const SizedBox(height: 12),
            const Text(
              'Get instant health guidance, symptom explanations, wellness tips, and lifestyle recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 20),
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _TopicChip(label: 'Sleep health'),
                _TopicChip(label: 'Stress management'),
                _TopicChip(label: 'Nutrition'),
                _TopicChip(label: 'Exercise'),
                _TopicChip(label: 'Symptoms'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.navy600,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppTheme.cyanAccent, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.onSurface, letterSpacing: 0.5),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navy600.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: AppTheme.onSurface, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.cyanAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppTheme.cyanAccent, size: 18),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.cyanAccent.withOpacity(0.2)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.cyanAccent.withOpacity(0.4)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.cyanAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: AppTheme.cyanAccent, size: 18),
            ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.cyanAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy_rounded, color: AppTheme.cyanAccent, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final delay = i * 0.2;
                    final value = ((_controller.value + delay) % 1.0);
                    final opacity = 0.3 + 0.7 * (0.5 + 0.5 * (value < 0.5 ? value * 2 : 2 - value * 2));
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.cyanAccent.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
