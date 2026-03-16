import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/theme.dart';
import '../../constants/food_database.dart';
import '../../database/app_database.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../services/groq_service.dart';
import '../../utils/calc_utils.dart';
import '../../widgets/common_widgets.dart';

// ── LOG WORKOUT ──────────────────────────────────────────
class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});
  @override State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  String _category = 'Bodyweight';
  Map<String, dynamic>? _selected;
  final _setsC = TextEditingController(text: '3');
  final _repsC = TextEditingController(text: '10');
  final _durC = TextEditingController(text: '20');
  int _energy = 2;

  List<Map<String, dynamic>> get _filtered => kExercises.where((e) => e['category'] == _category).toList();

  double get _calBurned {
    if (_selected == null) return 0;
    final user = context.read<AppState>().user;
    final dSec = (int.tryParse(_durC.text) ?? 20) * 60;
    return CalcUtils.calculateCaloriesBurned((_selected!['met'] as num).toDouble(), user?.weightKg ?? 60, dSec);
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final user = context.read<AppState>().user;
    if (user == null) return;
    await AppDatabase.instance.logWorkout(WorkoutLog(
      userId: user.id!, exerciseName: _selected!['name'],
      category: _selected!['category'],
      sets: int.tryParse(_setsC.text) ?? 0,
      reps: int.tryParse(_repsC.text) ?? 0,
      durationSec: (int.tryParse(_durC.text) ?? 20) * 60,
      caloriesBurned: _calBurned,
      energyAfter: _energy,
      loggedAt: DateTime.now().toIso8601String(),
    ));
    await AppDatabase.instance.markStreakAction(user.id!, 'workout');
    if (mounted) {
      await context.read<AppState>().refreshWorkouts();
      Navigator.pop(context);
    }
  }

  @override
  void dispose() { _setsC.dispose(); _repsC.dispose(); _durC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        ModalHeader(title: 'Log workout', action: _selected != null ? 'Save' : null, onAction: _save),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          const AppLabel('Category'),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: ['Bodyweight', 'Cardio', 'Yoga', 'Stretching', 'Weights'].map((c) => GestureDetector(
              onTap: () => setState(() { _category = c; _selected = null; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _category == c ? AppColors.secondary : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _category == c ? AppColors.secondary : AppColors.border2),
                ),
                child: Text(c, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _category == c ? AppColors.pale : AppColors.textSecondary)),
              ),
            )).toList()),
          ),

          const SizedBox(height: 16),
          const AppLabel('Exercise'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _filtered.map((e) {
            final isActive = _selected?['id'] == e['id'];
            return GestureDetector(
              onTap: () => setState(() => _selected = e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? AppColors.accent : AppColors.border2),
                ),
                child: Text(e['name'] as String, style: TextStyle(fontSize: 13, color: isActive ? AppColors.accent : AppColors.textSecondary, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
              ),
            );
          }).toList()),
          if (_selected != null) ...[
            const SizedBox(height: 16),
            Row(children: [
              if (_selected!['unit'] == 'reps') ...[
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppLabel('Sets'),
                  const SizedBox(height: 6),
                  TextField(controller: _setsC, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Syne'), textAlign: TextAlign.center),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const AppLabel('Reps'),
                  const SizedBox(height: 6),
                  TextField(controller: _repsC, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Syne'), textAlign: TextAlign.center),
                ])),
                const SizedBox(width: 12),
              ],
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const AppLabel('Duration (min)'),
                const SizedBox(height: 6),
                TextField(controller: _durC, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}), style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Syne'), textAlign: TextAlign.center),
              ])),
            ]),
            const SizedBox(height: 16),
            const AppLabel('Energy after workout'),
            const SizedBox(height: 8),
            Row(children: [
              ['😫', 'Exhausted'], ['😩', 'Tired'], ['😐', 'Okay'], ['💪', 'Energized'],
            ].asMap().entries.map((entry) {
              final i = entry.key + 1;
              final e = entry.value;
              final isActive = _energy == i;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _energy = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isActive ? AppColors.accent : AppColors.border2),
                  ),
                  child: Column(children: [
                    Text(e[0], style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(e[1], style: TextStyle(fontSize: 10, color: isActive ? AppColors.accent : AppColors.textSecondary), textAlign: TextAlign.center),
                  ]),
                ),
              ));
            }).toList()),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text('Estimated burn: ~${_calBurned.round()} kcal', style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w600))),
            ),
            const SizedBox(height: 16),
            GreenButton(label: 'Save workout', onPressed: _save),
          ],
        ])),
      ])),
    );
  }
}

