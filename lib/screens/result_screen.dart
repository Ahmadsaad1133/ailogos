import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/generation_record.dart';
import '../services/groq_tts_service.dart';
import '../widgets/branded_logo.dart';
import '../widgets/gradient_background.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  static const routeName = '/result';

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

enum _ReadingTheme { dark, light, sepia }
enum _TtsEngine { device, groq }

class _ResultScreenState extends State<ResultScreen> {
  double _fontSize = 18;
  _ReadingTheme _readingTheme = _ReadingTheme.dark;

  // 🎙 Engines
  final GroqTTSService _groqTts = GroqTTSService();
  final AudioPlayer _groqPlayer = AudioPlayer();
  final FlutterTts _deviceTts = FlutterTts();

  _TtsEngine _selectedEngine = _TtsEngine.device;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _initDeviceTts();
  }

  Future<void> _initDeviceTts() async {
    try {
      // Wait for speak completion callbacks
      await _deviceTts.awaitSpeakCompletion(true);

      // Basic config
      await _deviceTts.setSpeechRate(0.45);
      await _deviceTts.setPitch(1.0);

      // Try to pick a "nice" English voice if available
      final voices = await _deviceTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        Map<dynamic, dynamic>? best;
        for (final v in voices) {
          final map = Map<dynamic, dynamic>.from(v as Map);
          final locale = (map['locale'] ?? '').toString().toLowerCase();
          if (locale.startsWith('en-us') ||
              locale.startsWith('en-gb') ||
              locale.startsWith('en')) {
            best = map;
            break;
          }
        }
        best ??= Map<dynamic, dynamic>.from(voices.first as Map);

        final name = best['name']?.toString();
        final locale = best['locale']?.toString();

        if (locale != null && locale.isNotEmpty) {
          await _deviceTts.setLanguage(locale);
        } else {
          await _deviceTts.setLanguage('en-US');
        }

        if (name != null && name.isNotEmpty) {
          await _deviceTts.setVoice({
            'name': name,
            'locale': locale ?? 'en-US',
          });
        }
      } else {
        // fallback
        await _deviceTts.setLanguage('en-US');
      }

      // When device TTS finishes or is cancelled
      _deviceTts.setCompletionHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });
      _deviceTts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });
    } catch (e) {
      // If initialisation itself fails, show a hint once.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Device voice not available on this device/emulator: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _groqPlayer.stop();
    _groqPlayer.dispose();
    _deviceTts.stop();
    super.dispose();
  }

  Future<void> _playDeviceTts(String text) async {
    try {
      await _stopAllAudio();
      setState(() {
        _isPlaying = true;
      });

      final result = await _deviceTts.speak(text);

      // flutter_tts returns 1 on success on Android/iOS
      if (result != 1 && mounted) {
        setState(() {
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device TTS failed (code: $result). '
                'Make sure a TTS engine is installed on this device.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Device voice error: $e\nCheck if Text-to-speech is enabled in system settings.',
          ),
        ),
      );
    }
  }

  Future<void> _playGroqAudio(String text) async {
    if (_isLoadingAudio) return;

    try {
      await _stopAllAudio();
      setState(() {
        _isLoadingAudio = true;
      });

      final file = await _groqTts.generateSpeech(text);
      await _groqPlayer.setPlaybackRate(0.9);
      await _groqPlayer.play(DeviceFileSource(file.path));

      if (!mounted) return;
      setState(() {
        _isPlaying = true;
        _isLoadingAudio = false;
      });

      _groqPlayer.onPlayerComplete.listen((event) {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAudio = false;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _stopAllAudio() async {
    await _deviceTts.stop();
    await _groqPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isLoadingAudio = false;
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
                'Unlock AI voice for your stories, long length, and more perks.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.star_rounded),
                label: Text(appState.isPremium
                    ? 'Premium already active'
                    : 'Unlock Premium (dev toggle)'),
                onPressed: () {
                  if (!appState.isPremium) {
                    appState.activatePremium();
                  }
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              Text(
                'In production, replace this with your real in-app purchase flow.',
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final GenerationRecord? fromArgs =
    args is GenerationRecord ? args : null;

    final appState = context.watch<AppState>();
    final fallback =
    appState.history.isNotEmpty ? appState.history.first : null;

    final record = fromArgs ?? fallback;
    if (record == null) {
      return const _MissingRecord();
    }

    // If user lost premium, ensure engine falls back to device.
    if (!appState.isPremium && _selectedEngine == _TtsEngine.groq) {
      _selectedEngine = _TtsEngine.device;
    }

    final theme = Theme.of(context);
    final colors = _resolveColors(theme);

    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_result.svg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Story Result'),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: BrandedLogo(size: 44, variant: LogoVariant.icon),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prompt
                Text('Prompt', style: theme.textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  record.prompt,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),

                // Story box
                Expanded(
                  child: Hero(
                    tag: 'story_${record.id}',
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: colors.background,
                        border: Border.all(color: colors.border),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Text(
                            record.story,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: _fontSize,
                              height: 1.6,
                              color: colors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🎙 Engine selector + big play button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Device voice'),
                          selected: _selectedEngine == _TtsEngine.device,
                          onSelected: (_) {
                            setState(() {
                              _selectedEngine = _TtsEngine.device;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Groq AI voice'),
                              if (!appState.isPremium) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.lock, size: 14),
                              ],
                            ],
                          ),
                          selected: _selectedEngine == _TtsEngine.groq,
                          onSelected: (_) {
                            if (!appState.isPremium) {
                              _showPremiumSheet(appState);
                            } else {
                              setState(() {
                                _selectedEngine = _TtsEngine.groq;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingAudio)
                      const Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    else
                      Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () {
                            if (_isPlaying) {
                              _stopAllAudio();
                            } else {
                              if (_selectedEngine == _TtsEngine.device) {
                                _playDeviceTts(record.story);
                              } else {
                                _playGroqAudio(record.story);
                              }
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (_selectedEngine == _TtsEngine.groq)
                      Text(
                        appState.isPremium
                            ? 'AI voice plays a short preview of the story.'
                            : 'AI voice is part of OBSDIV Premium.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Reading theme + font size controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        _ThemeChip(
                          label: 'Dark',
                          selected: _readingTheme == _ReadingTheme.dark,
                          onTap: () => setState(
                                () => _readingTheme = _ReadingTheme.dark,
                          ),
                        ),
                        _ThemeChip(
                          label: 'Light',
                          selected: _readingTheme == _ReadingTheme.light,
                          onTap: () => setState(
                                () => _readingTheme = _ReadingTheme.light,
                          ),
                        ),
                        _ThemeChip(
                          label: 'Sepia',
                          selected: _readingTheme == _ReadingTheme.sepia,
                          onTap: () => setState(
                                () => _readingTheme = _ReadingTheme.sepia,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontSize = (_fontSize - 1).clamp(14, 26);
                            });
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          _fontSize.toInt().toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _fontSize = (_fontSize + 1).clamp(14, 26);
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _ResultActionButton(
                      icon: Icons.copy_rounded,
                      label: 'Copy story',
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: record.story),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Story copied to clipboard'),
                          ),
                        );
                      },
                    ),
                    _ResultActionButton(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          HomeScreen.routeName,
                              (route) => false,
                        );
                      },
                    ),
                    _ResultActionButton(
                      icon: Icons.history_edu_rounded,
                      label: 'History',
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(HistoryScreen.routeName);
                      },
                    ),
                    _ResultActionButton(
                      icon: Icons.auto_stories_rounded,
                      label: 'Continue story',
                      onTap: () async {
                        final state = context.read<AppState>();
                        final newRecord = await state.generateImage(
                          record.prompt,
                          genre: record.genre,
                          lengthLabel: record.lengthLabel,
                          continueFromPrevious: true,
                          previousStory: record.story,
                        );
                        if (!context.mounted || newRecord == null) return;
                        await Navigator.of(context).pushReplacementNamed(
                          ResultScreen.routeName,
                          arguments: newRecord,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StoryColors _resolveColors(ThemeData theme) {
    switch (_readingTheme) {
      case _ReadingTheme.dark:
        return _StoryColors(
          background: theme.colorScheme.surface.withOpacity(0.98),
          text: Colors.white,
          border: theme.colorScheme.primary.withOpacity(0.4),
        );
      case _ReadingTheme.light:
        return _StoryColors(
          background: Colors.white,
          text: Colors.black87,
          border: Colors.grey.shade300,
        );
      case _ReadingTheme.sepia:
        return _StoryColors(
          background: const Color(0xFFF4E7C3),
          text: const Color(0xFF5B4636),
          border: const Color(0xFFE0C89D),
        );
    }
  }
}

class _StoryColors {
  final Color background;
  final Color text;
  final Color border;

  _StoryColors({
    required this.background,
    required this.text,
    required this.border,
  });
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
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
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.9)
              : theme.colorScheme.surface.withOpacity(0.9),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}

class _ResultActionButton extends StatelessWidget {
  const _ResultActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.surface.withOpacity(0.85),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingRecord extends StatelessWidget {
  const _MissingRecord();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_result.svg',
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text('No story to display.'),
        ),
      ),
    );
  }
}
