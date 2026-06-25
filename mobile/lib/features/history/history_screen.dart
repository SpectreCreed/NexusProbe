import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/search_provider.dart';
import '../../core/models/osint_results.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        title: const Text('Search History'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(historyProvider),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Filter by email...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () => setState(() => _query = ''),
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                      )
                    : null,
              ),
            ),
          ).animate().fadeIn(),

          // History list
          Expanded(
            child: historyAsync.when(
              data: (searches) {
                final filtered = _query.isEmpty
                    ? searches
                    : searches
                        .where((s) => s.email.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return _EmptyState(hasQuery: _query.isNotEmpty);
                }

                return RefreshIndicator(
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.surface,
                  onRefresh: () async => ref.invalidate(historyProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _HistoryItem(
                      record: filtered[i],
                      index: i,
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(historyProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final SearchRecord record;
  final int index;

  const _HistoryItem({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final statusColor = record.isCompleted
        ? AppTheme.success
        : record.isFailed
            ? AppTheme.error
            : AppTheme.warning;

    final statusIcon = record.isCompleted
        ? Icons.check_circle_rounded
        : record.isFailed
            ? Icons.error_rounded
            : Icons.hourglass_top_rounded;

    final statusLabel = record.isCompleted
        ? 'Completed'
        : record.isFailed
            ? 'Failed'
            : 'Processing';

    return GestureDetector(
      onTap: record.isCompleted
          ? () => context.push('/report/${record.id}')
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.email,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (record.createdAt != null)
                        Text(
                          _formatDate(record.createdAt!),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (record.isCompleted)
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    )
        .animate(delay: (30 * index).ms)
        .fadeIn()
        .slideX(begin: 0.05, end: 0);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('MMM d · HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.history_rounded,
            color: AppTheme.textMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No results for your filter' : 'No history yet',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'Try a different search term'
                : 'Run your first OSINT scan from the home screen',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
