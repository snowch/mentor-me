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

  void _logMedication(BuildContext context, Medication med, MedicationLogStatus status) {
    final provider = context.read<MedicationProvider>();
    if (status == MedicationLogStatus.taken) {
      provider.logMedicationTaken(med);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${med.displayString} logged as taken'),
          duration: const Duration(seconds: 2),
        ),
      );
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
            if (isPending) ...[
              AppSpacing.gapMd,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSkipped,
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip'),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: onTaken,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Take'),
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
}
