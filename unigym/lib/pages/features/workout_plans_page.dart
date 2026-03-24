import 'package:flutter/material.dart';

class WorkoutPlansPage extends StatelessWidget {
  const WorkoutPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Workout Plans',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD932C6), Color(0xFF4A3ED6)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fitness_center_rounded,
                        color: Colors.white, size: 32),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workout Plans',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Choose a plan that matches your goal',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Plans ──
              _WorkoutPlanCard(
                title: 'Push Day',
                subtitle: 'Chest · Shoulders · Triceps',
                level: 'Intermediate',
                duration: '45–60 min',
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF1E88E5),
                exercises: const [
                  _Exercise(name: 'Bench Press', sets: 4, reps: '8–10'),
                  _Exercise(name: 'Overhead Press', sets: 3, reps: '10–12'),
                  _Exercise(name: 'Incline Dumbbell Press', sets: 3, reps: '10–12'),
                  _Exercise(name: 'Lateral Raises', sets: 3, reps: '12–15'),
                  _Exercise(name: 'Tricep Pushdown', sets: 3, reps: '12–15'),
                  _Exercise(name: 'Overhead Tricep Extension', sets: 3, reps: '12'),
                ],
              ),

              const SizedBox(height: 16),

              _WorkoutPlanCard(
                title: 'Pull Day',
                subtitle: 'Back · Biceps · Rear Delts',
                level: 'Intermediate',
                duration: '45–60 min',
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF43A047),
                exercises: const [
                  _Exercise(name: 'Deadlift', sets: 4, reps: '5–6'),
                  _Exercise(name: 'Pull-ups', sets: 3, reps: '8–10'),
                  _Exercise(name: 'Barbell Row', sets: 3, reps: '8–10'),
                  _Exercise(name: 'Seated Cable Row', sets: 3, reps: '10–12'),
                  _Exercise(name: 'Face Pulls', sets: 3, reps: '15'),
                  _Exercise(name: 'Barbell Curl', sets: 3, reps: '10–12'),
                ],
              ),

              const SizedBox(height: 16),

              _WorkoutPlanCard(
                title: 'Leg Day',
                subtitle: 'Quads · Hamstrings · Glutes · Calves',
                level: 'Advanced',
                duration: '50–65 min',
                icon: Icons.directions_walk_rounded,
                color: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFFF9800),
                exercises: const [
                  _Exercise(name: 'Squat', sets: 4, reps: '6–8'),
                  _Exercise(name: 'Romanian Deadlift', sets: 3, reps: '10–12'),
                  _Exercise(name: 'Leg Press', sets: 3, reps: '12–15'),
                  _Exercise(name: 'Leg Curl', sets: 3, reps: '12–15'),
                  _Exercise(name: 'Walking Lunges', sets: 3, reps: '12 each'),
                  _Exercise(name: 'Calf Raises', sets: 4, reps: '15–20'),
                ],
              ),

              const SizedBox(height: 16),

              _WorkoutPlanCard(
                title: 'Full Body',
                subtitle: 'All major muscle groups',
                level: 'Beginner',
                duration: '40–50 min',
                icon: Icons.accessibility_new_rounded,
                color: const Color(0xFFEDE7F6),
                iconColor: const Color(0xFF7C3AED),
                exercises: const [
                  _Exercise(name: 'Goblet Squat', sets: 3, reps: '10–12'),
                  _Exercise(name: 'Dumbbell Row', sets: 3, reps: '10 each'),
                  _Exercise(name: 'Dumbbell Press', sets: 3, reps: '10–12'),
                  _Exercise(name: 'Hip Hinge', sets: 3, reps: '12'),
                  _Exercise(name: 'Plank', sets: 3, reps: '30–45 sec'),
                  _Exercise(name: 'Dumbbell Curl', sets: 2, reps: '12–15'),
                ],
              ),

              const SizedBox(height: 16),

              _WorkoutPlanCard(
                title: 'Core & Abs',
                subtitle: 'Core · Stability · Endurance',
                level: 'Beginner',
                duration: '20–30 min',
                icon: Icons.crop_square_rounded,
                color: const Color(0xFFFFEBEE),
                iconColor: const Color(0xFFE53935),
                exercises: const [
                  _Exercise(name: 'Plank', sets: 3, reps: '45 sec'),
                  _Exercise(name: 'Crunches', sets: 3, reps: '20'),
                  _Exercise(name: 'Leg Raises', sets: 3, reps: '15'),
                  _Exercise(name: 'Russian Twists', sets: 3, reps: '20'),
                  _Exercise(name: 'Mountain Climbers', sets: 3, reps: '30 sec'),
                  _Exercise(name: 'Dead Bug', sets: 3, reps: '10 each'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Workout Plan Card ─────────────────────────────────────────────────────────

class _WorkoutPlanCard extends StatefulWidget {
  const _WorkoutPlanCard({
    required this.title,
    required this.subtitle,
    required this.level,
    required this.duration,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.exercises,
  });

  final String title;
  final String subtitle;
  final String level;
  final String duration;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final List<_Exercise> exercises;

  @override
  State<_WorkoutPlanCard> createState() => _WorkoutPlanCardState();
}

class _WorkoutPlanCardState extends State<_WorkoutPlanCard> {
  bool _expanded = false;

  Color get _levelColor {
    switch (widget.level) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4A3ED6);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card Header ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon,
                        color: widget.iconColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Level badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _levelColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.level,
                                style: TextStyle(
                                  color: _levelColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Duration badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: purple.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer_outlined,
                                      size: 11, color: purple),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.duration,
                                    style: TextStyle(
                                      color: purple,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded Exercise List ──
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exercises',
                    style: TextStyle(
                      color: purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.exercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: widget.iconColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: widget.iconColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            '${exercise.sets} x ${exercise.reps}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Exercise Model ────────────────────────────────────────────────────────────

class _Exercise {
  const _Exercise({
    required this.name,
    required this.sets,
    required this.reps,
  });

  final String name;
  final int sets;
  final String reps;
}