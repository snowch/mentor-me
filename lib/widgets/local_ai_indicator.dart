// lib/widgets/local_ai_indicator.dart
// Visual indicator for Local AI status in app bar

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/local_ai_state_provider.dart';
import '../services/local_ai_service.dart';

class LocalAIIndicator extends StatelessWidget {
  const LocalAIIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalAIStateProvider>(
      builder: (context, stateProvider, child) {
        // Only show indicator when actively loading or inferring
        if (!stateProvider.isActive) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Tooltip(
            message: stateProvider.statusMessage,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getIndicatorColor(context, stateProvider.state),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(stateProvider.state),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getIndicatorColor(context, stateProvider.state),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(LocalAIState state) {
    switch (state) {
      case LocalAIState.loading:
        return 'Loading';
      case LocalAIState.inferring:
        return 'Thinking';
      case LocalAIState.ready:
        return 'Ready';
      case LocalAIState.idle:
        return '';
    }
  }

  Color _getIndicatorColor(BuildContext context, LocalAIState state) {
    switch (state) {
      case LocalAIState.loading:
        return Colors.orange;
      case LocalAIState.inferring:
        return Theme.of(context).colorScheme.primary;
      case LocalAIState.ready:
        return Colors.green;
      case LocalAIState.idle:
        return Colors.grey;
    }
  }
}
