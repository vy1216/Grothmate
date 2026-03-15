import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../database/app_database.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../utils/calc_utils.dart';
import '../../widgets/common_widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _tab = 'This Week';

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

      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your progress',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    CalcUtils.formatDate(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            PillTabBar(
              tabs: const ['This Week', 'Patterns', 'Supplements', 'Vault'],
              active: _tab,
              onChanged: (t) => setState(() => _tab = t),
            ),
            Expanded(
              child: IndexedStack(
                index: ['This Week', 'Patterns', 'Supplements', 'Vault']
                    .indexOf(_tab),
                children: [
                  _ThisWeekTab(state: state),
                  const _PatternsTab(),
                  const _SupplementsTab(),
                  _VaultTab(userId: user.id!),
                ],
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// ── THIS WEEK TAB ────────────────────────────────────────
class _ThisWeekTab extends StatelessWidget {
  final AppState state;
  const _ThisWeekTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final user = state.user!;
    final weights = state.weightHistory;

    // All weight calculations done locally inside build
    final double curW =
        weights.isNotEmpty ? weights.last.weightKg : user.weightKg;
    final double startW =
        weights.isNotEmpty ? weights.first.weightKg : user.weightKg;
    final double goalW = user.goalWeightKg;
    final double gained = (curW - startW).abs();
    final double range = (goalW - startW).abs().clamp(0.1, double.infinity);
    final double pct = (gained / range).clamp(0.0, 1.0);

    final ws = state.weekStats;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final breakdown = (ws['daily_breakdown'] as List? ?? []);

    final List<double> barData = List.generate(7, (i) {
      final entry = breakdown.firstWhere(
        (d) {
          try {
            final date = DateTime.parse(d['day'] as String);
            return date.weekday == (i + 1);
          } catch (_) {
            return false;
          }
        },
        orElse: () => <String, dynamic>{'total': 0.0},
      );
      return (entry['total'] as num? ?? 0.0).toDouble();
    });

    final double maxBar = [
      ...barData,
      user.dailyKcalTarget,
    ].reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 4),

        // ── Weight card ──────────────────────────────────
        AppCard(
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLabel('Current Weight'),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: curW.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const TextSpan(
                          text: ' kg',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ]),
                    ),
                    Text(
                      gained > 0.05
                          ? '+${gained.toStringAsFixed(1)} kg from start'
                          : 'Starting weight',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Goal weight',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Text(
                      '$goalW kg',
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      '${(goalW - curW).abs().toStringAsFixed(1)} kg to go',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.card2,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$startW kg',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint),
                ),
                Text(
                  '${(pct * 100).round()}% there',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$goalW kg',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, '/weight-log').then((_) => state.loadAll()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: const Text(
                  "Log today's weight",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        // ── Calorie bar chart ────────────────────────────
        AppCard(
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calorie consistency — this week',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 90,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final double kcal =
                        i < barData.length ? barData[i] : 0.0;
                    final double barH = maxBar > 0
                        ? (kcal / maxBar).clamp(0.05, 1.0)
                        : 0.05;
                    final Color color =
                        kcal >= user.dailyKcalTarget
                            ? AppColors.accent
                            : kcal >= user.dailyKcalTarget * 0.7
                                ? AppColors.amber
                                : kcal > 0
                                    ? AppColors.coral
                                    : AppColors.border2;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: barH,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              days[i],
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 14, children: [
                _Legend(color: AppColors.accent, label: 'Target hit'),
                _Legend(color: AppColors.amber, label: '70%+ hit'),
                _Legend(color: AppColors.coral, label: 'Below'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Stats row ────────────────────────────────────
        Row(children: [
          _StatCard(
            value: '${ws['avg_kcal'] ?? 0}',
            label: 'Avg kcal/day',
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          _StatCard(
            value: '${ws['days_hit'] ?? 0}/7',
            label: 'Days on target',
            color: AppColors.amber,
          ),
          const SizedBox(width: 8),
          _StatCard(
            value: '${ws['workout_count'] ?? 0}',
            label: 'Workouts',
            color: AppColors.blue,
          ),
          const SizedBox(width: 8),
          _StatCard(
            value: '${state.streak}d',
            label: 'Streak',
            color: AppColors.coral,
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── SHARED HELPERS ───────────────────────────────────────
class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}

// ── PATTERNS TAB ─────────────────────────────────────────
class _PatternsTab extends StatelessWidget {
  const _PatternsTab();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔍', style: TextStyle(fontSize: 44)),
              SizedBox(height: 12),
              Text(
                'Keep logging for 7+ days',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'GrowthMate will start detecting patterns between your food, mood, and energy after consistent logging.',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

// ── SUPPLEMENTS TAB ──────────────────────────────────────
class _SupplementsTab extends StatelessWidget {
  const _SupplementsTab();

  static const _supplements = [
    {
      'name': 'Vitamin B12',
      'desc':
          'Critical for energy and nerve function — most underweight vegetarians are deficient.',
      'emoji': '💊',
    },
    {
      'name': 'Vitamin D',
      'desc':
          'Essential for mood, immunity, and muscle strength. Get a blood test to check your levels.',
      'emoji': '☀️',
    },
    {
      'name': 'Iron',
      'desc':
          'Iron deficiency is a major cause of fatigue and low energy in underweight individuals.',
      'emoji': '🩸',
    },
  ];

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Track which supplements you\'re taking. These are critical for energy and mood if you\'re underweight.',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6),
          ),
          const SizedBox(height: 12),
          ..._supplements.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(children: [
                  Text(s['emoji']!,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s['desc']!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: const Text(
                      'Taken ✓',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      );
}

// ── VAULT TAB ────────────────────────────────────────────
class _VaultTab extends StatefulWidget {
  final int userId;
  const _VaultTab({required this.userId});
  @override State<_VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends State<_VaultTab> {
  List<VaultEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries =
        await AppDatabase.instance.getVaultEntries(widget.userId);
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/worry-timer')
                .then((_) => _load()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.secondary),
              ),
              child: const Center(
                child: Text(
                  '+ New brain dump',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child:
                    CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          else if (_entries.isEmpty)
            const EmptyState(
              emoji: '🧠',
              title: 'Your thought vault is empty',
              subtitle:
                  'Use the Worry Timer to dump your thoughts. Stored here privately.',
            )
          else
            ..._entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTime.parse(e.createdAt)
                            .toLocal()
                            .toString()
                            .substring(0, 16),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        e.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (e.aiReadable)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'AI can read this',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.accent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
