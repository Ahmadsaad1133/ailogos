import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_state.dart';
import 'models/creative_workspace_state.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_out_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/persona_chat_screen.dart';
import 'services/auth_service.dart';
import 'services/history_service.dart';
import 'services/preferences_service.dart';
import 'services/cloud_media_repository.dart';
import 'services/creative_content_repository.dart';
import 'services/groq_tts_service.dart';
import 'services/image_generation_service.dart';
import 'services/persona_chat_service.dart';
import 'services/story_generation_service.dart';
import 'services/chat_clients/anthropic_chat_client.dart';
import 'services/chat_clients/chat_model_client.dart';
import 'services/chat_clients/groq_chat_client.dart';
import 'services/chat_clients/openai_chat_client.dart';
import 'services/sleep_sound_service.dart';
import 'services/voice_narrator_service.dart';
import 'services/voice_library_store.dart';
import 'services/writing_generation_service.dart';
import 'services/user_data_store.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await dotenv.load(fileName: '.env');

  final groqKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final groqModelId = dotenv.env['GROQ_MODEL_ID'] ?? 'llama-3.1-8b-instant';
  final openAiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final openAiModel = dotenv.env['OPENAI_MODEL_ID'] ?? 'gpt-4o-mini';
  final anthropicKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  final anthropicModel =
      dotenv.env['ANTHROPIC_MODEL_ID'] ?? 'claude-3-5-sonnet-20240620';
  final sharedPreferences = await SharedPreferences.getInstance();
  final authService = AuthService();
  final dataStore = UserDataStore(
    preferences: sharedPreferences,
  );
  await dataStore.initialise();
  final chatClients = <ChatModelClient>[
    GroqChatClient(apiKey: groqKey, model: groqModelId),
    OpenAIChatClient(apiKey: openAiKey, model: openAiModel),
    AnthropicChatClient(apiKey: anthropicKey, model: anthropicModel),
  ];
  final storyService = StoryGenerationService(
    clients: chatClients,
  );

  final imageModel = dotenv.env['OPENAI_IMAGE_MODEL'] ?? 'gpt-image-1';
  final imageService = ImageGenerationService(
    apiKey: openAiKey,
    model: imageModel,
  );

  final mediaRepository = CloudMediaRepository();
  final contentRepository = CreativeContentRepository();
  final voiceLibraryStore = VoiceLibraryStore(preferences: sharedPreferences);
  final voiceService = VoiceNarratorService();
  final sleepService = SleepSoundService(mediaRepository: mediaRepository);
  final writingService = WritingGenerationService(clients: chatClients);
  final personaService = PersonaChatService(clients: chatClients);
  final historyService = HistoryService(dataStore);
  final preferencesService = PreferencesService(dataStore);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<UserDataStore>.value(value: dataStore),
        Provider<CreativeContentRepository>.value(value: contentRepository),
        Provider<CloudMediaRepository>.value(value: mediaRepository),
      ],
      child: ChangeNotifierProvider(
        create: (_) => AppState(
          storyService: storyService,
          historyService: historyService,
          preferencesService: preferencesService,
          dataStore: dataStore,
          authService: authService,
        )..initialise(),
        child: ChangeNotifierProvider(
          create: (_) => CreativeWorkspaceState(
            imageService: imageService,
            voiceService: voiceService,
            sleepSoundService: sleepService,
            writingService: writingService,
            personaChatService: personaService,
            contentRepository: contentRepository,
            mediaRepository: mediaRepository,
            voiceLibraryStore: voiceLibraryStore,
            dataStore: dataStore,
            authService: authService,
          ),
          child: const OBSDIVApp(),
        ),
      ),
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
      home: const _RootNavigator(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case SplashScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
              settings: settings,
            );
          case OnboardingScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const OnboardingScreen(),
              settings: settings,
            );
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
          case PersonaChatScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const PersonaChatScreen(),
              settings: settings,
            );
          case HistoryScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const HistoryScreen(),
              settings: settings,
            );
          case SignInScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const SignInScreen(),
              settings: settings,
            );
          case SignUpScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const SignUpScreen(),
              settings: settings,
            );
          case SignOutScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const SignOutScreen(),
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
class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final authService = context.watch<AuthService>();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (!appState.initialised ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (!appState.onboardingComplete) {
          return const OnboardingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const SignInScreen();
        }

        return const HomeScreen();
      },
    );
  }
}