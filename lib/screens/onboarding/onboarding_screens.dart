import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/theme.dart';
import '../../database/app_database.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../services/groq_service.dart';
import '../../utils/calc_utils.dart';
import '../../widgets/common_widgets.dart';

// ── ONBOARDING BASE ─────────────────────────────────────
class OnboardingBase extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback onContinue;
  final bool continueDisabled;
  final bool loading;
  final VoidCallback? onBack;

  const OnboardingBase({
    super.key, required this.step, this.total = 7, required this.title,
    this.subtitle, required this.children, required this.onContinue,
    this.continueDisabled = false, this.loading = false, this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: step / total,
                    backgroundColor: AppColors.border2,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$step of $total', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textSecondary), onPressed: onBack),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontFamily: 'Syne', fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2)),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
                ],
                const SizedBox(height: 24),
                ...children,
                const SizedBox(height: 100),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GreenButton(label: loading ? 'Setting up...' : 'Continue →', onPressed: onContinue, disabled: continueDisabled, isLoading: loading),
          ),
        ]),
      ),
    );
  }
}

// ── HELPER WIDGETS ───────────────────────────────────────
class ObLabel extends StatelessWidget {
  final String text;
  const ObLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );
}

class PillOptions extends StatelessWidget {
  final List<String> options;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool multiSelect;
  final List<String> multiSelected;

  const PillOptions({
    super.key, required this.options, required this.values, this.selected = '',
    required this.onSelect, this.multiSelect = false, this.multiSelected = const [],
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
    children: List.generate(options.length, (i) {
      final isActive = multiSelect ? multiSelected.contains(values[i]) : selected == values[i];
      return GestureDetector(
        onTap: () => onSelect(values[i]),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? AppColors.secondary : AppColors.card,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: isActive ? AppColors.secondary : AppColors.border2),
          ),
          child: Text(options[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isActive ? AppColors.pale : AppColors.textSecondary)),
        ),
      );
    }),
  );
}

// ── WELCOME SCREEN ───────────────────────────────────────
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 90, height: 90, decoration: BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 2),
              ),
              child: const Center(child: Text('🌱', style: TextStyle(fontSize: 42))),
            ),
            const SizedBox(height: 24),
            const Text('GrowthMate', style: TextStyle(fontFamily: 'Syne', fontSize: 42, fontWeight: FontWeight.w800, color: AppColors.accent, letterSpacing: -1)),
            const SizedBox(height: 8),
            const Text('your personal growth companion', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            const Text('Track calories, understand your mood, and build habits that actually stick — with AI that knows you.', style: TextStyle(fontSize: 14, color: AppColors.textHint, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/onboard/stats'),
                child: const Text("Let's begin"),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Takes about 3 minutes to set up', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          ]),
        ),
      ),
    );
  }
}

