import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';
import 'settings_screen.dart';
import 'tabs/image_tab.dart';
import 'tabs/sleep_tab.dart';
import 'tabs/story_tab.dart';
import 'tabs/voice_tab.dart';
import 'tabs/writing_tab.dart';
import 'persona_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GradientBackground(
          asset: 'lib/assets/backgrounds/obsdiv_home.svg',
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: () => Navigator.of(context)
                            .pushNamed(SettingsScreen.routeName),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey ${appState.displayName},',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore all OBSDIV creative labs.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Persona chat',
                        icon: const Icon(Icons.bubble_chart_rounded),
                        onPressed: () => Navigator.of(context)
                            .pushNamed(PersonaChatScreen.routeName),
                      ),
                      const SizedBox(width: 8),
                      const BrandedLogo(
                        size: 40,
                        variant: LogoVariant.watermark,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TabBar(
                      labelColor: theme.colorScheme.onSurface,
                      indicatorColor: theme.colorScheme.primary,
                      unselectedLabelColor:
                      theme.colorScheme.onSurface.withOpacity(0.6),
                      tabs: const [
                        Tab(icon: Icon(Icons.auto_stories_rounded), text: 'Story'),
                        Tab(icon: Icon(Icons.edit_note_rounded), text: 'Writing'),
                        Tab(icon: Icon(Icons.image_outlined), text: 'Images'),
                        Tab(icon: Icon(Icons.graphic_eq_rounded), text: 'Voice'),
                        Tab(icon: Icon(Icons.nightlight_round), text: 'Sleep'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Expanded(
                  child: TabBarView(
                    children: [
                      StoryTab(),
                      WritingTab(),
                      ImageTab(),
                      VoiceTab(),
                      SleepTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
