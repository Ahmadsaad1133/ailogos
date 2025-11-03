import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/generation_record.dart';
import '../widgets/animated_glow_button.dart';
import '../widgets/branded_logo.dart';
import '../widgets/generated_image_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/prompt_input.dart';
import 'history_screen.dart';
import 'result_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate(AppState state) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a prompt to begin.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    final record = await state.generateImage(prompt);
    if (!mounted) return;
    if (record != null) {
      _promptController.clear();
      await Navigator.of(context).pushNamed(
        ResultScreen.routeName,
        arguments: record,
      );
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final lastRecord = appState.history.isEmpty ? null : appState.history.first;

    return Scaffold(
      backgroundColor: Colors
          .transparent, // 🔹 Transparent scaffold as requested
      body: GradientBackground(
        asset: 'lib/assets/backgrounds/obsdiv_home.svg',
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(SettingsScreen.routeName),
                ),
                title: const BrandedLogo(
                  size: 56,
                  variant: LogoVariant.icon,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_outlined),
                    onPressed: () => Navigator.of(context)
                        .pushNamed(SettingsScreen.routeName),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    onPressed: () => Navigator.of(context)
                        .pushNamed(HistoryScreen.routeName),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 32),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summon visuals with a single prompt.',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'OBSDIV’s generative core crafts imagery from your words in seconds.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      PromptInput(
                        controller: _promptController,
                        onSubmitted: () => _handleGenerate(appState),
                      ),
                      const SizedBox(height: 24),
                      AnimatedGlowButton(
                        label: 'Generate with OBSDIV',
                        icon: Icons.bolt_rounded,
                        isBusy: appState.isGenerating,
                        onPressed: () => _handleGenerate(appState),
                      ),
                      if (lastRecord != null) ...[
                        const SizedBox(height: 42),
                        Text('Latest creation',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 380,
                          child: GeneratedImagePreview(
                            record: lastRecord,
                            onOpen: () => _openResult(lastRecord),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openResult(GenerationRecord record) async {
    await Navigator.of(context).pushNamed(
      ResultScreen.routeName,
      arguments: record,
    );
  }
}

class GeneratedImagePreview extends StatelessWidget {
  const GeneratedImagePreview({
    super.key,
    required this.record,
    required this.onOpen,
  });

  final GenerationRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GeneratedImageCard(
      imageBytes: record.imageBytes,
      prompt: record.prompt,
      heroTag: record.id,
      onTap: onOpen,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tap to view actions',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Icon(Icons.open_in_full_rounded, size: 18),
        ],
      ),
    );
  }
}
