// lib/screens/medication_screen.dart
// Medication tracking screen with list, logging, and adherence tracking

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import '../theme/app_spacing.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'All Medications', icon: Icon(Icons.medication)),
          ],
        ),
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _TodayTab(provider: provider),
              _AllMedicationsTab(provider: provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMedicationDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddMedicationSheet(),
    );
  }
}

/// Tab showing today's medications and quick logging
class _TodayTab extends StatelessWidget {
  final MedicationProvider provider;

  const _TodayTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeMeds = provider.activeMedications;
    final todayLogs = provider.todayLogs;

    if (activeMeds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              AppSpacing.gapMd,
              Text(
                'No medications added yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapSm,
              Text(
                'Tap the button below to add your first medication',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          _buildSummaryCard(context, provider),
          AppSpacing.gapMd,

          // Overdue medications alert
          if (provider.hasOverdueMedications) ...[
            _buildOverdueAlert(context, provider),
            AppSpacing.gapMd,
          ],

          // Pending medications
          if (provider.pendingMedications.isNotEmpty) ...[
            Text(
              'Pending Today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            ...provider.pendingMedications.map(
              (med) => _MedicationCard(
                medication: med,
                isPending: true,
                onTaken: () => _logMedication(context, med, MedicationLogStatus.taken),
                onSkipped: () => _showSkipDialog(context, med),
              ),
            ),
            AppSpacing.gapMd,
          ],

          // Taken today
          if (todayLogs.isNotEmpty) ...[
            Text(
              'Logged Today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            ...todayLogs.map((log) => _LogCard(log: log, onUndo: () => _undoLog(context, log))),
            AppSpacing.gapMd,
          ],

          // As needed medications
          if (provider.asNeededMedications.isNotEmpty) ...[
            Text(
              'As Needed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            ...provider.asNeededMedications.map(
              (med) => _MedicationCard(
                medication: med,
                isPending: false,
                onTaken: () => _logMedication(context, med, MedicationLogStatus.taken),
                onSkipped: () {}, // No skip for as-needed
              ),
            ),
          ],

          AppSpacing.gapXl,
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, MedicationProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final taken = provider.takenTodayCount;
    final total = provider.activeMedications.where((m) =>
        m.frequency != MedicationFrequency.asNeeded).length;
    final pending = provider.pendingMedications.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: pending == 0 ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                pending == 0 ? Icons.check_circle : Icons.schedule,
                color: pending == 0 ? Colors.green.shade600 : Colors.orange.shade600,
                size: 28,
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pending == 0 ? 'All Done!' : '$pending Pending',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$taken of $total medications taken today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueAlert(BuildContext context, MedicationProvider provider) {
    final theme = Theme.of(context);
    final overdue = provider.overdueMedications;

    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    overdue.length == 1
                        ? 'Medication Overdue'
                        : '${overdue.length} Medications Overdue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...overdue.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medication.displayString,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Scheduled ${item.scheduledTime} · ${item.overdueDisplay}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _logMedication(
                      context,
                      item.medication,
                      MedicationLogStatus.taken,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade800,
                    ),
                    child: const Text('Take Now'),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _logMedication(BuildContext context, Medication med, MedicationLogStatus status) {
    final provider = context.read<MedicationProvider>();

    if (status == MedicationLogStatus.taken) {
      // Check dosage constraints
      final violations = provider.checkConstraints(med);

      if (violations.isNotEmpty) {
        // Show warning dialog
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('Safety Limit Warning'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Taking this medication now may exceed safety limits:'),
                const SizedBox(height: 12),
                ...violations.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(v.message)),
                    ],
                  ),
                )),
                if (provider.getNextAvailableTime(med) != null &&
                    provider.getNextAvailableTime(med)!.isAfter(DateTime.now())) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Next available: ${DateFormat('h:mm a').format(provider.getNextAvailableTime(med)!)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Do you still want to log this medication?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  provider.logMedicationTaken(med);
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${med.displayString} logged as taken'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Log Anyway'),
              ),
            ],
          ),
        );
      } else {
        // No violations, log immediately
        provider.logMedicationTaken(med);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${med.displayString} logged as taken'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _undoLog(BuildContext context, MedicationLog log) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo Log'),
        content: Text('Remove the log for ${log.medicationName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<MedicationProvider>().deleteLog(log.id);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${log.medicationName} log removed'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Undo'),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(BuildContext context, Medication med) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Skip Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you skipping ${med.displayString}?'),
            AppSpacing.gapMd,
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g., Side effects, forgot, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<MedicationProvider>().logMedicationSkipped(
                med,
                skipReason: reasonController.text.isNotEmpty ? reasonController.text : null,
              );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${med.displayString} marked as skipped'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

