import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/models.dart';
import '../constants/food_database.dart';
import 'web_storage.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();
  static AppDatabase get instance => _instance ??= AppDatabase._();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    return _db ??= await _init();
  }

  Future<Database> _init() async {
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
    if (kIsWeb) {
      final rows = await WebStorage.load('users');
      return rows.isEmpty ? null : UserModel.fromMap(rows.first);
    }
    final db = await database;
    if (db == null) return null;
    final rows = await db.query('users', limit: 1);
    return rows.isEmpty ? null : UserModel.fromMap(rows.first);
  }

  Future<int> createUser(UserModel user) async {
    if (kIsWeb) {
      final id = await WebStorage.insert('users', user.toMap());
      await WebStorage.insert('weight_entries', {
        'user_id': id,
        'weight_kg': user.weightKg,
        'logged_at': DateTime.now().toIso8601String(),
      });
      return id;
    }
    final db = await database;
    if (db == null) return 0;
    final id = await db.insert('users', user.toMap());
    await db.insert('weight_entries', {
      'user_id': id,
      'weight_kg': user.weightKg,
      'logged_at': DateTime.now().toIso8601String(),
    });
    return id;
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    if (kIsWeb) {
      await WebStorage.update('users', id, data);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  // ── MEALS ─────────────────────────────────────────────
  Future<void> logMeal(MealLog meal) async {
    if (kIsWeb) {
      await WebStorage.insert('meal_logs', meal.toMap());
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('meal_logs', meal.toMap());
  }

  Future<List<MealLog>> getTodayMeals(int userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (kIsWeb) {
      final rows = await WebStorage.load('meal_logs');
      final filtered = rows.where((r) => 
        r['user_id'] == userId && 
        (r['logged_at'] as String).startsWith(today)
      ).toList();
      return filtered.map(MealLog.fromMap).toList();
    }
    final db = await database;
    if (db == null) return [];
    final rows = await db.query(
      'meal_logs',
      where: "user_id = ? AND date(logged_at) = ?",
      whereArgs: [userId, today],
      orderBy: 'logged_at ASC',
    );
    return rows.map(MealLog.fromMap).toList();
  }

  Future<void> deleteMealLog(int id) async {
    if (kIsWeb) {
      await WebStorage.delete('meal_logs', id);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.delete('meal_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MealLog>> getRecentMeals(int userId) async {
    if (kIsWeb) {
      final rows = await WebStorage.load('meal_logs');
      final filtered = rows.where((r) => r['user_id'] == userId).toList();
      final sorted = filtered.reversed.take(20).toList();
      return sorted.map(MealLog.fromMap).toList();
    }
    final db = await database;
    if (db == null) return [];
    final rows = await db.rawQuery(
      'SELECT DISTINCT user_id, food_name, food_id, calories, protein_g, carbs_g, fat_g, sugar_g, portion_g, meal_slot, logged_at FROM meal_logs WHERE user_id = ? ORDER BY logged_at DESC LIMIT 20',
      [userId],
    );
    return rows.map(MealLog.fromMap).toList();
  }

  // ── FOOD SEARCH ───────────────────────────────────────
  Future<List<FoodItem>> searchFoods(String query) async {
    if (query.length < 2) return [];
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
    if (db == null) return [];
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
    if (kIsWeb) {
      await WebStorage.insert('workout_logs', workout.toMap());
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('workout_logs', workout.toMap());
  }

  Future<List<WorkoutLog>> getTodayWorkouts(int userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (kIsWeb) {
      final rows = await WebStorage.load('workout_logs');
      final filtered = rows.where((r) => 
        r['user_id'] == userId && 
        (r['logged_at'] as String).startsWith(today)
      ).toList();
      return filtered.map(WorkoutLog.fromMap).toList();
    }
    final db = await database;
    if (db == null) return [];
    final rows = await db.query(
      'workout_logs',
      where: "user_id = ? AND date(logged_at) = ?",
      whereArgs: [userId, today],
    );
    return rows.map(WorkoutLog.fromMap).toList();
  }

  Future<List<WorkoutLog>> getWeekWorkouts(int userId) async {
    if (kIsWeb) {
      final rows = await WebStorage.load('workout_logs');
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final filtered = rows.where((r) => 
        r['user_id'] == userId && 
        DateTime.parse(r['logged_at'] as String).isAfter(sevenDaysAgo)
      ).toList();
      return filtered.map(WorkoutLog.fromMap).toList();
    }
    final db = await database;
    if (db == null) return [];
    final rows = await db.rawQuery(
      "SELECT * FROM workout_logs WHERE user_id = ? AND date(logged_at) >= date('now','-7 days') ORDER BY logged_at DESC",
      [userId],
    );
    return rows.map(WorkoutLog.fromMap).toList();
  }

  // ── MOOD ──────────────────────────────────────────────
  Future<void> logMood(MoodLog mood) async {
    if (kIsWeb) {
      await WebStorage.insert('mood_logs', mood.toMap());
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('mood_logs', mood.toMap());
  }

  Future<MoodLog?> getTodayMood(int userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (kIsWeb) {
      final rows = await WebStorage.load('mood_logs');
      final filtered = rows.where((r) => 
        r['user_id'] == userId && 
        (r['logged_at'] as String).startsWith(today)
      ).toList();
      return filtered.isEmpty ? null : MoodLog.fromMap(filtered.last);
    }
    final db = await database;
    if (db == null) return null;
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
    if (kIsWeb) {
      await WebStorage.insert('water_logs', {
        'user_id': userId,
        'glasses': 1,
        'logged_at': DateTime.now().toIso8601String(),
      });
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('water_logs', {
      'user_id': userId,
      'glasses': 1,
      'logged_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getTodayWater(int userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (kIsWeb) {
      final rows = await WebStorage.load('water_logs');
      final filtered = rows.where((r) => 
        r['user_id'] == userId && 
        (r['logged_at'] as String).startsWith(today)
      ).toList();
      int total = 0;
      for (var r in filtered) {
        total += (r['glasses'] as int);
      }
      return total;
    }
    final db = await database;
    if (db == null) return 0;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(glasses),0) as total FROM water_logs WHERE user_id = ? AND date(logged_at) = ?",
      [userId, today],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── VAULT ─────────────────────────────────────────────
  Future<void> saveVaultEntry(VaultEntry entry) async {
    if (kIsWeb) {
      await WebStorage.insert('vault_entries', entry.toMap());
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('vault_entries', entry.toMap());
  }

  Future<List<VaultEntry>> getVaultEntries(int userId) async {
    if (kIsWeb) {
      final rows = await WebStorage.load('vault_entries');
      final filtered = rows.where((r) => r['user_id'] == userId).toList();
      return filtered.map(VaultEntry.fromMap).toList();
    }
    final db = await database;
    if (db == null) return [];
    final rows = await db.query(
      'vault_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(VaultEntry.fromMap).toList();
  }

  // ── CHAT ──────────────────────────────────────────────
  Future<void> saveMessage(int userId, String role, String content, [String mode = 'health']) async {
    await logChat(userId, role, content, mode);
  }
  Future<void> logWeight(int userId, double kg) async {
    if (kIsWeb) {
      await WebStorage.insert('weight_entries', {
        'user_id': userId,
        'weight_kg': kg,
        'logged_at': DateTime.now().toIso8601String(),
      });
      final user = await getUser();
      if (user != null) {
        final double bmi = kg / ((user.heightCm / 100) * (user.heightCm / 100));
        await updateUser(userId, {'weight_kg': kg, 'bmi': bmi});
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('weight_entries', {
      'user_id': userId,
      'weight_kg': kg,
      'logged_at': DateTime.now().toIso8601String(),
    });
    final user = await getUser();
    if (user != null) {
      final double bmi = kg / ((user.heightCm / 100) * (user.heightCm / 100));
      await updateUser(userId, {'weight_kg': kg, 'bmi': bmi});
    }
  }

  Future<List<WeightEntry>> getWeightHistory(int userId) async {
    if (kIsWeb) {
      final rows = await WebStorage.load('weight_entries');
      final filtered = rows.where((r) => r['user_id'] == userId).toList();
      return filtered.map(WeightEntry.fromMap).toList();
    }
    final db = await database;
    if (db == null) return [];
    final rows = await db.query(
      'weight_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'logged_at ASC',
    );
    return rows.map(WeightEntry.fromMap).toList();
  }

  // ── CHAT ──────────────────────────────────────────────
  Future<void> logChat(int userId, String role, String content, [String mode = 'health']) async {
    final data = {
      'user_id': userId,
      'role': role,
      'content': content,
      'mode': mode,
      'logged_at': DateTime.now().toIso8601String(),
    };
    if (kIsWeb) {
      await WebStorage.insert('ai_conversations', data);
      return;
    }
    final db = await database;
    if (db == null) return;
    await db.insert('ai_conversations', data);
  }

  Future<List<Map<String, dynamic>>> getConversationHistory(int userId, {int limit = 50, String mode = 'health'}) async {
    if (kIsWeb) {
      final rows = await WebStorage.load('ai_conversations');
      final filtered = rows.where((r) => r['user_id'] == userId && r['mode'] == mode).toList();
      return filtered.reversed.take(limit).toList().reversed.toList();
    }
    final db = await database;
    if (db == null) return [];
    final rows = await db.query(
      'ai_conversations',
      where: 'user_id = ? AND mode = ?',
      whereArgs: [userId, mode],
      orderBy: 'logged_at DESC',
      limit: limit,
    );
    return rows.reversed.toList();
  }

  // ── STREAK ────────────────────────────────────────────
  Future<int> getCurrentStreak(int userId) async {
    final user = await getUser();
    return user?.bestStreak ?? 0;
  }

  Future<void> markStreakAction(int userId, String action) async {
    final date = DateTime.now().toIso8601String().split('T')[0];
    if (kIsWeb) {
      final rows = await WebStorage.load('daily_completions');
      final index = rows.indexWhere((r) => r['user_id'] == userId && r['date'] == date);
      List<String> actions = [];
      if (index != -1) {
        actions = List<String>.from(jsonDecode(rows[index]['actions_completed_json'] as String));
        if (!actions.contains(action)) {
          actions.add(action);
          await WebStorage.update('daily_completions', rows[index]['id'] as int, {
            'actions_completed_json': jsonEncode(actions)
          });
        }
      } else {
        actions = [action];
        await WebStorage.insert('daily_completions', {
          'user_id': userId,
          'date': date,
          'actions_completed_json': jsonEncode(actions),
          'streak_maintained': 0,
        });
      }
      return;
    }
    final db = await database;
    if (db == null) return;
    final rows = await db.query('daily_completions', where: 'user_id = ? AND date = ?', whereArgs: [userId, date]);
    if (rows.isNotEmpty) {
      final List<String> actions = List<String>.from(jsonDecode(rows.first['actions_completed_json'] as String));
      if (!actions.contains(action)) {
        actions.add(action);
        await db.update('daily_completions', {'actions_completed_json': jsonEncode(actions)}, where: 'id = ?', whereArgs: [rows.first['id']]);
      }
    } else {
      await db.insert('daily_completions', {
        'user_id': userId,
        'date': date,
        'actions_completed_json': jsonEncode([action]),
        'streak_maintained': 0,
      });
    }
  }

  // ── STATS ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getWeekStats(int userId) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final sevenDaysAgoStr = sevenDaysAgo.toIso8601String().split('T')[0];

    if (kIsWeb) {
      final meals = await WebStorage.load('meal_logs');
      final mood = await WebStorage.load('mood_logs');
      final workouts = await WebStorage.load('workout_logs');
      
      final filteredMeals = meals.where((r) => r['user_id'] == userId && (r['logged_at'] as String).compareTo(sevenDaysAgoStr) >= 0).toList();
      final filteredMood = mood.where((r) => r['user_id'] == userId && (r['logged_at'] as String).compareTo(sevenDaysAgoStr) >= 0).toList();
      final filteredWorkouts = workouts.where((r) => r['user_id'] == userId && (r['logged_at'] as String).compareTo(sevenDaysAgoStr) >= 0).toList();

      final totalCal = filteredMeals.fold(0.0, (sum, r) => sum + (r['calories'] as num).toDouble());
      final avgMood = filteredMood.isEmpty ? 0.0 : filteredMood.fold(0.0, (sum, r) => sum + (r['mood_score'] as int)) / filteredMood.length;

      return {
        'avg_kcal': totalCal / 7,
        'total_water': 0,
        'avg_mood': avgMood,
        'days_hit': 0,
        'workout_count': filteredWorkouts.length,
      };
    }
    
    final db = await database;
    if (db == null) return {'avg_kcal': 0, 'avg_mood': 0, 'days_hit': 0, 'workout_count': 0};
    final calRes = await db.rawQuery("SELECT SUM(calories) as total FROM meal_logs WHERE user_id = ? AND date(logged_at) >= ?", [userId, sevenDaysAgoStr]);
    final moodRes = await db.rawQuery("SELECT AVG(mood_score) as avg_mood FROM mood_logs WHERE user_id = ? AND date(logged_at) >= ?", [userId, sevenDaysAgoStr]);
    final workoutRes = await db.rawQuery("SELECT COUNT(*) as cnt FROM workout_logs WHERE user_id = ? AND date(logged_at) >= ?", [userId, sevenDaysAgoStr]);

    return {
      'avg_kcal': ((calRes.first['total'] as num?) ?? 0) / 7,
      'avg_mood': (moodRes.first['avg_mood'] as num?) ?? 0,
      'days_hit': 0,
      'workout_count': workoutRes.first['cnt'] ?? 0,
    };
  }
}
