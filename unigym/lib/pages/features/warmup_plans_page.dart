import 'package:flutter/material.dart';

class WarmupPlansPage extends StatelessWidget {
  const WarmupPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Warm-up Plans"),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withOpacity(0.9),
              primary.withOpacity(0.4),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: WarmupPlansContent(primary: primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WarmupPlansContent extends StatelessWidget {
  const WarmupPlansContent({super.key, required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final plans = [
      {
        'title': 'Quick Stretch (5 min)',
        'level': 'Beginner',
        'description': 'Full-body dynamic stretch to get your joints moving.',
        'icon': Icons.accessibility_new,
      },
      {
        'title': 'Cardio Warm-up (10 min)',
        'level': 'Intermediate',
        'description':
            'Light cardio with mobility drills to raise your heart rate.',
        'icon': Icons.directions_run,
      },
      {
        'title': 'Strength Prep (8 min)',
        'level': 'Advanced',
        'description':
            'Activation exercises focused on core, glutes, and shoulders.',
        'icon': Icons.fitness_center,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: primary.withOpacity(0.15),
              child: Icon(
                Icons.local_fire_department,
                color: primary,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Warm up right',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                Text(
                  'Pick a plan to prepare for your workout',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _WarmupPlanCard(
                title: plan['title'] as String,
                level: plan['level'] as String,
                description: plan['description'] as String,
                icon: plan['icon'] as IconData,
                primary: primary,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WarmupPlanCard extends StatelessWidget {
  const _WarmupPlanCard({
    required this.title,
    required this.level,
    required this.description,
    required this.icon,
    required this.primary,
  });

  final String title;
  final String level;
  final String description;
  final IconData icon;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // TODO: Navigate to detailed warm-up routine / start flow
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            level,
                            style: textTheme.labelSmall?.copyWith(
                              color: primary,
                            ),
                          ),
                        ),
                        Text(
                          'View',
                          style: textTheme.labelMedium?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
