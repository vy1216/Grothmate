import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'constants/theme.dart';
import 'database/app_database.dart';
import 'services/app_state.dart';
import 'services/groq_service.dart';
import 'screens/onboarding/onboarding_screens.dart';
import 'screens/main/home_screen.dart';
import 'screens/main/track_screen.dart';
import 'screens/main/ai_chat_screen.dart';
import 'screens/main/progress_screen.dart';
import 'screens/modals/log_meal_screen.dart';
import 'screens/modals/log_workout_screen.dart';
import 'screens/modals/mood_log_screen.dart';
import 'screens/modals/worry_timer_screen.dart';
import 'screens/modals/weekly_review_screen.dart';
import 'screens/modals/weight_log_screen.dart';
import 'screens/modals/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  // Initialize database factory based on platform
  if (!kIsWeb) {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: needs ffi init
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      // Android & iOS: native sqflite works without any init
    } catch (_) {
      // Fallback silently — web or unknown platform
    }
  }

  // Initialize database (creates all tables)
  await AppDatabase.instance.database;

  // Load saved Groq API key
  final prefs = await SharedPreferences.getInstance();
  String savedKey = prefs.getString('groq_api_key') ?? '';
  
  // Force reload from .env if the key looks like a placeholder or is empty
  if (savedKey.isEmpty || savedKey == 'your_groq_api_key_here' || savedKey.startsWith('gsk_omN3')) {
    // 1. Check --dart-define (for Vercel environment variables)
    savedKey = const String.fromEnvironment('GROQ_API_KEY');
    
    // 2. If not in dart-define, check .env file
    if (savedKey.isEmpty) {
      savedKey = dotenv.env['GROQ_API_KEY']?.trim() ?? '';
    }

    if (savedKey.isNotEmpty) {
      await prefs.setString('groq_api_key', savedKey);
    }
  }
  
  if (savedKey.isNotEmpty && savedKey != 'your_groq_api_key_here') {
    debugPrint("Setting Groq API Key: ${savedKey.substring(0, 8)}...");
    GroqService.setApiKey(savedKey);
  } else {
    debugPrint("Groq API Key is EMPTY or DEFAULT!");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..loadAll(),
      child: const GrowthMateApp(),
    ),
  );
}

class GrowthMateApp extends StatelessWidget {
  const GrowthMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowthMate',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/':                  (ctx) => const SplashRouter(),
        '/welcome':           (ctx) => const WelcomeScreen(),
        '/onboard/stats':     (ctx) => const StatsScreen(),
        '/onboard/goals':     (ctx) => const GoalsScreen(),
        '/onboard/routine':   (ctx) => const RoutineScreen(),
        '/onboard/diet':      (ctx) => const DietScreen(),
        '/onboard/social':    (ctx) => const SocialScreen(),
        '/onboard/notifications': (ctx) => const NotificationsScreen(),
        '/onboard/complete':  (ctx) => const SetupCompleteScreen(),
        '/home':              (ctx) => const MainShell(),
        '/log-meal':          (ctx) => const LogMealScreen(),
        '/log-workout':       (ctx) => const LogWorkoutScreen(),
        '/mood-log':          (ctx) => const MoodLogScreen(),
        '/worry-timer':       (ctx) => const WorryTimerScreen(),
        '/weekly-review':     (ctx) => const WeeklyReviewScreen(),
        '/weight-log':        (ctx) => const WeightLogScreen(),
        '/settings':          (ctx) => const SettingsScreen(),
      },
    );
  }
}

// ── SPLASH ROUTER ─────────────────────────────────────────
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final user = await AppDatabase.instance.getUser();
    if (!mounted) return;
    if (user != null && user.onboardingComplete == 1) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌱', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'GrowthMate',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'your personal growth companion',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── MAIN SHELL (Bottom Nav) ────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    TrackScreen(),
    AIChatScreen(),
    ProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),
              label: 'Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}
