import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_state.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/history_service.dart';
import 'services/image_generation_service.dart';
import 'services/preferences_service.dart';
import 'themes/app_theme.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnvironment();
  final preferences = await SharedPreferences.getInstance();
  final appState = AppState(
    imageService: ImageGenerationService(),
    historyService: HistoryService(preferences),
    preferencesService: PreferencesService(preferences),
  );
  await appState.initialise();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const PoweredByObsdivApp(),
    ),
  );
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow running without a bundled .env file. Environment variables can
    // still be provided through --dart-define or platform secure storage.
  }
}

class PoweredByObsdivApp extends StatelessWidget {
  const PoweredByObsdivApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = AppTheme.dark(accent: appState.accentColor);

    return MaterialApp(
      title: 'Powered by OBSDIV',
      theme: theme,
      debugShowCheckedModeBanner: false,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        ResultScreen.routeName: (_) => const ResultScreen(),
        HistoryScreen.routeName: (_) => const HistoryScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
      initialRoute: SplashScreen.routeName,
    );
  }
}
