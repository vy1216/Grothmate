import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../database/app_database.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../utils/calc_utils.dart';
import '../../widgets/common_widgets.dart';

class LogMealScreen extends StatefulWidget {
  const LogMealScreen({super.key});
  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final TextEditingController _searchC = TextEditingController();
  String _tab = 'Search';
  List<FoodItem> _results = [];
  List<MealLog> _recent = [];
  FoodItem? _selected;
  double _portionMult = 1.0;
  bool _searching = false;
  String _slot = 'dinner';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      final user = context.read<AppState>().user;
      setState(() {
        _slot = (args?['slot'] as String?) ??
            CalcUtils.getMealSlot(
              user?.wakeTime ?? '07:00',
              user?.sleepTime ?? '23:00',
            );
      });
      _loadRecent();
    });
  }

  Future<void> _loadRecent() async {
    final user = context.read<AppState>().user;
    if (user == null) return;
    final r = await AppDatabase.instance.getRecentMeals(user.id!);
    if (mounted) setState(() => _recent = r);
  }

  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final r = await AppDatabase.instance.searchFoods(q);
    if (mounted) setState(() { _results = r; _searching = false; });
  }

  Future<void> _logFood(FoodItem food, double portionG) async {
    final user = context.read<AppState>().user;
    if (user == null) return;
    final macros = food.macrosForPortion(portionG);
    await AppDatabase.instance.logMeal(MealLog(
      userId: user.id!,
      mealSlot: _slot,
      foodName: food.name,
      foodId: food.id,
      portionG: portionG,
      calories: macros.calories,
      proteinG: macros.protein,
      carbsG: macros.carbs,
      fatG: macros.fat,
      sugarG: macros.sugar,
      fiberG: macros.fiber,
      loggedAt: DateTime.now().toIso8601String(),
    ));
    await AppDatabase.instance.markStreakAction(user.id!, 'meal_logged');
    if (!mounted) return;
    await context.read<AppState>().refreshMeals();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '${food.name} logged! +${macros.calories.round()} kcal',
      ),
      backgroundColor: AppColors.accent.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ));
  }

  static String _getCatEmoji(String cat) {
    const Map<String, String> m = {
      'Dal': '🫘',
      'Bread': '🫓',
      'Rice': '🍚',
      'Curry': '🍛',
      'Egg': '🥚',
      'Snack': '🍪',
      'Peanut Butter': '🥜',
      'Health': '💚',
      'Beverage': '🥛',
      'Street Food': '🥙',
      'Dairy': '🧀',
      'Fruit': '🍎',
      'Supplement': '💊',
      'Protein': '💪',
      'South Indian': '🫓',
    };
    return m[cat] ?? '🍽️';
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            _buildHeader(),
            PillTabBar(
              tabs: const ['Search', 'Recent'],
              active: _tab,
              onChanged: (t) => setState(() => _tab = t),
            ),
            Expanded(
              child: _tab == 'Search' ? _buildSearch() : _buildRecent(),
            ),
          ]),
          if (_selected != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _FoodDetailPanel(
                food: _selected!,
                portionMult: _portionMult,
                onPortionChange: (m) => setState(() => _portionMult = m),
                onLog: () => _logFood(
                  _selected!,
                  _selected!.servingSizeG * _portionMult,
                ),
                onClose: () => setState(() {
                  _selected = null;
                  _portionMult = 1.0;
                }),
                slot: _slot,
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Log meal',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            CalcUtils.capitalize(_slot),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSearch() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border2),
          ),
          child: Row(children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: AppColors.textHint, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchC,
                onChanged: _search,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search dal, roti, eggs, peanut butter...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchC.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchC.clear();
                  setState(() => _results = []);
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.close, color: AppColors.textHint, size: 16),
                ),
              ),
          ]),
        ),
      ),
      Expanded(
        child: _searching
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text(
                            _searchC.text.length < 2
                                ? 'Type 2+ characters to search'
                                : 'No results for "${_searchC.text}"',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try: dal, roti, egg, rice, peanut butter, chai...',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (ctx, i) {
                      final food = _results[i];
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selected = food;
                          _portionMult = 1.0;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.card2,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  _getCatEmoji(food.category),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${food.category} · ${food.servingSizeG.round()}g serving',
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
                                  '${food.caloriesPerServing.round()}',
                                  style: const TextStyle(
                                    fontFamily: 'Syne',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const Text(
                                  'kcal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _buildRecent() {
    if (_recent.isEmpty) {
      return const EmptyState(
        emoji: '📋',
        title: 'No recent foods yet',
        subtitle: 'Log your first meal to see it here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recent.length,
      itemBuilder: (ctx, i) {
        final item = _recent[i];
        return GestureDetector(
          onTap: () async {
            final user = context.read<AppState>().user;
            if (user == null) return;
            await AppDatabase.instance.logMeal(MealLog(
              userId: user.id!,
              mealSlot: _slot,
              foodName: item.foodName,
              foodId: item.foodId,
              portionG: item.portionG,
              calories: item.calories,
              proteinG: item.proteinG,
              carbsG: item.carbsG,
              fatG: item.fatG,
              sugarG: item.sugarG,
              loggedAt: DateTime.now().toIso8601String(),
            ));
            if (!mounted) return;
            await context.read<AppState>().refreshMeals();
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Last logged · ${item.portionG.round()}g',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.calories.round()}',
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.add_circle_outline,
                color: AppColors.accent,
                size: 20,
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ── FOOD DETAIL PANEL ────────────────────────────────────
class _FoodDetailPanel extends StatelessWidget {
  final FoodItem food;
  final double portionMult;
  final ValueChanged<double> onPortionChange;
  final VoidCallback onLog, onClose;
  final String slot;

  const _FoodDetailPanel({
    required this.food,
    required this.portionMult,
    required this.onPortionChange,
    required this.onLog,
    required this.onClose,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    final double portionG = food.servingSizeG * portionMult;
    final MacroResult macros = food.macrosForPortion(portionG);

    final List<Map<String, dynamic>> sizes = [
      {'label': 'Small', 'mult': 0.6},
      {'label': 'Medium', 'mult': 1.0},
      {'label': 'Large', 'mult': 1.6},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${food.category} · ${portionG.round()}g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: const Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(
            children: sizes.map((s) {
              final bool isActive = portionMult == s['mult'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPortionChange(s['mult'] as double),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.bg2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? AppColors.accent : AppColors.border2,
                      ),
                    ),
                    child: Column(children: [
                      Text(
                        s['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(food.servingSizeG * (s['mult'] as double)).round()}g',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive
                              ? AppColors.light
                              : AppColors.textHint,
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MacroChip('${macros.calories.round()} kcal', AppColors.accent),
              _MacroChip('P: ${macros.protein.toStringAsFixed(1)}g', AppColors.accent),
              _MacroChip('C: ${macros.carbs.toStringAsFixed(1)}g', AppColors.amber),
              _MacroChip('F: ${macros.fat.toStringAsFixed(1)}g', AppColors.blue),
              _MacroChip(
                'S: ${macros.sugar.toStringAsFixed(1)}g',
                macros.sugar > 15 ? AppColors.coral : AppColors.textSecondary,
              ),
            ],
          ),
          if (macros.sugar > 15) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.coral.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Text('⚠️ ', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    'High sugar detected. Consider a lower-sugar option.',
                    style: TextStyle(fontSize: 12, color: AppColors.coral),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onLog,
              child: Text('Log to ${CalcUtils.capitalize(slot)} →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MacroChip(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.bg2,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'Syne',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}
