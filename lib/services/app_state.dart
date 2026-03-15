import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  UserModel? _user;
  List<MealLog> _todayMeals = [];
  int _water = 0;
  MoodLog? _todayMood;
  int _streak = 0;
  List<WeightEntry> _weightHistory = [];
  List<WorkoutLog> _weekWorkouts = [];
  Map<String, dynamic> _weekStats = {};
  bool _loading = false;

  UserModel? get user => _user;
  List<MealLog> get todayMeals => _todayMeals;
  int get water => _water;
  MoodLog? get todayMood => _todayMood;
  int get streak => _streak;
  List<WeightEntry> get weightHistory => _weightHistory;
  List<WorkoutLog> get weekWorkouts => _weekWorkouts;
  Map<String, dynamic> get weekStats => _weekStats;
  bool get loading => _loading;

  double get totalCalToday => _todayMeals.fold(0, (s, m) => s + m.calories);
  double get totalProteinToday => _todayMeals.fold(0, (s, m) => s + m.proteinG);
  double get totalCarbsToday => _todayMeals.fold(0, (s, m) => s + m.carbsG);
  double get totalFatToday => _todayMeals.fold(0, (s, m) => s + m.fatG);
  double get totalSugarToday => _todayMeals.fold(0, (s, m) => s + m.sugarG);

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    try {
      _user = await AppDatabase.instance.getUser();
      if (_user != null) {
        final id = _user!.id!;
        final results = await Future.wait([
          AppDatabase.instance.getTodayMeals(id),
          AppDatabase.instance.getTodayMood(id),
          AppDatabase.instance.getTodayWater(id),
          AppDatabase.instance.getCurrentStreak(id),
          AppDatabase.instance.getWeightHistory(id),
          AppDatabase.instance.getWeekWorkouts(id),
          AppDatabase.instance.getWeekStats(id),
        ]);
        _todayMeals = results[0] as List<MealLog>;
        _todayMood = results[1] as MoodLog?;
        _water = results[2] as int;
        _streak = results[3] as int;
        _weightHistory = results[4] as List<WeightEntry>;
        _weekWorkouts = results[5] as List<WorkoutLog>;
        _weekStats = results[6] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('AppState loadAll error: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshMeals() async {
    if (_user == null) return;
    _todayMeals = await AppDatabase.instance.getTodayMeals(_user!.id!);
    notifyListeners();
  }

  Future<void> addWater() async {
    if (_user == null) return;
    await AppDatabase.instance.addWaterGlass(_user!.id!);
    await AppDatabase.instance.markStreakAction(_user!.id!, 'water');
    _water++;
    notifyListeners();
  }

  Future<void> logMoodUpdate(MoodLog mood) async {
    await AppDatabase.instance.logMood(mood);
    _todayMood = mood;
    notifyListeners();
  }

  Future<void> deleteMeal(int mealId) async {
    await AppDatabase.instance.deleteMealLog(mealId);
    await refreshMeals();
  }

  Future<void> addWeight(double kg) async {
    if (_user == null) return;
    await AppDatabase.instance.logWeight(_user!.id!, kg);
    _weightHistory = await AppDatabase.instance.getWeightHistory(_user!.id!);
    _user = await AppDatabase.instance.getUser();
    notifyListeners();
  }

  Future<void> refreshWorkouts() async {
    if (_user == null) return;
    _weekWorkouts = await AppDatabase.instance.getWeekWorkouts(_user!.id!);
    _weekStats = await AppDatabase.instance.getWeekStats(_user!.id!);
    notifyListeners();
  }

  Future<void> refreshStreak() async {
    if (_user == null) return;
    _streak = await AppDatabase.instance.getCurrentStreak(_user!.id!);
    notifyListeners();
  }

  Future<void> setUser(UserModel user) async {
    _user = user;
    notifyListeners();
  }
}
