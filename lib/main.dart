import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:powered_by_obsdiv/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/app_state.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';
import 'services/history_service.dart';
import 'services/preferences_service.dart';
import 'services/story_generation_service.dart';
import 'services/user_data_store.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for Groq credentials
  await dotenv.load(fileName: '.env');

  final groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final groqModelId = dotenv.env['GROQ_MODEL_ID'] ?? 'llama-3.1-8b-instant';
  final openAiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final openAiModel = dotenv.env['OPENAI_MODEL_ID'] ?? 'gpt-4o-mini';
  final anthropicKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  final anthropicModel =
      dotenv.env['ANTHROPIC_MODEL_ID'] ?? 'claude-3-5-sonnet-20240620';
  SupabaseClient? supabaseClient;
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      supabaseClient = Supabase.instance.client;
    } catch (_) {
      supabaseClient = null;
    }
  }
  final supabaseRedirect = dotenv.env['SUPABASE_REDIRECT_URI'];
  final sharedPreferences = await SharedPreferences.getInstance();
  final dataStore = UserDataStore(
    preferences: sharedPreferences,
    client: supabaseClient,
  );
  await dataStore.initialise();
  final authService = AuthService(
    client: supabaseClient,
    redirectUrl: supabaseRedirect,
  );
  final storyService = StoryGenerationService.fromEnvironment(
    groqApiKey: groqKey,
    groqModel: groqModelId,
    openAiKey: openAiKey,
    openAiModel: openAiModel,
    anthropicKey: anthropicKey,
    anthropicModel: anthropicModel,
  );

  final historyService = HistoryService(dataStore);
  final preferencesService = PreferencesService(dataStore);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        storyService: storyService,
        historyService: historyService,
        preferencesService: preferencesService,
        dataStore: dataStore,
        authService: authService,
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
      home: const OnboardingScreen(),
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