// ── STATS SCREEN ─────────────────────────────────────────
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _nameC = TextEditingController();
  final _weightC = TextEditingController();
  final _heightC = TextEditingController();
  String _gender = 'male';

  double? get _bmi {
    final w = double.tryParse(_weightC.text);
    final h = double.tryParse(_heightC.text);
    if (w != null && h != null && w > 0 && h > 0) return CalcUtils.calculateBMI(w, h);
    return null;
  }

  bool get _valid => _nameC.text.trim().isNotEmpty && (double.tryParse(_weightC.text) ?? 0) > 0 && (double.tryParse(_heightC.text) ?? 0) > 0;

  @override
  void dispose() { _nameC.dispose(); _weightC.dispose(); _heightC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bmi = _bmi;
    return OnboardingBase(
      step: 1, title: 'Tell us about yourself',
      subtitle: 'We calculate your personalized calorie target from these details.',
      onBack: () => Navigator.pop(context),
      continueDisabled: !_valid,
      onContinue: () {
        final args = {
          'name': _nameC.text.trim(), 'gender': _gender,
          'weight_kg': double.parse(_weightC.text),
          'height_cm': double.parse(_heightC.text),
          'bmi': bmi ?? 20.0,
        };
        Navigator.pushNamed(context, '/onboard/goals', arguments: args);
      },
      children: [
        ObLabel('Your name'),
        TextField(controller: _nameC, onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Enter your name'), style: const TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ObLabel('Gender'),
        PillOptions(options: const ['Male', 'Female', 'Other'], values: const ['male', 'female', 'other'], selected: _gender,
          onSelect: (v) => setState(() => _gender = v)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ObLabel('Weight (kg)'),
            TextField(controller: _weightC, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '52'), style: const TextStyle(color: AppColors.textPrimary)),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ObLabel('Height (cm)'),
            TextField(controller: _heightC, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '175'), style: const TextStyle(color: AppColors.textPrimary)),
          ])),
        ]),
        if (bmi != null) ...[
          const SizedBox(height: 16),
          AppCard(child: Row(children: [
            Container(
              width: 60, height: 60, decoration: BoxDecoration(
                shape: BoxShape.circle, color: CalcUtils.getBMIColor(bmi).withOpacity(0.15),
                border: Border.all(color: CalcUtils.getBMIColor(bmi), width: 2),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(bmi.toString(), style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: CalcUtils.getBMIColor(bmi))),
                Text('BMI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: CalcUtils.getBMIColor(bmi))),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(CalcUtils.getBMILabel(bmi), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: CalcUtils.getBMIColor(bmi))),
              const SizedBox(height: 4),
              Text(bmi < 18.5 ? "We'll build a calorie surplus to help you gain weight safely." : bmi < 25 ? "Healthy range. We'll help you maintain and build strength." : "We'll create a balanced plan for healthy progress.",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
            ])),
          ])),
        ],
      ],
    );
  }
}

// ── GOALS SCREEN ─────────────────────────────────────────
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String _goal = 'gain_weight';
  String _activity = '1.2';
  String _diet = 'veg_eggs';
  final _goalWeightC = TextEditingController();

  @override
  void dispose() { _goalWeightC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final statsArgs = ModalRoute.of(context)?.settings.arguments as Map?;
    return OnboardingBase(
      step: 2, title: 'What do you want?',
      subtitle: 'This sets your calorie target and how the AI supports you.',
      onBack: () => Navigator.pop(context),
      onContinue: () {
        final gw = double.tryParse(_goalWeightC.text) ?? ((statsArgs?['weight_kg'] as double? ?? 60) + 8);
        Navigator.pushNamed(context, '/onboard/routine', arguments: {
          ...?statsArgs, 'goal_type': _goal, 'activity_level': _activity,
          'diet_type': _diet, 'goal_weight_kg': gw,
          'activity_multiplier': double.parse(_activity),
        });
      },
      children: [
        ObLabel('Primary goal'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          {'id':'gain_weight','label':'Gain Weight +500'},
          {'id':'lose_weight','label':'Lose Weight -500'},
          {'id':'build_strength','label':'Build Strength'},
          {'id':'improve_energy','label':'Feel Better'},
        ].map((g) {
          final isActive = _goal == g['id'];
          return GestureDetector(
            onTap: () => setState(() => _goal = g['id']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isActive ? AppColors.accent : AppColors.border2),
              ),
              child: Text(g['label']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? AppColors.accent : AppColors.textSecondary)),
            ),
          );
        }).toList()),
        const SizedBox(height: 16),
        ObLabel('Goal weight (kg)'),
        TextField(controller: _goalWeightC, keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 60'), style: const TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ObLabel('Activity level'),
        PillOptions(options: const ['Sedentary', 'Light', 'Moderate', 'Active'], values: const ['1.2', '1.375', '1.55', '1.725'],
          selected: _activity, onSelect: (v) => setState(() => _activity = v)),
        const SizedBox(height: 16),
        ObLabel('Diet type'),
        PillOptions(options: const ['Vegetarian', 'Veg + Eggs', 'Non-Veg', 'Vegan'], values: const ['vegetarian', 'veg_eggs', 'non_veg', 'vegan'],
          selected: _diet, onSelect: (v) => setState(() => _diet = v)),
      ],
    );
  }
}

