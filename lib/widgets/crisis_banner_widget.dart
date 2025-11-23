import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Persistent crisis support banner widget
///
/// Displays at the top of screens to provide quick access to crisis resources.
/// Can be shown conditionally based on:
/// - User's safety plan status
/// - Recent crisis detection
/// - User preference
class CrisisBannerWidget extends StatefulWidget {
  const CrisisBannerWidget({super.key});

  @override
  State<CrisisBannerWidget> createState() => _CrisisBannerWidgetState();
}

class _CrisisBannerWidgetState extends State<CrisisBannerWidget> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.emergency,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'In crisis? Help is available 24/7',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/crisis-resources');
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: const Text('Get Help'),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onErrorContainer,
            ),
            onPressed: () {
              setState(() {
                _isDismissed = true;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Compact floating crisis button
///
/// Can be added to any screen as a FloatingActionButton alternative
class CrisisFloatingButton extends StatelessWidget {
  const CrisisFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () => Navigator.pushNamed(context, '/crisis-resources'),
      backgroundColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.onError,
      tooltip: 'Crisis Support',
      child: const Icon(Icons.emergency),
    );
  }
}
