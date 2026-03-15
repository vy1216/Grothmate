# GrowthMate — Flutter App 🌱

A complete Flutter health & wellness companion app with AI chat (Groq), calorie tracking, mood logging, exercise tracking, and more.

---

## Quick Setup (5 steps)

### Step 1 — Install Flutter
If you don't have Flutter installed:
```bash
# Download Flutter SDK from https://flutter.dev/docs/get-started/install
# Then add to PATH and run:
flutter doctor
```
Make sure you see no critical errors (Android toolchain is required for Android).

### Step 2 — Get the project
Extract the zip into a folder, then open terminal in that folder.

### Step 3 — Add fonts
The app uses **Syne** and **DM Sans** fonts. Download them free from Google Fonts:
- https://fonts.google.com/specimen/Syne → Download → put `Syne-Bold.ttf` and `Syne-ExtraBold.ttf` in `assets/fonts/`
- https://fonts.google.com/specimen/DM+Sans → Download → put `DMSans-Light.ttf`, `DMSans-Regular.ttf`, `DMSans-Medium.ttf` in `assets/fonts/`

Create the assets/fonts folder:
```bash
mkdir -p assets/fonts
```

### Step 4 — Create .env file
Create a `.env` file in the project root:
```
GROQ_API_KEY=your_groq_api_key_here
```
Get your **free** Groq API key at: https://console.groq.com

> Note: You can also add the API key directly in the app Settings screen after running it. The .env key is loaded on startup. You can skip this step and add the key from within the app.

### Step 5 — Install dependencies and run
```bash
# Install all packages
flutter pub get

# Run on Android (with emulator or device connected)
flutter run

# Run on iOS (Mac only, with simulator or device)
flutter run

# Build release APK for Android
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

---

## Project Structure

```
growthmate_flutter/
├── lib/
│   ├── main.dart                    # App entry, routing, shell
│   ├── constants/
│   │   ├── theme.dart               # Forest Growth dark theme colors
│   │   └── food_database.dart       # 130+ Indian food items + exercises
│   ├── models/
│   │   └── models.dart              # All data models (User, MealLog, etc.)
│   ├── database/
│   │   └── app_database.dart        # SQLite layer — all queries
│   ├── services/
│   │   ├── groq_service.dart        # Groq AI API integration
│   │   └── app_state.dart           # Global state (ChangeNotifier)
│   ├── utils/
│   │   └── calc_utils.dart          # BMI, calorie calc, formatting
│   ├── widgets/
│   │   └── common_widgets.dart      # AppCard, buttons, labels, etc.
│   └── screens/
│       ├── onboarding/
│       │   └── onboarding_screens.dart  # All 7 onboarding screens
│       ├── main/
│       │   ├── home_screen.dart         # Dashboard with calorie ring
│       │   ├── track_screen.dart        # Meals / Exercise / Water tabs
│       │   ├── ai_chat_screen.dart      # Groq-powered AI companion
│       │   └── progress_screen.dart     # Charts, weight, vault, supplements
│       └── modals/
│           ├── log_meal_screen.dart     # Food search + detail sheet
│           ├── all_modals.dart          # Workout, Mood, Timer, Review, Weight, Settings
│           └── *.dart                   # Individual re-exports
├── assets/
│   └── fonts/                       # Syne + DM Sans (you add these)
├── android/                         # Android config
├── .env                             # Your Groq API key
└── pubspec.yaml                     # Dependencies
```

---

## Key Features

| Feature | Description |
|---|---|
| Onboarding | 7 steps — dynamically calculates calorie target from your stats |
| Calorie Ring | Custom painter SVG ring showing kcal + protein progress |
| Food Search | SQLite full-text search across 130+ Indian foods |
| AI Companion | Groq llama3-70b with your full daily context in every message |
| Mood Tracker | 5-state mood + energy logging |
| Water Tracker | Glass-by-glass tracking with animated grid |
| Exercise Logger | Category browser + calorie burn calculator |
| Worry Timer | 15-minute brain dump with vault storage |
| Progress Charts | Weight trend, calorie consistency bar chart |
| Weekly Review | AI-generated personal letter every Sunday |
| Streak System | 7 different actions count toward daily streak |
| Settings | API key management, profile view, data reset |

---

## AI Features (Groq)

All AI features require a Groq API key (free at console.groq.com).

**Chat:** Every message sends your full context to Groq:
- Today's calories, macros, meals logged
- Current mood and energy level
- Water intake, streak, week averages
- Your goal, diet type, weight

**Weekly Review:** Generates a personal 120-150 word narrative letter about your week every Sunday.

**Fallback:** If no API key is set, smart rule-based responses still work based on your data.

---

## Dependencies Used

```yaml
sqflite: ^2.3.2          # Local SQLite database
shared_preferences: ^2.2.3 # Key-value storage (API key, prefs)
http: ^1.2.1              # Groq API calls
google_fonts: ^6.2.1      # Font loading fallback
provider: ^6.1.2          # State management
flutter_local_notifications: ^17.1.2 # Push notifications
image_picker: ^1.0.7      # Camera / gallery access
intl: ^0.19.0             # Date formatting
uuid: ^4.4.0              # Unique IDs
flutter_dotenv: ^5.1.0    # .env loading
```

---

## Common Issues

**"Fonts not found" error:**
Make sure you added the font files to `assets/fonts/` with the exact names listed in `pubspec.yaml`.

**"No module named sqflite" on iOS:**
Run `cd ios && pod install` then try again.

**API key not working:**
- Check you copied the full key starting with `gsk_`
- You can update it anytime in the app's Settings screen
- Free tier allows 30 requests/minute

**Build fails on Android:**
Make sure your Android SDK is installed and `flutter doctor` shows no errors for Android toolchain.

---

## Adding More Foods

Edit `lib/constants/food_database.dart` and add entries to the `kFoodDatabase` list following the same `FoodItem` pattern.

---

Built with Flutter · Powered by Groq llama3-70b · Forest Growth dark theme