// ── ROUTINE SCREEN ───────────────────────────────────────
class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});
  @override State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final _wakeC = TextEditingController(text: '07:00');
  final _sleepC = TextEditingController(text: '23:00');
  String _schedule = 'college';
  bool _skipsMeals = false;

  @override
  void dispose() { _wakeC.dispose(); _sleepC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    return OnboardingBase(
      step: 3, title: 'How does your day look?',
      subtitle: "We'll time your meal reminders to fit your actual routine.",
      onBack: () => Navigator.pop(context),
      onContinue: () => Navigator.pushNamed(context, '/onboard/diet', arguments: {
        ...?args, 'wake_time': _wakeC.text, 'sleep_time': _sleepC.text,
        'schedule_type': _schedule, 'skips_meals': _skipsMeals,
      }),
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ObLabel('Wake up time'),
            TextField(controller: _wakeC, decoration: const InputDecoration(hintText: '07:00'), style: const TextStyle(color: AppColors.textPrimary)),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ObLabel('Bedtime'),
            TextField(controller: _sleepC, decoration: const InputDecoration(hintText: '23:00'), style: const TextStyle(color: AppColors.textPrimary)),
          ])),
        ]),
        const SizedBox(height: 16),
        ObLabel('Your schedule'),
        PillOptions(options: const ['College Student', 'Working Professional', 'Other'], values: const ['college', 'working', 'other'],
          selected: _schedule, onSelect: (v) => setState(() => _schedule = v)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _skipsMeals = !_skipsMeals),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _skipsMeals ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _skipsMeals ? AppColors.accent : AppColors.border2),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('I often skip meals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(_skipsMeals ? '✓ Missed meal recovery activated' : 'Tap to activate missed meal recovery',
                  style: TextStyle(fontSize: 12, color: _skipsMeals ? AppColors.accent : AppColors.textSecondary, height: 1.4)),
              ])),
              Switch(value: _skipsMeals, onChanged: (v) => setState(() => _skipsMeals = v), activeColor: AppColors.accent),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── DIET SCREEN ──────────────────────────────────────────
class DietScreen extends StatefulWidget {
  const DietScreen({super.key});
  @override State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  final _favC = TextEditingController();
  List<String> _pantry = [];

  @override
  void dispose() { _favC.dispose(); super.dispose(); }

  void _togglePantry(String item) => setState(() {
    _pantry.contains(item) ? _pantry.remove(item) : _pantry.add(item);
  });

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final diet = args?['diet_type'] ?? 'veg_eggs';
    const pantryItems = ['Peanut Butter', 'Sattu', 'Roasted Chana', 'Makhana', 'Almonds', 'Milk', 'Eggs', 'Ghee', 'Bread'];
    return OnboardingBase(
      step: 4, title: 'What do you eat?',
      subtitle: 'This personalizes your food suggestions and AI advice.',
      onBack: () => Navigator.pop(context),
      onContinue: () => Navigator.pushNamed(context, '/onboard/social', arguments: {
        ...?args, 'favorite_foods': _favC.text, 'pantry_items': _pantry,
      }),
      children: [
        AppCard(child: Row(children: [
          const Text('🥚', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Diet: ${diet.toString().replaceAll('_', ' + ')}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent)),
            const Text('Set in previous step', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
        ])),
        const SizedBox(height: 16),
        ObLabel('Favourite foods (optional)'),
        TextField(controller: _favC, maxLines: 2,
          decoration: const InputDecoration(hintText: 'e.g. dal, roti, eggs, peanut butter...'), style: const TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        ObLabel('What healthy items do you keep at home?'),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: pantryItems.map((item) {
            final isActive = _pantry.contains(item);
            return GestureDetector(
              onTap: () => _togglePantry(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.secondary : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? AppColors.secondary : AppColors.border2),
                ),
                child: Text(item, style: TextStyle(fontSize: 13, color: isActive ? AppColors.pale : AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── SOCIAL SCREEN ────────────────────────────────────────
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});
  @override State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _introvert = 5;
  String _energy = 'sometimes';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    return OnboardingBase(
      step: 5, title: 'Just a couple more things',
      subtitle: 'This helps the app support your mental wellbeing, not just calories.',
      onBack: () => Navigator.pop(context),
      onContinue: () => Navigator.pushNamed(context, '/onboard/notifications', arguments: {
        ...?args, 'introvert_score': _introvert, 'energy_baseline': _energy,
      }),
      children: [
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How comfortable are you eating around others?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4)),
          const SizedBox(height: 12),
          Row(children: List.generate(10, (i) {
            final n = i + 1;
            final isActive = n <= _introvert;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _introvert = n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 24, margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.secondary : AppColors.border2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ));
          })),
          const SizedBox(height: 8),
          Center(child: Text('$_introvert / 10', style: const TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent))),
          if (_introvert < 5)
            const Padding(padding: EdgeInsets.only(top: 6), child: Text('✓ Mess compass will help you find quiet eating windows', style: TextStyle(fontSize: 11, color: AppColors.accent))),
        ])),
        const SizedBox(height: 12),
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How often do you feel low energy or unmotivated?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            {'v': 'rarely', 'l': 'Rarely'}, {'v': 'sometimes', 'l': 'Sometimes'},
            {'v': 'often', 'l': 'Often'}, {'v': 'almost_always', 'l': 'Almost Always'},
          ].map((opt) {
            final isActive = _energy == opt['v'];
            return GestureDetector(
              onTap: () => setState(() => _energy = opt['v']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.secondary : AppColors.bg2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? AppColors.secondary : AppColors.border2),
                ),
                child: Text(opt['l']!, style: TextStyle(fontSize: 13, color: isActive ? AppColors.pale : AppColors.textSecondary)),
              ),
            );
          }).toList()),
          if (_energy == 'often' || _energy == 'almost_always')
            const Padding(padding: EdgeInsets.only(top: 8), child: Text('✓ Thought-to-action support will be activated', style: TextStyle(fontSize: 11, color: AppColors.accent))),
        ])),
      ],
    );
  }
}