/// Tab showing all medications
class _AllMedicationsTab extends StatelessWidget {
  final MedicationProvider provider;

  const _AllMedicationsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final meds = provider.medications;

    if (meds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.medication_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              AppSpacing.gapMd,
              Text(
                'No medications added',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final active = meds.where((m) => m.isActive).toList();
    final inactive = meds.where((m) => !m.isActive).toList();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: [
        if (active.isNotEmpty) ...[
          Text(
            'Active (${active.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapSm,
          ...active.map((med) => _MedicationListTile(medication: med)),
          AppSpacing.gapMd,
        ],
        if (inactive.isNotEmpty) ...[
          Text(
            'Inactive (${inactive.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapSm,
          ...inactive.map((med) => _MedicationListTile(medication: med)),
        ],
        AppSpacing.gapXl,
      ],
    );
  }
}

/// Card for a medication in the Today tab
class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final bool isPending;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;

  const _MedicationCard({
    required this.medication,
    required this.isPending,
    required this.onTaken,
    required this.onSkipped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<MedicationProvider>();

    // Check dosage constraints
    final violations = provider.checkConstraints(medication);
    final canTake = violations.isEmpty;
    final nextTime = provider.getNextAvailableTime(medication);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  medication.category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.displayString,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        medication.frequency.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Show dosage constraints
            if (medication.dosageConstraints != null && medication.dosageConstraints!.isNotEmpty) ...[
              AppSpacing.gapSm,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: medication.dosageConstraints!.map((constraint) =>
                  Chip(
                    label: Text(
                      constraint.description,
                      style: theme.textTheme.bodySmall,
                    ),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ).toList(),
              ),
            ],

            if (medication.instructions != null) ...[
              AppSpacing.gapSm,
              Text(
                medication.instructions!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // Show constraint violations
            if (!canTake && violations.isNotEmpty) ...[
              AppSpacing.gapSm,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Safety limit reached',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...violations.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: Colors.orange.shade700)),
                          Expanded(
                            child: Text(
                              v.message,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (nextTime != null && nextTime.isAfter(DateTime.now())) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Available: ${DateFormat('h:mm a').format(nextTime)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Show buttons for pending or as-needed medications
            if (isPending || medication.frequency == MedicationFrequency.asNeeded) ...[
              AppSpacing.gapMd,
              Row(
                children: [
                  // Skip button only for pending scheduled medications
                  if (isPending) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSkipped,
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('Skip'),
                      ),
                    ),
                    AppSpacing.gapSm,
                  ],
                  Expanded(
                    flex: isPending ? 2 : 1,
                    child: FilledButton.icon(
                      onPressed: canTake ? onTaken : null,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(canTake ? 'Take' : 'Not Available'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Log entry card
class _LogCard extends StatelessWidget {
  final MedicationLog log;
  final VoidCallback? onUndo;

  const _LogCard({required this.log, this.onUndo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: log.status == MedicationLogStatus.taken
          ? Colors.green.shade50
          : Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Text(
          log.status.emoji,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          log.medicationName,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${log.status.displayName} at ${DateFormat('h:mm a').format(log.timestamp)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (log.skipReason != null)
              Tooltip(
                message: log.skipReason!,
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (onUndo != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                onPressed: onUndo,
                tooltip: 'Undo',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// List tile for medication in All Medications tab
class _MedicationListTile extends StatelessWidget {
  final Medication medication;

  const _MedicationListTile({required this.medication});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Text(
          medication.category.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          medication.displayString,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: medication.isActive ? null : colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          medication.summary,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: medication.isActive ? 'deactivate' : 'activate',
              child: ListTile(
                leading: Icon(
                  medication.isActive ? Icons.pause : Icons.play_arrow,
                ),
                title: Text(medication.isActive ? 'Deactivate' : 'Activate'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showMedicationDetails(context),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final provider = context.read<MedicationProvider>();
    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'deactivate':
        provider.deactivateMedication(medication.id);
        break;
      case 'activate':
        provider.reactivateMedication(medication.id);
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  void _showMedicationDetails(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    medication.category.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.displayString,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          medication.category.displayName,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              _detailRow('Frequency', medication.frequency.displayName),
              if (medication.instructions != null)
                _detailRow('Instructions', medication.instructions!),
              if (medication.purpose != null)
                _detailRow('Purpose', medication.purpose!),
              if (medication.prescribedBy != null)
                _detailRow('Prescribed by', medication.prescribedBy!),
              if (medication.notes != null)
                _detailRow('Notes', medication.notes!),
              _detailRow(
                'Added',
                DateFormat('MMM d, yyyy').format(medication.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddMedicationSheet(medication: medication),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text(
          'Delete ${medication.displayString}? This will also delete all logs for this medication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MedicationProvider>().deleteMedication(medication.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding/editing medications
class _AddMedicationSheet extends StatefulWidget {
  final Medication? medication;

  const _AddMedicationSheet({this.medication});

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionsController;
  late TextEditingController _purposeController;
  late TextEditingController _prescribedByController;
  late TextEditingController _notesController;

  late MedicationFrequency _frequency;
  late MedicationCategory _category;
  late List<DosageConstraint> _constraints;

  bool get isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameController = TextEditingController(text: med?.name ?? '');
    _dosageController = TextEditingController(text: med?.dosage ?? '');
    _instructionsController = TextEditingController(text: med?.instructions ?? '');
    _purposeController = TextEditingController(text: med?.purpose ?? '');
    _prescribedByController = TextEditingController(text: med?.prescribedBy ?? '');
    _notesController = TextEditingController(text: med?.notes ?? '');
    _frequency = med?.frequency ?? MedicationFrequency.onceDaily;
    _category = med?.category ?? MedicationCategory.prescription;
    _constraints = med?.dosageConstraints != null
        ? List.from(med!.dosageConstraints!)
        : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _purposeController.dispose();
    _prescribedByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100, // Keyboard + bottom nav (80px) + spacing (20px)
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Medication' : 'Add Medication',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapLg,

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name *',
                  hintText: 'e.g., Aspirin, Vitamin D',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the medication name';
                  }
                  return null;
                },
              ),
              AppSpacing.gapMd,

              // Dosage
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g., 100mg, 500mg',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.gapMd,

              // Category dropdown
              DropdownButtonFormField<MedicationCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: MedicationCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Text(cat.emoji),
                        AppSpacing.gapSm,
                        Text(cat.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              AppSpacing.gapMd,

              // Frequency dropdown
              DropdownButtonFormField<MedicationFrequency>(
                value: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: MedicationFrequency.values.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(freq.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _frequency = value);
                },
              ),
              AppSpacing.gapMd,

              // Instructions
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'e.g., Take with food',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              AppSpacing.gapMd,

              // Purpose
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                  hintText: 'e.g., Blood pressure, pain relief',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.gapMd,

              // Prescribed by
              TextFormField(
                controller: _prescribedByController,
                decoration: const InputDecoration(
                  labelText: 'Prescribed by',
                  hintText: 'Doctor name',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.gapMd,

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Any additional notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              AppSpacing.gapLg,

              // Dosage Constraints Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Safety Limits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddConstraintDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Safety Limit',
                  ),
                ],
              ),
              if (_constraints.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No safety limits set (tap + to add)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ..._constraints.asMap().entries.map((entry) {
                  final index = entry.key;
                  final constraint = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        _getConstraintIcon(constraint.type),
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(constraint.description),
                      subtitle: Text(constraint.type.displayName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          setState(() => _constraints.removeAt(index));
                        },
                      ),
                    ),
                  );
                }),
              AppSpacing.gapLg,

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(isEditing ? 'Save Changes' : 'Add Medication'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MedicationProvider>();

    final medication = Medication(
      id: widget.medication?.id,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim().isNotEmpty
          ? _dosageController.text.trim()
          : null,
      instructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      purpose: _purposeController.text.trim().isNotEmpty
          ? _purposeController.text.trim()
          : null,
      prescribedBy: _prescribedByController.text.trim().isNotEmpty
          ? _prescribedByController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      frequency: _frequency,
      category: _category,
      createdAt: widget.medication?.createdAt,
      isActive: widget.medication?.isActive ?? true,
      dosageConstraints: _constraints.isNotEmpty ? _constraints : null,
    );

    if (isEditing) {
      provider.updateMedication(medication);
    } else {
      provider.addMedication(medication);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing ? 'Medication updated' : 'Medication added',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getConstraintIcon(DosageConstraintType type) {
    switch (type) {
      case DosageConstraintType.minTimeBetween:
        return Icons.schedule;
      case DosageConstraintType.maxPerPeriod:
        return Icons.repeat;
      case DosageConstraintType.maxCumulativeAmount:
        return Icons.stacked_bar_chart;
      case DosageConstraintType.timeWindow:
        return Icons.access_time;
      case DosageConstraintType.custom:
        return Icons.info_outline;
    }
  }

  void _showAddConstraintDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _ConstraintPickerDialog(
        onConstraintAdded: (constraint) {
          setState(() => _constraints.add(constraint));
        },
      ),
    );
  }
}

/// Dialog for picking and configuring a dosage constraint
class _ConstraintPickerDialog extends StatefulWidget {
  final Function(DosageConstraint) onConstraintAdded;

  const _ConstraintPickerDialog({required this.onConstraintAdded});

  @override
  State<_ConstraintPickerDialog> createState() => _ConstraintPickerDialogState();
}

class _ConstraintPickerDialogState extends State<_ConstraintPickerDialog> {
  DosageConstraintType? _selectedType;
  final _customDescController = TextEditingController();

  // Min time between
  int _minHours = 3;
  int _minMinutes = 0;

  // Max per period
  int _maxCount = 4;
  int _periodHours = 24;

  // Max cumulative amount
  double _maxAmount = 3000;
  String _unit = 'mg';
  int _amountPeriodHours = 24;

  // Time window
  String _notBefore = '06:00';
  String _notAfter = '22:00';
  bool _useNotBefore = false;
  bool _useNotAfter = true;

  @override
  void dispose() {
    _customDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Safety Limit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type picker
            DropdownButtonFormField<DosageConstraintType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Limit Type',
                border: OutlineInputBorder(),
              ),
              items: DosageConstraintType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),

            // Configuration based on type
            if (_selectedType == DosageConstraintType.minTimeBetween) ...[
              Text('Minimum time between doses', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _minHours.toString()),
                      onChanged: (v) => _minHours = int.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _minMinutes.toString()),
                      onChanged: (v) => _minMinutes = int.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
            ],

            if (_selectedType == DosageConstraintType.maxPerPeriod) ...[
              Text('Maximum doses per period', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Max Count',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _maxCount.toString()),
                onChanged: (v) => _maxCount = int.tryParse(v) ?? 1,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _periodHours,
                decoration: const InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6 hours')),
                  DropdownMenuItem(value: 12, child: Text('12 hours')),
                  DropdownMenuItem(value: 24, child: Text('24 hours (day)')),
                  DropdownMenuItem(value: 168, child: Text('7 days (week)')),
                ],
                onChanged: (v) => setState(() => _periodHours = v!),
              ),
            ],

            if (_selectedType == DosageConstraintType.maxCumulativeAmount) ...[
              Text('Maximum total amount per period', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: _maxAmount.toString()),
                      onChanged: (v) => _maxAmount = double.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _unit),
                      onChanged: (v) => _unit = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _amountPeriodHours,
                decoration: const InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 24, child: Text('Per day')),
                  DropdownMenuItem(value: 168, child: Text('Per week')),
                ],
                onChanged: (v) => setState(() => _amountPeriodHours = v!),
              ),
            ],

            if (_selectedType == DosageConstraintType.timeWindow) ...[
              Text('Time window restrictions', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Not before'),
                value: _useNotBefore,
                onChanged: (v) => setState(() => _useNotBefore = v!),
              ),
              if (_useNotBefore)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time (HH:MM)',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _notBefore),
                  onChanged: (v) => _notBefore = v,
                ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Not after'),
                value: _useNotAfter,
                onChanged: (v) => setState(() => _useNotAfter = v!),
              ),
              if (_useNotAfter)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time (HH:MM)',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _notAfter),
                  onChanged: (v) => _notAfter = v,
                ),
            ],

            if (_selectedType == DosageConstraintType.custom) ...[
              Text('Custom constraint', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _customDescController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Take with food',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedType == null ? null : _addConstraint,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _addConstraint() {
    late final DosageConstraint constraint;

    switch (_selectedType!) {
      case DosageConstraintType.minTimeBetween:
        constraint = DosageConstraint.minTimeBetween(
          hours: _minHours,
          minutes: _minMinutes,
        );
        break;

      case DosageConstraintType.maxPerPeriod:
        constraint = DosageConstraint.maxPerPeriod(
          count: _maxCount,
          hours: _periodHours,
        );
        break;

      case DosageConstraintType.maxCumulativeAmount:
        constraint = DosageConstraint.maxCumulativeAmount(
          amount: _maxAmount,
          unit: _unit,
          hours: _amountPeriodHours,
        );
        break;

      case DosageConstraintType.timeWindow:
        constraint = DosageConstraint.timeWindow(
          notBefore: _useNotBefore ? _notBefore : null,
          notAfter: _useNotAfter ? _notAfter : null,
        );
        break;

      case DosageConstraintType.custom:
        if (_customDescController.text.trim().isEmpty) return;
        constraint = DosageConstraint.custom(_customDescController.text.trim());
        break;
    }

    widget.onConstraintAdded(constraint);
    Navigator.pop(context);
  }
}