// ── MOOD LOG ─────────────────────────────────────────────
class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});
  @override State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  int? _mood;
  int _energy = 3;
  final _noteC = TextEditingController();

  Future<void> _save() async {
    if (_mood == null) return;
    final user = context.read<AppState>().user;
    if (user == null) return;
    final cfg = CalcUtils.getMoodConfig(_mood!);
    await context.read<AppState>().logMoodUpdate(MoodLog(
      userId: user.id!, moodScore: _mood!, moodLabel: cfg['label'] as String,
      energyScore: _energy, note: _noteC.text,
      loggedAt: DateTime.now().toIso8601String(),
    ));
    await AppDatabase.instance.markStreakAction(user.id!, 'mood');
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() { _noteC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final moods = [
      {'score': 5, 'label': 'Great', 'emoji': '😄'},
      {'score': 4, 'label': 'Good', 'emoji': '🙂'},
      {'score': 3, 'label': 'Okay', 'emoji': '😐'},
      {'score': 2, 'label': 'Low', 'emoji': '😔'},
      {'score': 1, 'label': 'Anxious', 'emoji': '😰'},
    ];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        ModalHeader(title: 'How are you feeling?', action: _mood != null ? 'Save' : null, onAction: _save),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Mood', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(children: moods.map((m) {
            final score = m['score'] as int;
            final cfg = CalcUtils.getMoodConfig(score);
            final isActive = _mood == score;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _mood = score),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cfg['bg'] as Color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isActive ? (cfg['color'] as Color) : Colors.transparent, width: 2),
                ),
                child: Column(children: [
                  Text(m['emoji'] as String, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 5),
                  Text(m['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? (cfg['color'] as Color) : AppColors.textSecondary)),
                ]),
              ),
            ));
          }).toList()),

          const SizedBox(height: 20),
          const Text('Energy level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
            final n = i + 1;
            final isActive = n <= _energy;
            return GestureDetector(
              onTap: () => setState(() => _energy = n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.secondary : AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? AppColors.accent : AppColors.border2, width: 1.5),
                ),
                child: Center(child: Text('$n', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isActive ? AppColors.pale : AppColors.textHint))),
              ),
            );
          })),
          const SizedBox(height: 6),
          Center(child: Text(['Very low', 'Low', 'Okay', 'Good', 'Excellent'][_energy - 1], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          const SizedBox(height: 20),
          const Text('Add a note (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          TextField(controller: _noteC, maxLines: 3, style: const TextStyle(color: AppColors.textPrimary), decoration: const InputDecoration(hintText: "What's on your mind?")),
          const SizedBox(height: 16),
          if (_mood != null) GreenButton(label: 'Save mood', onPressed: _save),
        ])),
      ])),
    );
  }
}

// ── WORRY TIMER ──────────────────────────────────────────
class WorryTimerScreen extends StatefulWidget {
  const WorryTimerScreen({super.key});
  @override State<WorryTimerScreen> createState() => _WorryTimerScreenState();
}

class _WorryTimerScreenState extends State<WorryTimerScreen> {
  String _phase = 'intro';
  final _textC = TextEditingController();
  int _timeLeft = 15 * 60;
  bool _aiReadable = false;
  DateTime? _startTime;
  Timer? _timer;