// ── NOTIFICATIONS SCREEN ─────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Map<String, bool> _notifs = {'meals': true, 'water': true, 'checkin': true, 'streak': true, 'weekly': true};

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    const options = [
      {'key': 'meals', 'label': 'Meal Reminders', 'desc': 'Remind me to log meals throughout the day', 'icon': '🍽️'},
      {'key': 'water', 'label': 'Water Reminders', 'desc': 'Remind me to drink water every 2 hours', 'icon': '💧'},
      {'key': 'checkin', 'label': 'Daily AI Check-in', 'desc': 'Morning energy + mood check-in', 'icon': '🤖'},
      {'key': 'streak', 'label': 'Streak Alerts', 'desc': "Alert me before I lose my streak", 'icon': '🔥'},
      {'key': 'weekly', 'label': 'Weekly Review', 'desc': 'Sunday summary from your AI companion', 'icon': '📊'},
    ];
    return OnboardingBase(
      step: 6, title: 'Stay on track',
      subtitle: "All reminders are timed to your schedule. Change these anytime.",
      onBack: () => Navigator.pop(context),
      onContinue: () => Navigator.pushNamed(context, '/onboard/complete', arguments: {...?args, 'notifications': _notifs}),
      children: options.map((opt) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => setState(() => _notifs[opt['key'] as String] = !(_notifs[opt['key'] as String] ?? true)),
          child: AppCard(child: Row(children: [
            Text(opt['icon'] as String, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(opt['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(opt['desc'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
            ])),
            Switch(value: _notifs[opt['key'] as String] ?? true, onChanged: (v) => setState(() => _notifs[opt['key'] as String] = v), activeColor: AppColors.accent),
          ])),
        ),
      )).toList(),
    );
  }
}

// ── SETUP COMPLETE SCREEN ────────────────────────────────
class SetupCompleteScreen extends StatefulWidget {
  const SetupCompleteScreen({super.key});
  @override State<SetupCompleteScreen> createState() => _SetupCompleteScreenState();
}

class _SetupCompleteScreenState extends State<SetupCompleteScreen> {
  final _nameC = TextEditingController(text: 'GrowthMate AI');
  bool _loading = false;

