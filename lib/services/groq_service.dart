import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';

class GroqService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  static String _apiKey = '';
  static void setApiKey(String key) => _apiKey = key;
  static String get apiKey => _apiKey;

  static int _calculateAge(String dob) {
    try {
      final birth = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) age--;
      return age;
    } catch (_) { return 21; }
  }

  static Future<String> buildSystemPrompt(int userId) async {
    try {
      final db = AppDatabase.instance;
      final user = await db.getUser();
      if (user == null) return 'You are a helpful health companion.';
      final todayMeals = await db.getTodayMeals(userId);
      final latestMood = await db.getTodayMood(userId);
      final waterToday = await db.getTodayWater(userId);
      final streak = await db.getCurrentStreak(userId);
      final weekStats = await db.getWeekStats(userId);
      final totalCal = todayMeals.fold<double>(0, (s, m) => s + m.calories);
      final totalProtein = todayMeals.fold<double>(0, (s, m) => s + m.proteinG);
      final totalSugar = todayMeals.fold<double>(0, (s, m) => s + m.sugarG);
      final age = _calculateAge(user.dob);
      final pct = ((totalCal / user.dailyKcalTarget) * 100).round();
      final mealSummary = todayMeals.isEmpty ? 'nothing logged yet'
          : todayMeals.map((m) => '${m.foodName} (${m.calories.round()} kcal)').join(', ');

      return '''You are ${user.aiCompanionName}, a warm and direct personal health companion.

USER PROFILE:
- Name: ${user.name}, Age: $age, Weight: ${user.weightKg}kg, Height: ${user.heightCm}cm
- BMI: ${user.bmi}, Goal: ${user.goalType.replaceAll('_', ' ')} to ${user.goalWeightKg}kg
- Diet: ${user.dietType}, Schedule: ${user.scheduleType}
- Energy baseline: ${user.energyBaseline}, Introvert score: ${user.introvertScore}/10

TODAY (${DateTime.now().toLocal()}):
- Calories: ${totalCal.round()} / ${user.dailyKcalTarget.round()} kcal ($pct% of goal)
- Meals logged: $mealSummary
- Protein: ${totalProtein.round()}g / ${user.proteinTargetG.round()}g target
- Sugar: ${totalSugar.round()}g
- Water: $waterToday / ${user.waterTargetGlasses} glasses
- Mood: ${latestMood?.moodLabel ?? 'not logged'}, Energy: ${latestMood?.energyScore ?? '?'}/5
- Streak: $streak days

THIS WEEK:
- Avg calories: ${weekStats['avg_kcal']} kcal/day
- Days target hit: ${weekStats['days_hit']}/7
- Avg mood: ${weekStats['avg_mood']}/5
- Workouts: ${weekStats['workout_count']}

PERSONALITY RULES:
- Be specific — always reference their actual numbers, never speak generically
- Keep responses under 100 words unless explicitly asked for detail
- If they express low mood — acknowledge it first, then connect to their data
- Never lecture. One suggestion at a time
- If they mention overthinking or being stuck — give ONE immediate physical micro-action
- Tone: caring, direct, like a knowledgeable friend watching their week
- You are NOT a doctor — never diagnose or prescribe''';
    } catch (e) {
      return 'You are a helpful health and wellness companion. Be warm, specific, and supportive.';
    }
  }

  static bool _detectThinkingMode(String message) {
    final patterns = ['keep thinking', "can't stop", 'lying in bed', 'everything feels',
      "don't know what to do", 'pointless', 'stuck in my head', "can't focus",
      'overthinking', 'anxious', 'depressed', 'feel low', 'feeling low', 'lazy',
      'no motivation', 'tired of'];
    final lower = message.toLowerCase();
    return patterns.any((p) => lower.contains(p));
  }

  static Future<String> sendMessage(int userId, String userMessage) async {
    if (_apiKey.isEmpty || _apiKey == 'your_groq_api_key_here') {
      return _fallbackResponse(userId, userMessage);
    }
    try {
      final systemPrompt = await buildSystemPrompt(userId);
      final historyRaw = await AppDatabase.instance.getConversationHistory(userId, limit: 10);
      final history = historyRaw.map((h) => {'role': h['role'], 'content': h['content']}).toList();

      String finalSystem = systemPrompt;
      if (_detectThinkingMode(userMessage)) {
        finalSystem += '\n\nIMPORTANT: User is showing overthinking/stress signs. First acknowledge in one warm sentence. Then give exactly ONE simple physical action they can do in 60 seconds. End by asking if they did it.';
      }

      final body = jsonEncode({
        'model': _model,
        'max_tokens': 400,
        'temperature': 0.7,
        'messages': [
          {'role': 'system', 'content': finalSystem},
          ...history,
          {'role': 'user', 'content': userMessage},
        ],
      });

      print('GROQ REQUEST BODY: $body');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_apiKey.trim()}',
        },
        body: body,
      );

      print('GROQ RESPONSE STATUS: ${response.statusCode}');
      print('GROQ RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        await AppDatabase.instance.saveMessage(userId, 'user', userMessage);
        await AppDatabase.instance.saveMessage(userId, 'assistant', reply);
        return reply;
      } else if (response.statusCode == 401) {
        return 'Invalid API key. Please update your Groq API key in Settings.';
      } else {
        return _fallbackResponse(userId, userMessage);
      }
    } catch (e) {
      return _fallbackResponse(userId, userMessage);
    }
  }

  static Future<String> _fallbackResponse(int userId, String msg) async {
    final user = await AppDatabase.instance.getUser();
    final meals = await AppDatabase.instance.getTodayMeals(userId);
    final totalCal = meals.fold<double>(0, (s, m) => s + m.calories).round();
    final target = user?.dailyKcalTarget.round() ?? 2000;
    final remain = target - totalCal;
    final lower = msg.toLowerCase();

    if (lower.contains('eat') || lower.contains('food') || lower.contains('meal')) {
      return remain > 0
          ? 'You still need $remain kcal today. Try adding dal with 2 rotis and a spoon of ghee — that gets you ~600 kcal easily.'
          : "You've hit your calorie target today! Great work. Focus on protein for remaining meals.";
    }
    if (lower.contains('lazy') || lower.contains('low') || lower.contains('tired')) {
      return "I hear you. Low energy often connects to not eating enough — you've had $totalCal kcal today. Stand up right now, drink a full glass of water, and have a small snack. That one action can shift your energy.";
    }
    if (lower.contains('think') || lower.contains('overthink') || lower.contains('stuck')) {
      return "Your brain is loud right now. Here's one thing: stand up, walk to your kitchen and back, drink a glass of water. Just that. Come back and tell me you did it.";
    }
    return 'Add your Groq API key in Settings to get personalized AI responses. For now: you\'re at $totalCal/$target kcal today. Keep logging!';
  }

  static Future<String> generateWeeklyReview(int userId) async {
    if (_apiKey.isEmpty) return 'Add your Groq API key in Settings to enable weekly reviews.';
    try {
      final user = await AppDatabase.instance.getUser();
      final weekStats = await AppDatabase.instance.getWeekStats(userId);
      final streak = await AppDatabase.instance.getCurrentStreak(userId);
      final weights = await AppDatabase.instance.getWeightHistory(userId);
      final latestWeight = weights.isNotEmpty ? weights.last.weightKg : (user?.weightKg ?? 60);
      final startWeight = weights.isNotEmpty ? weights.first.weightKg : latestWeight;

      final prompt = '''Write a personal weekly review letter for ${user?.name ?? 'the user'}.

Their data this week:
- Average daily calories: ${weekStats['avg_kcal']} / ${user?.dailyKcalTarget.round()} kcal target
- Days they hit their target: ${weekStats['days_hit']}/7
- Current weight: ${latestWeight}kg (started at ${startWeight}kg, goal: ${user?.goalWeightKg}kg)
- Workouts completed: ${weekStats['workout_count']}
- Average mood: ${weekStats['avg_mood']}/5
- Current streak: $streak days

Write 120-150 words. Address them by first name. Reference 3 specific data points. Identify 1 clear pattern. Give exactly 1 goal for next week. NO bullet points — flowing paragraphs only. Tone: warm, honest, like a caring friend who watched their whole week.''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({'model': _model, 'max_tokens': 300, 'temperature': 0.75,
          'messages': [{'role': 'user', 'content': prompt}]}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      return 'Could not generate review right now. Try again later.';
    } catch (e) {
      return 'Could not generate review. Check your internet connection.';
    }
  }
}
