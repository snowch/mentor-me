import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/win.dart';
import '../providers/win_provider.dart';
import '../theme/app_spacing.dart';
import 'add_win_dialog.dart';

/// A widget that displays the user's recent wins for motivation.
/// Shows wins from the last 7 days with source icons and categories.
/// Shows an encouraging empty state with option to record a win when empty.
class RecentWinsWidget extends StatelessWidget {
  const RecentWinsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final winProvider = context.watch<WinProvider>();
    final recentWins = winProvider.getRecentWinsFromDays(7);

    // Show empty state if no recent wins
    if (recentWins.isEmpty) {
      return _buildEmptyState(context);
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Wins',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${recentWins.length} win${recentWins.length == 1 ? '' : 's'} this week',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                // Add win button
                IconButton(
                  onPressed: () => AddWinDialog.show(context),
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Record a win',
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                ),
                // Weekly stats badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.amber.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recentWins.length}',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Win list (show max 3 recent wins)
            ...recentWins.take(3).map((win) => _WinItem(win: win)),

            // Show more indicator if there are more wins
            if (recentWins.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    '+${recentWins.length - 3} more this week',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build an encouraging empty state when there are no recent wins
  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            // Trophy icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                color: Colors.amber.shade400,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Wins',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Celebrate your accomplishments, big or small',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => AddWinDialog.show(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Record a Win'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual win item in the list
class _WinItem extends StatelessWidget {
  final Win win;

  const _WinItem({required this.win});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getSourceColor(win.source).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getSourceIcon(win.source),
              color: _getSourceColor(win.source),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Win description and metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  win.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(win.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (win.category != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          win.category!.displayName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSourceIcon(WinSource source) {
    switch (source) {
      case WinSource.reflection:
        return Icons.psychology;
      case WinSource.journal:
        return Icons.book;
      case WinSource.manual:
        return Icons.edit;
      case WinSource.goalComplete:
        return Icons.flag;
      case WinSource.milestoneComplete:
        return Icons.check_circle;
      case WinSource.streakMilestone:
        return Icons.local_fire_department;
    }
  }

  Color _getSourceColor(WinSource source) {
    switch (source) {
      case WinSource.reflection:
        return Colors.purple;
      case WinSource.journal:
        return Colors.blue;
      case WinSource.manual:
        return Colors.teal;
      case WinSource.goalComplete:
        return Colors.green;
      case WinSource.milestoneComplete:
        return Colors.orange;
      case WinSource.streakMilestone:
        return Colors.amber.shade700;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