  Future<void> _finish(Map args) async {
    setState(() => _loading = true);
    try {
      final target = CalcUtils.calculateDailyTarget(
        weightKg: (args['weight_kg'] as num).toDouble(),
        heightCm: (args['height_cm'] as num).toDouble(),
        dob: args['dob'] ?? '2004-01-01',
        gender: args['gender'] ?? 'male',
        activityMultiplier: (args['activity_multiplier'] as num? ?? 1.2).toDouble(),
        goalType: args['goal_type'] ?? 'gain_weight',
      );
      final user = UserModel(
        name: args['name'] ?? 'User',
        dob: args['dob'] ?? '2004-01-01',
        gender: args['gender'] ?? 'male',
        weightKg: (args['weight_kg'] as num).toDouble(),
        heightCm: (args['height_cm'] as num).toDouble(),
        bmi: (args['bmi'] as num? ?? 20).toDouble(),
        goalWeightKg: (args['goal_weight_kg'] as num? ?? 60).toDouble(),
        goalType: args['goal_type'] ?? 'gain_weight',
        activityLevel: args['activity_level'] ?? 'sedentary',
        dietType: args['diet_type'] ?? 'veg_eggs',
        favoriteFoods: args['favorite_foods'] ?? '',
        wakeTime: args['wake_time'] ?? '07:00',
        sleepTime: args['sleep_time'] ?? '23:00',
        scheduleType: args['schedule_type'] ?? 'college',
        skipsMeals: args['skips_meals'] ?? false,
        introvertScore: args['introvert_score'] ?? 5,
        energyBaseline: args['energy_baseline'] ?? 'sometimes',
        dailyKcalTarget: target,
        proteinTargetG: ((args['weight_kg'] as num).toDouble() * 1.8).roundToDouble(),
        waterTargetGlasses: 8,
        pantryItemsJson: (args['pantry_items'] as List?)?.toString() ?? '[]',
        aiCompanionName: _nameC.text.trim().isNotEmpty ? _nameC.text.trim() : 'GrowthMate AI',
        notificationsJson: args['notifications']?.toString() ?? '{}',
        onboardingComplete: 1,
      );
      await AppDatabase.instance.createUser(user);
      if (mounted) {
        if (context.mounted) context.read<AppState>().loadAll();
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (e) { debugPrint('Setup error: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final target = CalcUtils.calculateDailyTarget(
      weightKg: (args['weight_kg'] as num? ?? 60).toDouble(),
      heightCm: (args['height_cm'] as num? ?? 170).toDouble(),
      dob: args['dob'] ?? '2004-01-01', gender: args['gender'] ?? 'male',
      activityMultiplier: (args['activity_multiplier'] as num? ?? 1.2).toDouble(),
      goalType: args['goal_type'] ?? 'gain_weight',
    );
    final startWeight = (args['weight_kg'] as num? ?? 52).toDouble();
    final milestone = startWeight + 0.5;
    return OnboardingBase(
      step: 7, title: "You're all set! 🎉",
      subtitle: "Here's your personalized plan based on your details.",
      onBack: () => Navigator.pop(context),
      loading: _loading,
      onContinue: () => _finish(args),
      children: [
        _RevealCard(label: 'Daily calorie goal', value: '${target.round()}', unit: 'kcal', color: AppColors.accent, subtitle: 'Calculated from your stats, goal, and activity'),
        const SizedBox(height: 10),
        _RevealCard(label: 'First milestone', value: milestone.toStringAsFixed(1), unit: 'kg', color: AppColors.amber, subtitle: 'Just +0.5kg from now — your first win'),
        const SizedBox(height: 10),
        _RevealCard(label: 'Protein target', value: '${(startWeight * 1.8).round()}', unit: 'g/day', color: AppColors.blue, subtitle: 'For muscle growth and recovery'),
        const SizedBox(height: 16),
        ObLabel('Name your AI companion'),
        TextField(controller: _nameC, decoration: const InputDecoration(hintText: 'GrowthMate AI'), style: const TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('This is what your AI will be called in chats', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }
}

class _RevealCard extends StatelessWidget {
  final String label, value, unit, subtitle;
  final Color color;
  const _RevealCard({required this.label, required this.value, required this.unit, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: color, width: 3), top: const BorderSide(color: AppColors.border), right: const BorderSide(color: AppColors.border), bottom: const BorderSide(color: AppColors.border))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      RichText(text: TextSpan(children: [
        TextSpan(text: value, style: TextStyle(fontFamily: 'Syne', fontSize: 32, fontWeight: FontWeight.w800, color: color)),
        TextSpan(text: ' $unit', style: const TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      ])),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
    ]),
  );
}
