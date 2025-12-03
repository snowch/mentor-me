// lib/screens/dashboard_settings_screen.dart
// Screen for customizing the dashboard widget layout

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dashboard_config.dart';
import '../providers/settings_provider.dart';
import '../theme/app_spacing.dart';

class DashboardSettingsScreen extends StatelessWidget {
  const DashboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
        actions: [
          TextButton(
            onPressed: () => _showResetConfirmation(context),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final layout = settings.dashboardLayout;
          final visibleWidgets = layout.visibleWidgets;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Instructions
              Card(
                elevation: 0,
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Text(
                          'Drag to reorder widgets. Toggle switches to show or hide them on your dashboard.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapLg,

              // Visible widgets section (reorderable)
              Text(
                'Visible Widgets',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Drag to reorder',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapMd,

              // Reorderable list of visible widgets
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleWidgets.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  settings.reorderDashboardWidgets(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final config = visibleWidgets[index];
                  final info = DashboardWidgetRegistry.getWidgetInfo(config.id);
                  if (info == null) return const SizedBox.shrink(key: Key('empty'));

                  return _WidgetListItem(
                    key: ValueKey(config.id),
                    info: info,
                    isVisible: true,
                    canHide: info.canHide,
                    onToggle: info.canHide
                        ? () => settings.toggleDashboardWidget(config.id)
                        : null,
                    showDragHandle: true,
                  );
                },
              ),

              AppSpacing.gapLg,

              // Hidden widgets section
              Text(
                'Hidden Widgets',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Toggle to show on dashboard',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapMd,

              // List of hidden widgets
              ...DashboardWidgetRegistry.availableWidgets
                  .where((info) => !layout.isWidgetVisible(info.id))
                  .map((info) => _WidgetListItem(
                        key: ValueKey('hidden_${info.id}'),
                        info: info,
                        isVisible: false,
                        canHide: info.canHide,
                        onToggle: () => settings.toggleDashboardWidget(info.id),
                        showDragHandle: false,
                      )),

              // Show message if no hidden widgets
              if (layout.widgets.every((w) => w.visible)) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'All widgets are visible',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              // Bottom padding for safe area
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Dashboard'),
        content: const Text(
          'This will restore the default widget order and visibility. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<SettingsProvider>().resetDashboardLayout();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard reset to default'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _WidgetListItem extends StatelessWidget {
  final DashboardWidgetInfo info;
  final bool isVisible;
  final bool canHide;
  final VoidCallback? onToggle;
  final bool showDragHandle;

  const _WidgetListItem({
    super.key,
    required this.info,
    required this.isVisible,
    required this.canHide,
    this.onToggle,
    required this.showDragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isVisible
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Opacity(
        opacity: isVisible ? 1.0 : 0.7,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              info.icon,
              color: info.color,
              size: 24,
            ),
          ),
          title: Text(
            info.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            info.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canHide)
                Switch(
                  value: isVisible,
                  onChanged: onToggle != null ? (_) => onToggle!() : null,
                )
              else
                Tooltip(
                  message: 'This widget cannot be hidden',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (showDragHandle) ...[
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: 0, // This will be overridden by the parent
                  child: Icon(
                    Icons.drag_handle,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
