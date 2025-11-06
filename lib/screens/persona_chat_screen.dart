import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../models/creative_workspace_state.dart';

class PersonaChatScreen extends StatefulWidget {
  const PersonaChatScreen({super.key});

  static const routeName = '/persona-chat';

  @override
  State<PersonaChatScreen> createState() => _PersonaChatScreenState();
}

class _PersonaChatScreenState extends State<PersonaChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(CreativeWorkspaceState workspace) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    _messageController.clear();
    await workspace.sendPersonaMessage(message);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final workspace = context.watch<CreativeWorkspaceState>();
    final theme = Theme.of(context);
    final messages = workspace.activeMessages;
    final streamingText = workspace.streamingPersonaBuffer;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persona Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                children: CreativeWorkspaceState.personaPresets
                    .map(
                      (preset) => ChoiceChip(
                    label: Text(preset.title),
                    selected: workspace.activePreset.id == preset.id,
                    onSelected: (_) => workspace.selectPersona(preset),
                  ),
                )
                    .toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length + (streamingText.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= messages.length) {
                    return _MessageBubble(
                      message: ChatMessageModel(
                        role: 'assistant',
                        text: streamingText,
                        createdAt: DateTime.now(),
                      ),
                    );
                  }
                  return _MessageBubble(message: messages[index]);
                },
              ),
            ),
            if (workspace.personaError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  workspace.personaError!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _send(workspace),
                      decoration: const InputDecoration(
                        hintText: 'Send a message…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: workspace.isPersonaStreaming
                        ? null
                        : () => _send(workspace),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessageModel message;

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = _isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = _isUser
        ? theme.colorScheme.primary.withOpacity(0.8)
        : theme.colorScheme.surface.withOpacity(0.9);
    final textColor = _isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        ),
      ),
    );
  }
}