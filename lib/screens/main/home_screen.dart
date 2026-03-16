import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../constants/theme.dart';
import '../../services/app_state.dart';
import '../../utils/calc_utils.dart';
import '../../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AppState>().loadAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (ctx, state, _) {
      final user = state.user;
      if (user == null) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        );
      }

      final double totalCal = state.totalCalToday;
      final double target = user.dailyKcalTarget;
      final double remaining = (target - totalCal).clamp(0, target);
      final double pct = (totalCal / target).clamp(0.0, 1.0);

      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => state.loadAll(),
            color: AppColors.accent,
            backgroundColor: AppColors.card,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(state, user.name),
                  _buildCalorieCard(state, totalCal, target, remaining, pct, user.proteinTargetG),
                  _buildMoodWaterRow(state, user.waterTargetGlasses),
                  SectionHeader(
                    title: "Today's meals",
                    action: '+ Log meal',
                    onAction: () => Navigator.pushNamed(context, '/log-meal')
                        .then((_) => state.refreshMeals()),
                  ),
                  _buildMealsList(state, user),
                  _buildStreakCard(state),
                  SectionHeader(title: 'Quick actions'),
                  _buildQuickActions(state),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(AppState state, String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${CalcUtils.getGreeting()},',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              CalcUtils.formatDate(DateTime.now()),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ]),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondary,
            child: Text(
              CalcUtils.getInitials(name),
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.pale,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCalorieCard(
    AppState state,
    double totalCal,
    double target,
    double remaining,
    double pct,
    double proteinTarget,
  ) {
    final String statusLabel = pct >= 1.0
        ? 'Goal hit! 🎉'
        : pct >= 0.7
            ? 'On track'
            : pct >= 0.4
                ? 'Behind'
                : 'Critical';
    final Color statusColor = pct >= 0.7
        ? AppColors.accent
        : pct >= 0.4
            ? AppColors.amber
            : AppColors.coral;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AppCard(
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppLabel("Today's Calories"),
              StatusBadge(statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _CalorieRingPainter(
                  pct,
                  (state.totalProteinToday / proteinTarget).clamp(0.0, 1.0),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    totalCal.round().toString(),
                    style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'kcal consumed',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/ ${target.round()} target',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: remaining > 0
                          ? AppColors.coral.withOpacity(0.15)
                          : AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      remaining > 0
                          ? '${remaining.round()} kcal left'
                          : 'Goal hit! ✓',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: remaining > 0
                            ? AppColors.coral
                            : AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _MacroItem('Protein', '${state.totalProteinToday.round()}g',
                AppColors.accent, state.totalProteinToday, proteinTarget),
            const SizedBox(width: 6),
            _MacroItem('Carbs', '${state.totalCarbsToday.round()}g',
                AppColors.amber, state.totalCarbsToday, target * 0.5 / 4),
            const SizedBox(width: 6),
            _MacroItem('Fat', '${state.totalFatToday.round()}g',
                AppColors.blue, state.totalFatToday, target * 0.3 / 9),
            const SizedBox(width: 6),
            _MacroItem(
              'Sugar',
              '${state.totalSugarToday.round()}g',
              state.totalSugarToday > 40
                  ? AppColors.coral
                  : AppColors.textSecondary,
              state.totalSugarToday,
              50,
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildMoodWaterRow(AppState state, int waterTarget) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/mood-log')
                .then((_) => state.loadAll()),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLabel('Mood'),
                  const SizedBox(height: 8),
                  Row(
                    children: [5, 4, 3, 2, 1].map((score) {
                      final cfg = CalcUtils.getMoodConfig(score);
                      final bool isActive =
                          state.todayMood?.moodScore == score;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          height: 28,
                          decoration: BoxDecoration(
                            color: cfg['bg'] as Color,
                            shape: BoxShape.circle,
                            border: isActive
                                ? Border.all(
                                    color: AppColors.accent,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              cfg['emoji'] as String,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.todayMood != null
                        ? CalcUtils.getMoodConfig(
                              state.todayMood!.moodScore,
                            )['label'] as String
                        : 'Tap to log',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => state.addWater(),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppLabel('Water'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 3,
                    runSpacing: 3,
                    children: List.generate(waterTarget, (i) {
                      final bool filled = i < state.water;
                      return Container(
                        width: 13,
                        height: 17,
                        decoration: BoxDecoration(
                          color: filled ? AppColors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: filled
                                ? AppColors.blue
                                : AppColors.border2,
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 5),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: '${state.water}',
                        style: const TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' / $waterTarget',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ]),
                  ),
                  const Text(
                    'tap to add glass',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMealsList(AppState state, dynamic user) {
    const slots = ['breakfast', 'lunch', 'snack', 'dinner'];
    final String currentSlot =
        CalcUtils.getMealSlot(user.wakeTime, user.sleepTime);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: slots.map((slot) {
          final items =
              state.todayMeals.where((m) => m.mealSlot == slot).toList();
          final double slotCal =
              items.fold(0.0, (s, m) => s + m.calories);
          final bool isCurrent = slot == currentSlot;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/log-meal',
                arguments: {'slot': slot},
              ).then((_) => state.refreshMeals()),
              child: AppCard(
                child: Row(children: [
                  Text(
                    CalcUtils.slotEmoji(slot),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            CalcUtils.capitalize(slot),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: items.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            StatusBadge('Now', color: AppColors.accent),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(
                          items.isNotEmpty
                              ? items.map((i) => i.foodName).join(' · ')
                              : 'Not logged yet — tap to add',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: items.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    items.isNotEmpty ? '${slotCal.round()}' : '—',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: items.isNotEmpty
                          ? AppColors.accent
                          : AppColors.textHint,
                    ),
                  ),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStreakCard(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '${state.streak}',
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(
                      text: ' day streak',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.light,
                      ),
                    ),
                  ]),
                ),
                const Text(
                  'Keep logging to maintain it!',
                  style: TextStyle(fontSize: 11, color: AppColors.light),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/log-meal')
                .then((_) => state.refreshMeals()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Log meal',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.pale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(AppState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(children: [
        _QuickAction('🍽️', 'Log Meal', () => Navigator.pushNamed(context, '/log-meal').then((_) => state.refreshMeals())),
        const SizedBox(width: 8),
        _QuickAction('💪', 'Log Workout', () => Navigator.pushNamed(context, '/log-workout').then((_) => state.refreshWorkouts())),
        const SizedBox(width: 8),
        _QuickAction('⚖️', 'Log Weight', () => Navigator.pushNamed(context, '/weight-log').then((_) => state.loadAll())),
        const SizedBox(width: 8),
        _QuickAction('🧠', 'Brain Dump', () => Navigator.pushNamed(context, '/worry-timer')),
      ]),
    );
  }
}

// ── HELPER WIDGETS ───────────────────────────────────────
class _MacroItem extends StatelessWidget {
  final String label, value;
  final Color color;
  final double current, max;
  const _MacroItem(this.label, this.value, this.color, this.current, this.max);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        MacroBar(value: current, max: max, color: color),
      ]),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _QuickAction(this.emoji, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    ),
  );
}

// ── CALORIE RING PAINTER ─────────────────────────────────
class _CalorieRingPainter extends CustomPainter {
  final double calPct, protPct;
  const _CalorieRingPainter(this.calPct, this.protPct);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double outerR = size.width / 2 - 5;
    final double innerR = size.width / 2 - 18;

    final Paint bgOuter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = AppColors.card2;
    final Color calColor = calPct >= 0.9
        ? AppColors.accent
        : calPct >= 0.6
            ? AppColors.amber
            : AppColors.coral;
    final Paint calPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = calColor
      ..strokeCap = StrokeCap.round;
    final Paint bgInner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AppColors.card2;
    final Paint protPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AppColors.blue
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, outerR, bgOuter);
    if (calPct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: outerR),
        -math.pi / 2,
        calPct.clamp(0.0, 1.0) * 2 * math.pi,
        false,
        calPaint,
      );
    }
    canvas.drawCircle(c, innerR, bgInner);
    if (protPct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: innerR),
        -math.pi / 2,
        protPct.clamp(0.0, 1.0) * 2 * math.pi,
        false,
        protPaint,
      );
    }

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: '${(calPct * 100).round()}%',
        style: const TextStyle(
          fontFamily: 'Syne',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 - 6));

    final TextPainter tp2 = TextPainter(
      text: const TextSpan(
        text: 'of goal',
        style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(c.dx - tp2.width / 2, c.dy + 4));
  }

  @override
  bool shouldRepaint(_CalorieRingPainter old) =>
      old.calPct != calPct || old.protPct != protPct;
}
