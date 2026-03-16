import 'package:flutter/material.dart';
import '../constants/theme.dart';

class CalcUtils {
  static int calculateAge(String dob) {
    try {
      final birth = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month || (today.month == birth.month && today.day < birth.day)) age--;
      return age;
    } catch (_) { return 21; }
  }

  static double calculateBMI(double weightKg, double heightCm) {
    final h = heightCm / 100;
    return double.parse((weightKg / (h * h)).toStringAsFixed(1));
  }

  static String getBMILabel(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  static Color getBMIColor(double bmi) {
    if (bmi < 18.5) return AppColors.blue;
    if (bmi < 25) return AppColors.accent;
    if (bmi < 30) return AppColors.amber;
    return AppColors.coral;
  }

  static double calculateDailyTarget({
    required double weightKg, required double heightCm,
    required String dob, required String gender,
    required double activityMultiplier, required String goalType,
  }) {
    final age = calculateAge(dob);
    double bmr;
    if (gender == 'female') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }
    final tdee = bmr * activityMultiplier;
    final surpluses = {
      'gain_weight': 500.0, 'lose_weight': -500.0,
      'build_strength': 200.0, 'improve_energy': 200.0
    };
    return (tdee + (surpluses[goalType] ?? 300)).roundToDouble();
  }

  static double calculateCaloriesBurned(double met, double weightKg, int durationSec) {
    final hours = durationSec / 3600;
    return double.parse((met * weightKg * hours).toStringAsFixed(1));
  }

  static String getMealSlot(String wakeTime, String sleepTime) {
    final now = DateTime.now();
    final h = now.hour;
    final wakeH = int.parse(wakeTime.split(':')[0]);
    final sleepH = int.parse(sleepTime.split(':')[0]);
    final waking = sleepH - wakeH;
    final b = wakeH + (waking * 0.1).round();
    final l = wakeH + (waking * 0.35).round();
    final s = wakeH + (waking * 0.55).round();
    final d = wakeH + (waking * 0.75).round();
    if (h < b || h >= sleepH) return 'dinner';
    if (h < l) return 'breakfast';
    if (h < s) return 'lunch';
    if (h < d) return 'snack';
    return 'dinner';
  }

  static String getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static Map<String, dynamic> getMoodConfig(int score) {
    final configs = {
      5: {'label': 'Great', 'emoji': '😄', 'color': AppColors.accent, 'bg': AppColors.primary},
      4: {'label': 'Good', 'emoji': '🙂', 'color': const Color(0xFF1D9E75), 'bg': const Color(0xFF163028)},
      3: {'label': 'Okay', 'emoji': '😐', 'color': AppColors.amber, 'bg': const Color(0xFF2A2010)},
      2: {'label': 'Low', 'emoji': '😔', 'color': AppColors.coral, 'bg': const Color(0xFF2A1A15)},
      1: {'label': 'Anxious', 'emoji': '😰', 'color': AppColors.red, 'bg': const Color(0xFF2A1515)},
    };
    return configs[score] ?? configs[3]!;
  }

  static String formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String slotEmoji(String slot) {
    const m = {'breakfast': '☀️', 'lunch': '🌤️', 'snack': '🌥️', 'dinner': '🌙'};
    return m[slot] ?? '🍽️';
  }

  static String capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