  void _start() {
    setState(() { _phase = 'writing'; _startTime = DateTime.now(); });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) { _timer?.cancel(); return; }
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) { _timer?.cancel(); _phase = 'done'; }
      });
    });
  }

  Future<void> _save() async {
    final user = context.read<AppState>().user;
    if (user == null || _textC.text.trim().isEmpty) { Navigator.pop(context); return; }
    final elapsed = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;
    await AppDatabase.instance.saveVaultEntry(VaultEntry(
      userId: user.id!, content: _textC.text.trim(),
      durationSec: elapsed, aiReadable: _aiReadable,
      createdAt: DateTime.now().toIso8601String(),
    ));
    await AppDatabase.instance.markStreakAction(user.id!, 'vault');
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() { _timer?.cancel(); _textC.dispose(); super.dispose(); }

  String get _timerStr {
    final m = _timeLeft ~/ 60;
    final s = _timeLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        ModalHeader(title: 'Brain dump'),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_phase == 'intro') ...[
            AppCard(radius: 24, padding: const EdgeInsets.all(24), child: Column(children: [
              const Text('🧠', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Release your thoughts', style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text("You get 15 minutes to write down everything on your mind — worries, thoughts, fears, anything. When the timer ends, your thoughts are safely stored in your vault.", style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6), textAlign: TextAlign.center),
            ])),
            const SizedBox(height: 20),
            GreenButton(label: 'Start brain dump (15 min)', onPressed: _start),
          ],
          if (_phase == 'writing') ...[
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.secondary)),
              child: Column(children: [
                Text(_timerStr, style: const TextStyle(fontFamily: 'Syne', fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.accent)),
                const Text('minutes remaining', style: TextStyle(fontSize: 13, color: AppColors.light)),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textC, maxLines: 12, autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6),
              decoration: const InputDecoration(hintText: "Write everything on your mind... don't filter, don't edit, just write."),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () { _timer?.cancel(); setState(() => _phase = 'done'); }, child: const Text("I'm done early", style: TextStyle(color: AppColors.textSecondary))),
          ],
          if (_phase == 'done') ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.accent)),
              child: Column(children: [
                const Text('✅', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                const Text('Your thoughts are safe', style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text("They'll be in your vault whenever you want to revisit them. Now — what are you going to eat tonight?", style: TextStyle(fontSize: 14, color: AppColors.light, height: 1.6), textAlign: TextAlign.center),
              ]),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _aiReadable = !_aiReadable),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _aiReadable ? AppColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _aiReadable ? AppColors.accent : AppColors.textHint, width: 1.5),
                  ),
                  child: _aiReadable ? const Icon(Icons.check, size: 13, color: AppColors.bg) : null,
                ),
                const SizedBox(width: 10),
                const Expanded(child: Text('Allow AI companion to read this for better support', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ]),
            ),
            const SizedBox(height: 16),
            GreenButton(label: 'Save to vault', onPressed: _save),
          ],
        ])),
      ])),
    );
  }
}

// ── WEEKLY REVIEW ────────────────────────────────────────
class WeeklyReviewScreen extends StatefulWidget {
  const WeeklyReviewScreen({super.key});
  @override State<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends State<WeeklyReviewScreen> {
  String? _review;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AppState>().user;
    if (user == null) return;
    final r = await GroqService.generateWeeklyReview(user.id!);
    if (mounted) setState(() { _review = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(child: Column(children: [
      const ModalHeader(title: 'Weekly review'),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Week of ${CalcUtils.formatDate(DateTime.now())}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(60), child: Column(children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16),
            Text('Your AI companion is reviewing your week...', style: TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ])))
        else
          AppCard(radius: 24, padding: const EdgeInsets.all(20), child: Text(_review ?? '', style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.8))),
      ])),
    ])),
  );
}

// ── WEIGHT LOG ───────────────────────────────────────────
class WeightLogScreen extends StatefulWidget {
  const WeightLogScreen({super.key});
  @override State<WeightLogScreen> createState() => _WeightLogScreenState();
}

class _WeightLogScreenState extends State<WeightLogScreen> {
  final _weightC = TextEditingController();

