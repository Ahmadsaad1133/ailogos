import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'models/app_state.dart';
import 'services/image_generation_service.dart';
import 'services/history_service.dart';
import 'services/preferences_service.dart';
import 'services/storage_service.dart';
import 'themes/app_theme.dart';       // لو عندك ملف ثيم، أو إحذف هالسطر واستعمل ThemeData عادي
import 'screens/home_screen.dart';   // حسب عندك

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) تحميل .env
  await dotenv.load(fileName: ".env");

  // 2) قراءة القيم
  final hfKey = dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
  final modelId =
      dotenv.env['HUGGINGFACE_MODEL_ID'] ?? 'stabilityai/stable-diffusion-3.5-large';

  // 3) إنشاء الخدمات
  final imageService = ImageGenerationService(
    apiKey: hfKey,
    modelId: modelId,
  );
  final historyService = HistoryService();
  final preferencesService = PreferencesService();
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
      theme: AppTheme.dark(), // أو ThemeData(...) لو ما عندك AppTheme
      home: const HomeScreen(),
    );
  }
}
