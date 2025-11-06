import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creative_workspace_state.dart';
import '../../models/voice_narration.dart';
import '../../services/voice_narrator_service.dart';
import '../../widgets/animated_glow_button.dart';

class VoiceTab extends StatefulWidget {
  const VoiceTab({super.key});

  @override
  State<VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<VoiceTab> {
  final TextEditingController _textController = TextEditingController();
  late final AudioPlayer _player;
  String _voiceStyle = VoiceNarratorService.availableVoices.first;
  double _pitch = 1.0;
  double _rate = 1.0;
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
    _textController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _generate(CreativeWorkspaceState workspace) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter some text to narrate.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await workspace.generateNarration(
      text: text,
      voiceStyle: _voiceStyle,
      pitch: _pitch,
      rate: _rate,
    );
  }

  Future<void> _playNarration(VoiceNarration narration) async {
    await _player.stop();
    await _player.setPlaybackRate(_rate);
    await _player.play(UrlSource(narration.downloadUrl));
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<CreativeWorkspaceState>();
    final theme = Theme.of(context);
    final latest = workspace.latestNarration;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick a voice and generate a custom narration.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _voiceStyle,
            items: VoiceNarratorService.availableVoices
                .map(
                  (voice) => DropdownMenuItem(
                value: voice,
                child: Text(voice),
              ),
            )
                .toList(),
            decoration: const InputDecoration(
              labelText: 'Voice style',
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() => _voiceStyle = value);
              }
            },
          ),
          const SizedBox(height: 12),
          _SliderRow(
            label: 'Pitch ${_pitch.toStringAsFixed(2)}',
            value: _pitch,
            onChanged: (value) => setState(() => _pitch = value),
          ),
          const SizedBox(height: 12),
          _SliderRow(
            label: 'Rate ${_rate.toStringAsFixed(2)}',
            value: _rate,
            onChanged: (value) => setState(() => _rate = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Narration text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedGlowButton(
            label: 'Generate narration',
            icon: Icons.graphic_eq_rounded,
            isBusy: workspace.isGeneratingVoice,
            onPressed: () => _generate(workspace),
          ),
          if (workspace.voiceError != null) ...[
            const SizedBox(height: 8),
            Text(
              workspace.voiceError!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          if (latest != null)
            _NarrationTile(
              narration: latest,
              isPlaying: _isPlaying,
              onPlay: () => _playNarration(latest),
            ),
          const SizedBox(height: 12),
          if (workspace.narrationLibrary.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Library', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...workspace.narrationLibrary.take(5).map(
                      (item) => _NarrationTile(
                    narration: item,
                    isPlaying: _isPlaying,
                    onPlay: () => _playNarration(item),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NarrationTile extends StatelessWidget {
  const _NarrationTile({
    required this.narration,
    required this.isPlaying,
    required this.onPlay,
  });

  final VoiceNarration narration;
  final bool isPlaying;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  narration.voiceStyle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  narration.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Slider(
          value: value,
          min: 0.7,
          max: 1.3,
          divisions: 6,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}