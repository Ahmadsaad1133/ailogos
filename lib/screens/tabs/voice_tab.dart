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
  late final TextEditingController _textController;
  late final AudioPlayer _player;
  late final VoiceNarratorService _voiceNarratorService;

  String _selectedVoice = VoiceNarratorService.availableVoices.first;
  double _pitch = 1.0;
  double _rate = 1.0;
  bool _isGenerating = false;

  VoiceNarration? _currentNarration;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _player = AudioPlayer();

    // 🔗 Connect to your local TTS server
    _voiceNarratorService = VoiceNarratorService();
  }

  @override
  void dispose() {
    _textController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isGenerating = true);

    try {
      const userId = 'local-user';

      final narration = await _voiceNarratorService.narrate(
        userId: userId,
        text: text,
        voiceStyle: _selectedVoice,
        pitch: _pitch,
        rate: _rate,
      );

      setState(() {
        _currentNarration = narration;
      });
    } catch (e) {
      debugPrint('Error generating narration: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice generation failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _play() async {
    if (_currentNarration == null) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(_currentNarration!.filePath));
    } catch (e) {
      debugPrint('Error playing narration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.watch<CreativeWorkspaceState?>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Story voice narration',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Narration text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedVoice,
                  decoration: const InputDecoration(
                    labelText: 'Voice style',
                    border: OutlineInputBorder(),
                  ),
                  items: VoiceNarratorService.availableVoices
                      .map(
                        (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedVoice = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSlider(
            context: context,
            label: 'Pitch',
            value: _pitch,
            onChanged: (v) => setState(() => _pitch = v),
          ),
          const SizedBox(height: 8),
          _buildSlider(
            context: context,
            label: 'Rate',
            value: _rate,
            onChanged: (v) => setState(() => _rate = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AnimatedGlowButton(
                  label: 'Generate narration',
                  icon: Icons.graphic_eq_rounded,
                  isBusy: _isGenerating,
                  onPressed: _isGenerating ? null : _generate,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed:
                (_currentNarration == null || _isGenerating) ? null : _play,
                icon: const Icon(Icons.play_arrow_rounded),
                tooltip: 'Play last narration',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_currentNarration != null) ...[
            Text(
              'Last narration',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _currentNarration!.text,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlider({
    required BuildContext context,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
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
