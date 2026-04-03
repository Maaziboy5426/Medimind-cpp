import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.defaultPadding,
                  24,
                  AppConstants.defaultPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MedMind',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.cyanAccent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your health at a glance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.surfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  AppCard(
                    child: Row(
                      children: [
                        ProgressRing(
                          progress: 0.72,
                          size: 64,
                          strokeWidth: 5,
                          child: Text(
                            '72%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.cyanAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly adherence',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppTheme.surfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const StatusBadge(label: 'On track', type: StatusType.success),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Next reminder',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppTheme.surfaceVariant,
                                  ),
                            ),
                            const StatusBadge(label: 'Soon', type: StatusType.info),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Medication at 2:00 PM',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.cyanAccent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Log activity',
                    icon: Icon(Icons.add_rounded, size: 20, color: AppTheme.navy900),
                    onPressed: () {},
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
