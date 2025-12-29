// lib/widgets/medication_summary_widget.dart
// Compact medication summary widget for grid layout
// Shows status at-a-glance with quick actions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/medication_screen.dart';
import '../theme/app_spacing.dart';

class MedicationSummaryWidget extends StatelessWidget {
  const MedicationSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final compact = settingsProvider.compactWidgets;

    return Consumer<MedicationProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // Calculate status
        final activeMeds = provider.activeMedications
            .where((m) => m.frequency != MedicationFrequency.asNeeded)
            .length;
        final taken = provider.takenTodayCount;
        final pending = provider.pendingMedications.length;
        final hasOverdue = provider.hasOverdueMedications;

        // Status color
        Color statusColor;
        IconData statusIcon;
        String statusText;

        if (activeMeds == 0) {
          statusColor = colorScheme.onSurfaceVariant;
          statusIcon = Icons.medication_outlined;
          statusText = 'None';
        } else if (hasOverdue) {
          statusColor = Colors.red.shade600;
          statusIcon = Icons.warning_amber_rounded;
          statusText = 'Overdue';
        } else if (pending == 0) {
          statusColor = Colors.green.shade600;
          statusIcon = Icons.check_circle;
          statusText = 'Done';
        } else {
          statusColor = Colors.orange.shade600;
          statusIcon = Icons.schedule;
          statusText = '$pending left';
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: InkWell(
            onTap: () => _navigateToMedicationScreen(context),
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            child: Padding(
              padding: EdgeInsets.all(compact ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    children: [
                      if (!compact)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.medication,
                            color: Colors.purple.shade600,
                            size: 20,
                          ),
                        ),
                      if (!compact) AppSpacing.gapSm,
                      if (compact)
                        Icon(
                          Icons.medication,
                          color: Colors.purple.shade600,
                          size: 18,
                        ),
                      if (compact) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Medications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 14 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 16),

                  // Status display
                  if (activeMeds == 0) ...[
                    // Empty state
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: compact ? 32 : 48,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No medications',
                            style: (compact
                                    ? theme.textTheme.bodySmall
                                    : theme.textTheme.bodyMedium)
                                ?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Progress display
                    Row(
                      children: [
                        // Status icon
                        Container(
                          padding: EdgeInsets.all(compact ? 8 : 12),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            statusIcon,
                            color: statusColor,
                            size: compact ? 24 : 32,
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 16),
                        // Count and status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$taken',
                                      style: (compact
                                              ? theme.textTheme.titleLarge
                                              : theme.textTheme.headlineMedium)
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / $activeMeds',
                                      style: (compact
                                              ? theme.textTheme.bodySmall
                                              : theme.textTheme.bodyMedium)
                                          ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 4),
                                Text(
                                  statusText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Quick action button (non-compact mode)
                  if (!compact && activeMeds > 0 && pending > 0) ...[
                    AppSpacing.gapMd,
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () => _navigateToMedicationScreen(context),
                        child: const Text('View & Log'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToMedicationScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MedicationScreen()),
    );
  }
}