  Future<void> _save() async {
    final w = double.tryParse(_weightC.text);
    if (w == null || w < 20 || w > 300) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid weight in kg')));
      return;
    }
    await context.read<AppState>().addWeight(w);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() { _weightC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(child: Column(children: [
      ModalHeader(title: 'Log weight', action: 'Save', onAction: _save),
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        AppCard(radius: 24, padding: const EdgeInsets.all(32), child: Column(children: [
          const AppLabel('Current weight'),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 120,
              child: TextField(
                controller: _weightC, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Syne', fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                decoration: const InputDecoration(border: InputBorder.none, hintText: '0.0', filled: false, contentPadding: EdgeInsets.zero),
              ),
            ),
            const Text(' kg', style: TextStyle(fontFamily: 'Syne', fontSize: 22, color: AppColors.textSecondary)),
          ]),
        ])),
        const SizedBox(height: 12),
        const AppCard(child: Text('💡  Weigh yourself in the morning, before eating, for the most consistent results.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6))),
        const SizedBox(height: 16),
        GreenButton(label: 'Log weight', onPressed: _save),
      ])),
    ])),
  );
}

// ── SETTINGS ─────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyC = TextEditingController();
  bool _keyVisible = false;
  String _savedKey = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final k = prefs.getString('groq_api_key') ?? '';
    setState(() { _savedKey = k; _keyC.text = k; GroqService.setApiKey(k); });
  }

  Future<void> _saveKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groq_api_key', _keyC.text.trim());
    GroqService.setApiKey(_keyC.text.trim());
    setState(() => _savedKey = _keyC.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key saved!'), backgroundColor: AppColors.accent));
  }

  @override
  void dispose() { _keyC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: Column(children: [
        const ModalHeader(title: 'Profile & Settings'),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          // Profile card
          if (user != null) AppCard(radius: 20, child: Row(children: [
            CircleAvatar(radius: 28, backgroundColor: AppColors.secondary,
              child: Text(CalcUtils.getInitials(user.name), style: const TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.pale))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: const TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('BMI ${user.bmi} · ${user.weightKg}kg · ${user.heightCm}cm', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
          ])),
          const SizedBox(height: 12),

          // Stats
          if (user != null) AppCard(child: Column(children: [
            _InfoRow('Goal', user.goalType.replaceAll('_', ' ')),
            _InfoRow('Daily target', '${user.dailyKcalTarget.round()} kcal'),
            _InfoRow('Protein target', '${user.proteinTargetG.round()}g/day'),
            _InfoRow('Water target', '${user.waterTargetGlasses} glasses'),
            _InfoRow('Diet', user.dietType.replaceAll('_', ' + ')),
            _InfoRow('AI companion', user.aiCompanionName),
            _InfoRow('Wake time', user.wakeTime),
            _InfoRow('Sleep time', user.sleepTime),
          ])),
          const SizedBox(height: 16),

          // API Key
          const Text('Groq API Key', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Get your free key at console.groq.com', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _keyC,
            obscureText: !_keyVisible,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'Courier'),
            decoration: InputDecoration(
              hintText: 'gsk_xxxxxxxxxxxxxxxxxxxxxxxx',
              suffixIcon: IconButton(
                icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 18),
                onPressed: () => setState(() => _keyVisible = !_keyVisible),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_savedKey.isNotEmpty)
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('✓ API key is set — AI features are active', style: TextStyle(fontSize: 12, color: AppColors.accent))),
          const SizedBox(height: 10),
          GreenButton(label: 'Save API Key', onPressed: _saveKey),
          const SizedBox(height: 24),

          // Danger zone
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text('Reset app?', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Syne')),
              content: const Text('This will delete ALL your data. This cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
                TextButton(onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
                }, child: const Text('Reset', style: TextStyle(color: AppColors.coral))),
              ],
            )),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.coral.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.coral.withOpacity(0.3))),
              child: const Center(child: Text('Reset app data', style: TextStyle(color: AppColors.coral, fontSize: 14, fontWeight: FontWeight.w500))),
            ),
          ),
          const SizedBox(height: 30),
        ])),
      ])),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
    ]),
  );
}
