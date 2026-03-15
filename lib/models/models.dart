class UserModel {
  final int? id;
  final String name;
  final String dob;
  final String gender;
  final double weightKg;
  final double heightCm;
  final double bmi;
  final double goalWeightKg;
  final String goalType;
  final String activityLevel;
  final String dietType;
  final String favoriteFoods;
  final String wakeTime;
  final String sleepTime;
  final String scheduleType;
  final bool skipsMeals;
  final int introvertScore;
  final String energyBaseline;
  final double dailyKcalTarget;
  final double proteinTargetG;
  final int waterTargetGlasses;
  final String pantryItemsJson;
  final String aiCompanionName;
  final String notificationsJson;
  final int bestStreak;
  final int onboardingComplete;

  UserModel({
    this.id,
    required this.name,
    required this.dob,
    this.gender = 'male',
    required this.weightKg,
    required this.heightCm,
    required this.bmi,
    required this.goalWeightKg,
    this.goalType = 'gain_weight',
    this.activityLevel = 'sedentary',
    this.dietType = 'veg_eggs',
    this.favoriteFoods = '',
    this.wakeTime = '07:00',
    this.sleepTime = '23:00',
    this.scheduleType = 'college',
    this.skipsMeals = false,
    this.introvertScore = 5,
    this.energyBaseline = 'sometimes',
    required this.dailyKcalTarget,
    required this.proteinTargetG,
    this.waterTargetGlasses = 8,
    this.pantryItemsJson = '[]',
    this.aiCompanionName = 'GrowthMate AI',
    this.notificationsJson = '{}',
    this.bestStreak = 0,
    this.onboardingComplete = 0,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name, 'dob': dob, 'gender': gender,
    'weight_kg': weightKg, 'height_cm': heightCm, 'bmi': bmi,
    'goal_weight_kg': goalWeightKg, 'goal_type': goalType,
    'activity_level': activityLevel, 'diet_type': dietType,
    'favorite_foods': favoriteFoods, 'wake_time': wakeTime,
    'sleep_time': sleepTime, 'schedule_type': scheduleType,
    'skips_meals': skipsMeals ? 1 : 0, 'introvert_score': introvertScore,
    'energy_baseline': energyBaseline, 'daily_kcal_target': dailyKcalTarget,
    'protein_target_g': proteinTargetG, 'water_target_glasses': waterTargetGlasses,
    'pantry_items_json': pantryItemsJson, 'ai_companion_name': aiCompanionName,
    'notifications_json': notificationsJson, 'best_streak': bestStreak,
    'onboarding_complete': onboardingComplete,
  };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id'], name: m['name'], dob: m['dob'] ?? '',
    gender: m['gender'] ?? 'male', weightKg: (m['weight_kg'] ?? 60).toDouble(),
    heightCm: (m['height_cm'] ?? 170).toDouble(), bmi: (m['bmi'] ?? 20).toDouble(),
    goalWeightKg: (m['goal_weight_kg'] ?? 65).toDouble(), goalType: m['goal_type'] ?? 'gain_weight',
    activityLevel: m['activity_level'] ?? 'sedentary', dietType: m['diet_type'] ?? 'veg_eggs',
    favoriteFoods: m['favorite_foods'] ?? '', wakeTime: m['wake_time'] ?? '07:00',
    sleepTime: m['sleep_time'] ?? '23:00', scheduleType: m['schedule_type'] ?? 'college',
    skipsMeals: (m['skips_meals'] ?? 0) == 1, introvertScore: m['introvert_score'] ?? 5,
    energyBaseline: m['energy_baseline'] ?? 'sometimes',
    dailyKcalTarget: (m['daily_kcal_target'] ?? 2000).toDouble(),
    proteinTargetG: (m['protein_target_g'] ?? 80).toDouble(),
    waterTargetGlasses: m['water_target_glasses'] ?? 8,
    pantryItemsJson: m['pantry_items_json'] ?? '[]',
    aiCompanionName: m['ai_companion_name'] ?? 'GrowthMate AI',
    notificationsJson: m['notifications_json'] ?? '{}',
    bestStreak: m['best_streak'] ?? 0,
    onboardingComplete: m['onboarding_complete'] ?? 0,
  );

  UserModel copyWith({
    double? weightKg, double? bmi, int? bestStreak, int? onboardingComplete,
    String? aiCompanionName,
  }) => UserModel(
    id: id, name: name, dob: dob, gender: gender,
    weightKg: weightKg ?? this.weightKg, heightCm: heightCm,
    bmi: bmi ?? this.bmi, goalWeightKg: goalWeightKg, goalType: goalType,
    activityLevel: activityLevel, dietType: dietType, favoriteFoods: favoriteFoods,
    wakeTime: wakeTime, sleepTime: sleepTime, scheduleType: scheduleType,
    skipsMeals: skipsMeals, introvertScore: introvertScore, energyBaseline: energyBaseline,
    dailyKcalTarget: dailyKcalTarget, proteinTargetG: proteinTargetG,
    waterTargetGlasses: waterTargetGlasses, pantryItemsJson: pantryItemsJson,
    aiCompanionName: aiCompanionName ?? this.aiCompanionName,
    notificationsJson: notificationsJson,
    bestStreak: bestStreak ?? this.bestStreak,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
}

class MealLog {
  final int? id;
  final int userId;
  final String mealSlot;
  final String foodName;
  final int? foodId;
  final double portionG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double sugarG;
  final double fiberG;
  final bool isPhotoLog;
  final bool estimated;
  final String loggedAt;

  MealLog({
    this.id, required this.userId, required this.mealSlot, required this.foodName,
    this.foodId, required this.portionG, required this.calories, required this.proteinG,
    required this.carbsG, required this.fatG, required this.sugarG, this.fiberG = 0,
    this.isPhotoLog = false, this.estimated = false, required this.loggedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'user_id': userId, 'meal_slot': mealSlot,
    'food_name': foodName, 'food_id': foodId, 'portion_g': portionG,
    'calories': calories, 'protein_g': proteinG, 'carbs_g': carbsG,
    'fat_g': fatG, 'sugar_g': sugarG, 'fiber_g': fiberG,
    'is_photo_log': isPhotoLog ? 1 : 0, 'estimated': estimated ? 1 : 0,
    'logged_at': loggedAt,
  };

  factory MealLog.fromMap(Map<String, dynamic> m) => MealLog(
    id: m['id'], userId: m['user_id'], mealSlot: m['meal_slot'],
    foodName: m['food_name'], foodId: m['food_id'],
    portionG: (m['portion_g'] ?? 100).toDouble(),
    calories: (m['calories'] ?? 0).toDouble(),
    proteinG: (m['protein_g'] ?? 0).toDouble(),
    carbsG: (m['carbs_g'] ?? 0).toDouble(),
    fatG: (m['fat_g'] ?? 0).toDouble(),
    sugarG: (m['sugar_g'] ?? 0).toDouble(),
    fiberG: (m['fiber_g'] ?? 0).toDouble(),
    isPhotoLog: (m['is_photo_log'] ?? 0) == 1,
    estimated: (m['estimated'] ?? 0) == 1,
    loggedAt: m['logged_at'] ?? DateTime.now().toIso8601String(),
  );
}

class WorkoutLog {
  final int? id;
  final int userId;
  final String exerciseName;
  final String category;
  final int sets;
  final int reps;
  final int durationSec;
  final double caloriesBurned;
  final int energyAfter;
  final String loggedAt;

  WorkoutLog({
    this.id, required this.userId, required this.exerciseName, required this.category,
    this.sets = 0, this.reps = 0, this.durationSec = 0, this.caloriesBurned = 0,
    this.energyAfter = 2, required this.loggedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'user_id': userId, 'exercise_name': exerciseName,
    'category': category, 'sets': sets, 'reps': reps, 'duration_sec': durationSec,
    'calories_burned': caloriesBurned, 'energy_after': energyAfter, 'logged_at': loggedAt,
  };

  factory WorkoutLog.fromMap(Map<String, dynamic> m) => WorkoutLog(
    id: m['id'], userId: m['user_id'], exerciseName: m['exercise_name'],
    category: m['category'], sets: m['sets'] ?? 0, reps: m['reps'] ?? 0,
    durationSec: m['duration_sec'] ?? 0,
    caloriesBurned: (m['calories_burned'] ?? 0).toDouble(),
    energyAfter: m['energy_after'] ?? 2,
    loggedAt: m['logged_at'] ?? DateTime.now().toIso8601String(),
  );
}

class MoodLog {
  final int? id;
  final int userId;
  final int moodScore;
  final String moodLabel;
  final int energyScore;
  final String note;
  final String source;
  final String loggedAt;

  MoodLog({
    this.id, required this.userId, required this.moodScore, required this.moodLabel,
    this.energyScore = 3, this.note = '', this.source = 'manual', required this.loggedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'user_id': userId, 'mood_score': moodScore,
    'mood_label': moodLabel, 'energy_score': energyScore, 'note': note,
    'source': source, 'logged_at': loggedAt,
  };

  factory MoodLog.fromMap(Map<String, dynamic> m) => MoodLog(
    id: m['id'], userId: m['user_id'], moodScore: m['mood_score'] ?? 3,
    moodLabel: m['mood_label'] ?? 'Okay', energyScore: m['energy_score'] ?? 3,
    note: m['note'] ?? '', source: m['source'] ?? 'manual',
    loggedAt: m['logged_at'] ?? DateTime.now().toIso8601String(),
  );
}

class WeightEntry {
  final int? id;
  final int userId;
  final double weightKg;
  final String loggedAt;

  WeightEntry({this.id, required this.userId, required this.weightKg, required this.loggedAt});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'user_id': userId,
    'weight_kg': weightKg, 'logged_at': loggedAt,
  };

  factory WeightEntry.fromMap(Map<String, dynamic> m) => WeightEntry(
    id: m['id'], userId: m['user_id'],
    weightKg: (m['weight_kg'] ?? 60).toDouble(),
    loggedAt: m['logged_at'] ?? DateTime.now().toIso8601String(),
  );
}

class FoodItem {
  final int id;
  final String name;
  final String category;
  final String aliases;
  final double servingSizeG;
  final double calPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double sugarPer100g;
  final double fiberPer100g;

  const FoodItem({
    required this.id, required this.name, required this.category,
    this.aliases = '', required this.servingSizeG, required this.calPer100g,
    required this.proteinPer100g, required this.carbsPer100g, required this.fatPer100g,
    required this.sugarPer100g, this.fiberPer100g = 0,
  });

  double get caloriesPerServing => calPer100g * servingSizeG / 100;

  MacroResult macrosForPortion(double portionG) {
    final r = portionG / 100;
    return MacroResult(
      calories: calPer100g * r,
      protein: proteinPer100g * r,
      carbs: carbsPer100g * r,
      fat: fatPer100g * r,
      sugar: sugarPer100g * r,
      fiber: fiberPer100g * r,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'category': category, 'aliases': aliases,
    'serving_size_g': servingSizeG, 'cal_per_100g': calPer100g,
    'protein_per_100g': proteinPer100g, 'carbs_per_100g': carbsPer100g,
    'fat_per_100g': fatPer100g, 'sugar_per_100g': sugarPer100g,
    'fiber_per_100g': fiberPer100g,
  };

  factory FoodItem.fromMap(Map<String, dynamic> m) => FoodItem(
    id: m['id'], name: m['name'], category: m['category'] ?? '',
    aliases: m['aliases'] ?? '', servingSizeG: (m['serving_size_g'] ?? 100).toDouble(),
    calPer100g: (m['cal_per_100g'] ?? 0).toDouble(),
    proteinPer100g: (m['protein_per_100g'] ?? 0).toDouble(),
    carbsPer100g: (m['carbs_per_100g'] ?? 0).toDouble(),
    fatPer100g: (m['fat_per_100g'] ?? 0).toDouble(),
    sugarPer100g: (m['sugar_per_100g'] ?? 0).toDouble(),
    fiberPer100g: (m['fiber_per_100g'] ?? 0).toDouble(),
  );
}

class MacroResult {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double fiber;

  const MacroResult({
    required this.calories, required this.protein, required this.carbs,
    required this.fat, required this.sugar, this.fiber = 0,
  });
}

class VaultEntry {
  final int? id;
  final int userId;
  final String content;
  final int durationSec;
  final bool aiReadable;
  final String createdAt;

  VaultEntry({this.id, required this.userId, required this.content,
    this.durationSec = 0, this.aiReadable = false, required this.createdAt});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'user_id': userId, 'content': content,
    'duration_sec': durationSec, 'ai_readable': aiReadable ? 1 : 0, 'created_at': createdAt,
  };

  factory VaultEntry.fromMap(Map<String, dynamic> m) => VaultEntry(
    id: m['id'], userId: m['user_id'], content: m['content'] ?? '',
    durationSec: m['duration_sec'] ?? 0, aiReadable: (m['ai_readable'] ?? 0) == 1,
    createdAt: m['created_at'] ?? DateTime.now().toIso8601String(),
  );
}
