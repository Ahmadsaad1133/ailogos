import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/generation_record.dart';
import '../widgets/animated_glow_button.dart';
import '../widgets/branded_logo.dart';
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

  String? _selectedGenre;
  double _lengthValue = 1; // 0 = Short, 1 = Medium, 2 = Long

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  String get _lengthLabel {
    if (_lengthValue < 0.5) return 'Short';
    if (_lengthValue < 1.5) return 'Medium';
    return 'Long';
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
    final record = await state.generateImage(
      prompt,
      genre: _selectedGenre,
      lengthLabel: _lengthLabel,
    );
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

  Future<void> _openResult(GenerationRecord record) async {
    await Navigator.of(context).pushNamed(
      ResultScreen.routeName,
      arguments: record,
    );
  }

  void _applyTemplate(String template) {
    setState(() {
      _promptController.text = template;
    });
  }

  void _showPremiumSheet(AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
              ),
              Text(
                'OBSDIV Premium',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '• Real AI voices (Groq) for your stories.\n'
                    '• Long story length unlocked.\n'
                    '• No more free-story cap.\n'
                    '• Future exclusive features.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AnimatedGlowButton(
                label: appState.isPremium
                    ? 'Premium already active'
                    : 'Unlock Premium (dev toggle)',
                icon: Icons.star_rounded,
                isBusy: false,
                onPressed: () {
                  if (!appState.isPremium) {
                    // In real app you’d replace this with in-app purchase flow.
                    appState.activatePremium();
                  }
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Note: In production, replace this button with your real in-app purchase flow (Play Store / App Store).',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final lastRecord =
    appState.history.isEmpty ? null : appState.history.first;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                actions: const [
                  Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: BrandedLogo(
                      size: 42,
                      variant: LogoVariant.watermark,
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey ${appState.displayName},',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Turn any idea into a cozy bedtime story with OBSDIV.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),

                      // 🔐 Premium / quota banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color:
                          theme.colorScheme.surface.withOpacity(0.95),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              appState.isPremium
                                  ? Icons.star_rounded
                                  : Icons.lock_open_rounded,
                              color: appState.isPremium
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: appState.isPremium
                                  ? Text(
                                'Premium active • Real voices & long stories unlocked.',
                                style: theme.textTheme.bodyMedium,
                              )
                                  : Text(
                                'Free stories left: ${appState.freeStoriesRemaining}/${appState.freeStoryQuota}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _showPremiumSheet(appState),
                              child: Text(
                                appState.isPremium
                                    ? 'Manage'
                                    : 'Get Premium',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Templates
                      Text(
                        'Quick ideas',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TemplateChip(
                            label: 'Romantic story by the sea 💜',
                            onTap: () => _applyTemplate(
                                'A romantic bedtime story set by the sea in Lebanon, with a calm, happy ending.'),
                          ),
                          _TemplateChip(
                            label: 'Sci-fi in the future 🚀',
                            onTap: () => _applyTemplate(
                                'A sci-fi story about a young Lebanese programmer who discovers an AI hidden in an old device.'),
                          ),
                          _TemplateChip(
                            label: 'Soft horror in old village 👻',
                            onTap: () => _applyTemplate(
                                'A light horror story in an old Lebanese village at night, suspenseful but not too scary.'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      PromptInput(
                        controller: _promptController,
                        onSubmitted: () => _handleGenerate(appState),
                      ),
                      const SizedBox(height: 16),

                      // Genre + length
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGenre,
                              decoration: const InputDecoration(
                                labelText: 'Genre',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Fantasy',
                                  child: Text('Fantasy'),
                                ),
                                DropdownMenuItem(
                                  value: 'Romance',
                                  child: Text('Romance'),
                                ),
                                DropdownMenuItem(
                                  value: 'Horror',
                                  child: Text('Horror'),
                                ),
                                DropdownMenuItem(
                                  value: 'Sci-fi',
                                  child: Text('Sci-fi'),
                                ),
                                DropdownMenuItem(
                                  value: 'Mystery',
                                  child: Text('Mystery'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedGenre = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Length: $_lengthLabel',
                                    style: theme.textTheme.bodyMedium),
                                Slider(
                                  value: _lengthValue,
                                  min: 0,
                                  max: 2,
                                  divisions: 2,
                                  label: _lengthLabel,
                                  onChanged: (v) {
                                    // 🔐 Long stories are premium-only.
                                    if (!appState.isPremium && v > 1.5) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Long stories are part of OBSDIV Premium.',
                                          ),
                                        ),
                                      );
                                      setState(() => _lengthValue = 1.5);
                                    } else {
                                      setState(() => _lengthValue = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      AnimatedGlowButton(
                        label: 'Generate story with OBSDIV',
                        icon: Icons.auto_stories_rounded,
                        isBusy: appState.isGenerating,
                        onPressed: () => _handleGenerate(appState),
                      ),

                      const SizedBox(height: 24),

                      if (lastRecord != null) ...[
                        Text('Recent story',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 260,
                          child: _StoryPreviewCard(
                            record: lastRecord,
                            onOpen: () => _openResult(lastRecord),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.history_rounded),
                          label: const Text('View all stories'),
                          onPressed: () => Navigator.of(context)
                              .pushNamed(HistoryScreen.routeName),
                        ),
                      ),
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
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface.withOpacity(0.9),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _StoryPreviewCard extends StatelessWidget {
  const _StoryPreviewCard({
    required this.record,
    required this.onOpen,
  });

  final GenerationRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final snippet =
    record.story.replaceAll('\n', ' ').trim();
    final shortSnippet =
    snippet.length > 130 ? '${snippet.substring(0, 130)}…' : snippet;

    return Hero(
      tag: 'story_${record.id}',
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: theme.colorScheme.surface.withOpacity(0.96),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last story', style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(
                record.prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  shortSnippet,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    record.genre ?? (record.lengthLabel ?? ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.7),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to read',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
