import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_state.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'services/history_service.dart';
import 'services/preferences_service.dart';
import 'services/story_generation_service.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for Groq credentials
  await dotenv.load(fileName: '.env');

  final sharedPreferences = await SharedPreferences.getInstance();

  final groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final groqModelId = dotenv.env['GROQ_MODEL_ID'] ?? 'llama-3.1-8b-instant';

  final storyService = StoryGenerationService(
    apiKey: groqKey,
    modelId: groqModelId,
  );

  final historyService = HistoryService(sharedPreferences);
  final preferencesService = PreferencesService(sharedPreferences);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        storyService: storyService,
        historyService: historyService,
        preferencesService: preferencesService,
      )..initialise(),
      child: const OBSDIVApp(),
    ),
  );
}

class OBSDIVApp extends StatelessWidget {
  const OBSDIVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Powered by OBSDIV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case HomeScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
              settings: settings,
            );
          case ResultScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const ResultScreen(),
              settings: settings,
            );
          case SettingsScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
              settings: settings,
            );
          case HistoryScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const HistoryScreen(),
              settings: settings,
            );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings: settings,
        );
      },
    );
  }
}
