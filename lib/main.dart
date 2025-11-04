import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_state.dart';
import 'services/image_generation_service.dart';
import 'services/history_service.dart';
import 'services/preferences_service.dart';
import 'services/storage_service.dart';
import 'themes/app_theme.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Load .env
  await dotenv.load(fileName: '.env');

  // 2) Read HF key + model id
  final hfKey = dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
  final modelId =
      dotenv.env['HUGGINGFACE_MODEL_ID'] ?? 'stabilityai/stable-diffusion-3.5-large';

  final sharedPreferences = await SharedPreferences.getInstance();

  final imageService = ImageGenerationService(
    apiKey: dotenv.env['HUGGINGFACE_API_KEY'] ?? '',
    modelId: dotenv.env['HUGGINGFACE_MODEL_ID'] ?? '',
  );

  final historyService = HistoryService(sharedPreferences);
  final preferencesService = PreferencesService(sharedPreferences);
  const storageService = StorageService();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        imageService: imageService,
        historyService: historyService,
        preferencesService: preferencesService,
        storageService: storageService,
      ),
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
    );
  }
}
