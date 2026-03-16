import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../database/app_database.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../utils/calc_utils.dart';
import '../../widgets/common_widgets.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});
  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  String _tab = 'Meals';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final user = state.user;
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );
      }
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(children: [
                const Expanded(
                  child: Text(
                    'Track',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  CalcUtils.formatDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ]),
            ),
            PillTabBar(
              tabs: const ['Meals', 'Exercise', 'Water'],
              active: _tab,
              onChanged: (t) => setState(() => _tab = t),
            ),
            Expanded(
              child: IndexedStack(
                index: ['Meals', 'Exercise', 'Water'].indexOf(_tab),
                children: [
                  _MealsTab(state: state),
                  _ExerciseTab(state: state),
                  _WaterTab(user: user, water: state.water, onAdd: state.addWater),
                ],
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// ── MEALS TAB ────────────────────────────────────────────
class _MealsTab extends StatelessWidget {
  final AppState state;
  const _MealsTab({required this.state});

  static const List<String> _slots = ['breakfast', 'lunch', 'snack', 'dinner'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 4),
        ..._slots.map((slot) {
          final items = state.todayMeals
              .where((m) => m.mealSlot == slot)
              .toList();
          final double slotCal =
              items.fold(0.0, (s, m) => s + m.calories);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      CalcUtils.slotEmoji(slot),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        CalcUtils.capitalize(slot),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (slotCal > 0)
                      Text(
                        '${slotCal.round()} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/log-meal',
                        arguments: {'slot': slot},
                      ).then((_) => state.refreshMeals()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '+ Add',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ]),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Nothing logged yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...items.map((item) => Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border2.withOpacity(0.5)),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.foodName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'P: ${item.proteinG.round()}g  C: ${item.carbsG.round()}g  F: ${item.fatG.round()}g',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.calories.round()} kcal',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => state.deleteMeal(item.id ?? 0),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppColors.coral,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    )),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── EXERCISE TAB ─────────────────────────────────────────
class _ExerciseTab extends StatelessWidget {
  final AppState state;
  const _ExerciseTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 4),
        GreenButton(
          label: '+ Log Workout',
          onPressed: () => Navigator.pushNamed(context, '/log-workout')
              .then((_) => state.refreshWorkouts()),
        ),
        const SizedBox(height: 16),
        if (state.weekWorkouts.isEmpty)
          const EmptyState(
            emoji: '💪',
            title: 'No workouts this week',
            subtitle:
                'Log your first workout and the AI will analyze your progress.',
          )
        else ...[
          const AppLabel('This week\'s workouts'),
          const SizedBox(height: 8),
          ...state.weekWorkouts.take(10).map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(children: [
                  const Text('💪', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.exerciseName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          w.sets > 0
                              ? '${w.sets} sets × ${w.reps} reps'
                              : '${(w.durationSec / 60).round()} min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${w.caloriesBurned.round()} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── WATER TAB ────────────────────────────────────────────
class _WaterTab extends StatelessWidget {
  final UserModel user;
  final int water;
  final VoidCallback onAdd;
  const _WaterTab({
    required this.user,
    required this.water,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          radius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const AppLabel('Today\'s Water'),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: '$water',
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' / ${user.waterTargetGlasses}',
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ]),
            ),
            const Text(
              'glasses today',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(user.waterTargetGlasses, (i) {
                final filled = i < water;
                return GestureDetector(
                  onTap: onAdd,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 56,
                    decoration: BoxDecoration(
                      color: filled
                          ? AppColors.blue.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: filled ? AppColors.blue : AppColors.border2,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filled ? '🥤' : '🫙',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.blue),
                ),
                child: const Text(
                  '+ Add a glass',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        const AppCard(
          child: Text(
            '💡  Drinking water before meals helps improve appetite if you\'re underweight. Aim for 2 glasses between each meal.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
