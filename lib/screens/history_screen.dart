import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/generation_record.dart';
import '../widgets/gradient_background.dart';
import '../widgets/history_tile.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const routeName = '/history';

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().history;
    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_history.svg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Creation History'),
        ),
        body: history.isEmpty
            ? const _EmptyHistory()
            : ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          itemBuilder: (context, index) {
            final record = history[index];
            return HistoryTile(
              record: record,
              onTap: () => _openRecord(context, record),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: history.length,
        ),
      ),
    );
  }

  void _openRecord(BuildContext context, GenerationRecord record) {
    Navigator.of(context).pushNamed(
      ResultScreen.routeName,
      arguments: record,
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.amp_stories_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'No creations yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your generated masterpieces will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}