import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creative_workspace_state.dart';
import '../../models/sleep_sound_mix.dart';
import '../../widgets/animated_glow_button.dart';

class SleepTab extends StatefulWidget {
  const SleepTab({super.key});

  @override
  State<SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends State<SleepTab> {
  final Set<String> _layers = {'rain', 'wind'};
  double _durationSeconds = 45;
  double _mixRatio = 0.7;
  bool _loop = false;
  late final AudioPlayer _player;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (mounted && playing != _isPlaying) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _generate(CreativeWorkspaceState workspace) async {
    if (_layers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one ambient layer.')),
      );
      return;
    }
    await workspace.generateSleepMix(
      layers: _layers.toList(),
      duration: Duration(seconds: _durationSeconds.round()),
      loop: _loop,
      mixRatio: _mixRatio,
    );
  }

  Future<void> _playMix(SleepSoundMix mix) async {
    await _player.stop();
    await _player.setReleaseMode(
      mix.loopEnabled ? ReleaseMode.loop : ReleaseMode.stop,
    );
    if (mix.bytes != null) {
      await _player.play(BytesSource(mix.bytes!));
      return;
    }
    if (mix.downloadUrl.isNotEmpty) {
      await _player.play(UrlSource(mix.downloadUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<CreativeWorkspaceState>();
    final theme = Theme.of(context);
    final latest = workspace.latestSleepMix;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blend ambient layers to craft a looping sleep sound.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              _LayerChip(
                label: 'Rain',
                value: 'rain',
                selected: _layers.contains('rain'),
                onChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _layers.add('rain');
                    } else {
                      _layers.remove('rain');
                    }
                  });
                },
              ),
              _LayerChip(
                label: 'Wind',
                value: 'wind',
                selected: _layers.contains('wind'),
                onChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _layers.add('wind');
                    } else {
                      _layers.remove('wind');
                    }
                  });
                },
              ),
              _LayerChip(
                label: 'Waves',
                value: 'waves',
                selected: _layers.contains('waves'),
                onChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _layers.add('waves');
                    } else {
                      _layers.remove('waves');
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Duration: ${_durationSeconds.round()} sec',
              style: theme.textTheme.bodyMedium),
          Slider(
            value: _durationSeconds,
            min: 30,
            max: 60,
            divisions: 6,
            onChanged: (value) => setState(() => _durationSeconds = value),
          ),
          const SizedBox(height: 12),
          Text('Mix ratio ${(100 * _mixRatio).round()}%',
              style: theme.textTheme.bodyMedium),
          Slider(
            value: _mixRatio,
            min: 0.4,
            max: 1.0,
            onChanged: (value) => setState(() => _mixRatio = value),
          ),
          SwitchListTile(
            value: _loop,
            onChanged: (value) => setState(() => _loop = value),
            title: const Text('Loop mode'),
          ),
          const SizedBox(height: 12),
          AnimatedGlowButton(
            label: 'Generate sleep mix',
            icon: Icons.nightlight_round,
            isBusy: workspace.isGeneratingSleep,
            onPressed: () => _generate(workspace),
          ),
          if (workspace.sleepError != null) ...[
            const SizedBox(height: 8),
            Text(
              workspace.sleepError!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          if (latest != null)
            _SleepMixTile(
              mix: latest,
              isPlaying: _isPlaying,
              onPlay: () => _playMix(latest),
            ),
          const SizedBox(height: 12),
          if (workspace.sleepLibrary.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved mixes', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...workspace.sleepLibrary.take(5).map(
                      (mix) => _SleepMixTile(
                    mix: mix,
                    isPlaying: _isPlaying,
                    onPlay: () => _playMix(mix),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
    );
  }
}

class _SleepMixTile extends StatelessWidget {
  const _SleepMixTile({
    required this.mix,
    required this.isPlaying,
    required this.onPlay,
  });

  final SleepSoundMix mix;
  final bool isPlaying;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layers = mix.layers.join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withOpacity(0.94),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
            onPressed: onPlay,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layers,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${mix.durationSeconds.round()} sec • mix ${mix.mixRatio.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}