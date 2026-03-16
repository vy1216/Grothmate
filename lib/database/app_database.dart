import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_swls.dart';
import 'package:path/path.dart';
import '../models/models.dart';
import '../constants/food_database.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();
  static AppDatabase get instance => _instance ??= AppDatabase._();

  Future<Database> get database async => _db ??= await _init();

  Future<Database> _init() async {
    if (kIsWeb) {
      // Use indexedDB based storage for web persistence
      var factory = createDatabaseFactoryFfiWeb();
      _db = await factory.openDatabase('growthmate.db', options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ));
      return _db!;
    }
    final path = join(await getDatabasesPath(), 'growthmate.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, dob TEXT, gender TEXT DEFAULT 'male',
      weight_kg REAL, height_cm REAL, bmi REAL, goal_weight_kg REAL, goal_type TEXT,
      activity_level TEXT DEFAULT 'sedentary', diet_type TEXT, favorite_foods TEXT DEFAULT '',
      wake_time TEXT DEFAULT '07:00', sleep_time TEXT DEFAULT '23:00',
      schedule_type TEXT DEFAULT 'college', skips_meals INTEGER DEFAULT 0,
      introvert_score INTEGER DEFAULT 5, energy_baseline TEXT DEFAULT 'sometimes',
      daily_kcal_target REAL DEFAULT 2000, protein_target_g REAL DEFAULT 80,
      water_target_glasses INTEGER DEFAULT 8, pantry_items_json TEXT DEFAULT '[]',
      ai_companion_name TEXT DEFAULT 'GrowthMate AI', notifications_json TEXT DEFAULT '{}',
      best_streak INTEGER DEFAULT 0, onboarding_complete INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS meal_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, meal_slot TEXT, food_name TEXT,
      food_id INTEGER, portion_g REAL, calories REAL, protein_g REAL, carbs_g REAL,
      fat_g REAL, sugar_g REAL, fiber_g REAL DEFAULT 0, is_photo_log INTEGER DEFAULT 0,
      estimated INTEGER DEFAULT 0, logged_at TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS food_database (
      id INTEGER PRIMARY KEY, name TEXT, category TEXT, aliases TEXT, serving_size_g REAL,
      cal_per_100g REAL, protein_per_100g REAL, carbs_per_100g REAL, fat_per_100g REAL,
      sugar_per_100g REAL, fiber_per_100g REAL, is_indian INTEGER DEFAULT 1)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS workout_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, exercise_name TEXT,
      category TEXT, sets INTEGER DEFAULT 0, reps INTEGER DEFAULT 0,
      duration_sec INTEGER DEFAULT 0, calories_burned REAL DEFAULT 0,
      energy_after INTEGER DEFAULT 2, logged_at TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS mood_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, mood_score INTEGER,
      mood_label TEXT, energy_score INTEGER DEFAULT 3, note TEXT DEFAULT '',
      source TEXT DEFAULT 'manual', logged_at TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS water_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, glasses INTEGER,
      logged_at TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS weight_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, weight_kg REAL,
      logged_at TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS ai_conversations (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, role TEXT, content TEXT,
      mode TEXT DEFAULT 'health', logged_at TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS vault_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, content TEXT,
      duration_sec INTEGER DEFAULT 0, ai_readable INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS daily_completions (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, date TEXT,
      actions_completed_json TEXT DEFAULT '[]', streak_maintained INTEGER DEFAULT 0,
      UNIQUE(user_id, date))''');

    await db.execute('''CREATE TABLE IF NOT EXISTS pattern_insights (
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, insight_type TEXT,
      insight_text TEXT, data_json TEXT DEFAULT '{}',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP, dismissed INTEGER DEFAULT 0)''');

    await _seedFoodDatabase(db);
  }

  Future<void> _seedFoodDatabase(Database db) async {
    final batch = db.batch();
    for (final food in kFoodDatabase) {
      batch.insert(
        'food_database',
        food.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // ── USER ──────────────────────────────────────────────
  Future<UserModel?> getUser() async {
    final db = await database;
    final rows = await db.query('users', limit: 1);
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<int> createUser(UserModel user) async {
    final db = await database;
    final id = await db.insert('users', user.toMap());
    await db.insert('weight_entries', {
      'user_id': id,
      'weight_kg': user.weightKg,
      'logged_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  // ── MEALS ─────────────────────────────────────────────
  Future<void> logMeal(MealLog meal) async {
    final db = await database;
    await db.insert('meal_logs', meal.toMap());
  }

  Future<List<MealLog>> getTodayMeals(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rows = await db.query(
      'meal_logs',
      where: "user_id = ? AND date(logged_at) = ?",
      whereArgs: [userId, today],
      orderBy: 'logged_at ASC',
    );
    return rows.map(MealLog.fromMap).toList();
  }

  Future<void> deleteMealLog(int id) async {
    final db = await database;
    await db.delete('meal_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MealLog>> getRecentMeals(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT food_name, food_id, calories, protein_g, carbs_g, fat_g, sugar_g, portion_g, meal_slot FROM meal_logs WHERE user_id = ? ORDER BY logged_at DESC LIMIT 20',
      [userId],
    );
    return rows.map(MealLog.fromMap).toList();
  }

  // ── FOOD SEARCH ───────────────────────────────────────
  Future<List<FoodItem>> searchFoods(String query) async {
    if (query.length < 2) return [];
    // On web, search from the in-memory constant list directly (faster)
    if (kIsWeb) {
      final q = query.toLowerCase();
      return kFoodDatabase
          .where((f) =>
              f.name.toLowerCase().contains(q) ||
              f.aliases.toLowerCase().contains(q) ||
              f.category.toLowerCase().contains(q))
          .take(20)
          .toList();
    }
    final q = '%$query%';
    final db = await database;
    final rows = await db.query(
      'food_database',
      where: 'name LIKE ? OR aliases LIKE ?',
      whereArgs: [q, q],
      limit: 20,
    );
    return rows.map(FoodItem.fromMap).toList();
  }

  // ── WORKOUTS ──────────────────────────────────────────
  Future<void> logWorkout(WorkoutLog workout) async {
    final db = await database;
    await db.insert('workout_logs', workout.toMap());
  }

  Future<List<WorkoutLog>> getTodayWorkouts(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rows = await db.query(
      'workout_logs',
      where: "user_id = ? AND date(logged_at) = ?",
      whereArgs: [userId, today],
    );
    return rows.map(WorkoutLog.fromMap).toList();
  }

  Future<List<WorkoutLog>> getWeekWorkouts(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT * FROM workout_logs WHERE user_id = ? AND date(logged_at) >= date('now','-7 days') ORDER BY logged_at DESC",
      [userId],
    );
    return rows.map(WorkoutLog.fromMap).toList();
  }

  // ── MOOD ──────────────────────────────────────────────
  Future<void> logMood(MoodLog mood) async {
    final db = await database;
    await db.insert('mood_logs', mood.toMap());
  }

  Future<MoodLog?> getTodayMood(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final rows = await db.query(
      'mood_logs',
      where: "user_id = ? AND date(logged_at) = ?",
      whereArgs: [userId, today],
      orderBy: 'logged_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : MoodLog.fromMap(rows.first);
  }

  // ── WATER ─────────────────────────────────────────────
  Future<void> addWaterGlass(int userId) async {
    final db = await database;
    await db.insert('water_logs', {
      'user_id': userId,
      'glasses': 1,
      'logged_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getTodayWater(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(glasses),0) as total FROM water_logs WHERE user_id = ? AND date(logged_at) = ?",
      [userId, today],
    );
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  // ── WEIGHT ────────────────────────────────────────────
  Future<void> logWeight(int userId, double weightKg) async {
    final db = await database;
    await db.insert('weight_entries', {
      'user_id': userId,
      'weight_kg': weightKg,
      'logged_at': DateTime.now().toIso8601String(),
    });
    await updateUser(userId, {'weight_kg': weightKg});
  }

  Future<List<WeightEntry>> getWeightHistory(int userId) async {
    final db = await database;
    final rows = await db.query(
      'weight_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at ASC',
    );
    return rows.map(WeightEntry.fromMap).toList();
  }

  // ── AI CONVERSATIONS ───────────────────────────────────
  Future<void> saveMessage(int userId, String role, String content) async {
    final db = await database;
    await db.insert('ai_conversations', {
      'user_id': userId,
      'role': role,
      'content': content,
      'logged_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getConversationHistory(
    int userId, {
    int limit = 10,
  }) async {
    final db = await database;
    final rows = await db.query(
      'ai_conversations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at DESC',
      limit: limit,
    );
    return rows.reversed.toList();
  }

  // ── VAULT ─────────────────────────────────────────────
  Future<void> saveVaultEntry(VaultEntry entry) async {
    final db = await database;
    await db.insert('vault_entries', entry.toMap());
  }

  Future<List<VaultEntry>> getVaultEntries(int userId) async {
    final db = await database;
    final rows = await db.query(
      'vault_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(VaultEntry.fromMap).toList();
  }

  // ── STREAK ────────────────────────────────────────────
  Future<int> getCurrentStreak(int userId) async {
    final db = await database;
    final rows = await db.query(
      'daily_completions',
      where: "user_id = ? AND streak_maintained = 1",
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    if (rows.isEmpty) return 0;
    int streak = 0;
    DateTime expected = DateTime.now();
    for (final row in rows) {
      final d = DateTime.parse(row['date'] as String);
      final int diff = expected
          .difference(d)
          .inDays
          .abs();
      if (diff <= 1) {
        streak++;
        expected = d;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> markStreakAction(int userId, String action) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final existing = await db.query(
      'daily_completions',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, today],
    );
    if (existing.isEmpty) {
      await db.insert(
        'daily_completions',
        {
          'user_id': userId,
          'date': today,
          'actions_completed_json': '["$action"]',
          'streak_maintained': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } else {
      await db.update(
        'daily_completions',
        {'streak_maintained': 1},
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, today],
      );
    }
  }

  // ── WEEK STATS ────────────────────────────────────────
  Future<Map<String, dynamic>> getWeekStats(int userId) async {
    final db = await database;
    final meals = await db.rawQuery(
      "SELECT date(logged_at) as day, SUM(calories) as total FROM meal_logs WHERE user_id = ? AND date(logged_at) >= date('now','-7 days') GROUP BY day",
      [userId],
    );
    final moods = await db.rawQuery(
      "SELECT AVG(mood_score) as avg_mood FROM mood_logs WHERE user_id = ? AND date(logged_at) >= date('now','-7 days')",
      [userId],
    );
    final workouts = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM workout_logs WHERE user_id = ? AND date(logged_at) >= date('now','-7 days')",
      [userId],
    );
    final user = await getUser();
    final double target = user?.dailyKcalTarget ?? 2000;
    final double totalKcal = meals.fold(
      0.0,
      (s, m) => s + (m['total'] as num? ?? 0).toDouble(),
    );
    final double avgKcal = meals.isNotEmpty ? totalKcal / 7 : 0.0;
    final int daysHit = meals
        .where((m) => (m['total'] as num? ?? 0).toDouble() >= target)
        .length;
    return {
      'avg_kcal': avgKcal.round(),
      'days_hit': daysHit,
      'avg_mood': (moods.first['avg_mood'] as num? ?? 0).toDouble(),
      'workout_count': (workouts.first['cnt'] as num? ?? 0).toInt(),
      'daily_breakdown': meals,
    };
  }

  // ── INSIGHTS ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getInsights(int userId) async {
    final db = await database;
    return db.query(
      'pattern_insights',
      where: 'user_id = ? AND dismissed = 0',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> dismissInsight(int id) async {
    final db = await database;
    await db.update(
      'pattern_insights',
      {'dismissed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
