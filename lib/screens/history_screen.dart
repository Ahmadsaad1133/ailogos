import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/generation_record.dart';
import '../widgets/gradient_background.dart';
import '../widgets/history_tile.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showFavoritesOnly = false;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final history = appState.history;
    final theme = Theme.of(context);

    List<GenerationRecord> filtered = history;

    if (_showFavoritesOnly) {
      filtered =
          filtered.where((r) => r.isFavorite).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.prompt.toLowerCase().contains(q) ||
            r.story.toLowerCase().contains(q);
      }).toList();
    }

    return GradientBackground(
      asset: 'lib/assets/backgrounds/obsdiv_history.svg',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Story History'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search in your stories',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !_showFavoritesOnly,
                    onSelected: (value) {
                      setState(() => _showFavoritesOnly = !value);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Favorites'),
                    selected: _showFavoritesOnly,
                    onSelected: (value) {
                      setState(() => _showFavoritesOnly = value);
                    },
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} story${filtered.length == 1 ? '' : 'ies'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                child: Text('No stories match your filters.'),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final GenerationRecord record = filtered[index];
                  return HistoryTile(
                    record: record,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        ResultScreen.routeName,
                        arguments: record,
                      );
                    },
                    onToggleFavorite: () => context
                        .read<AppState>()
                        .toggleFavorite(record),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
