// lib/screens/weight_tracking_screen.dart
// Full weight tracking screen with logging, goals, trends, and history

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weight_provider.dart';
import '../models/weight_entry.dart';
import '../theme/app_spacing.dart';

class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<WeightProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current weight card
                _buildCurrentWeightCard(context, provider),
                AppSpacing.gapMd,

                // Goal progress card (if goal exists)
                if (provider.goal != null)
                  _buildGoalProgressCard(context, provider),
                if (provider.goal != null) AppSpacing.gapMd,

                // Log entry card
                _buildLogEntryCard(context, provider),
                AppSpacing.gapMd,

                // Trend summary card
                _buildTrendCard(context, provider),
                AppSpacing.gapMd,

                // History section
                _buildHistorySection(context, provider),
                AppSpacing.gapXl,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentWeightCard(BuildContext context, WeightProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentWeight = provider.currentWeight;
    final unit = provider.preferredUnit;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.monitor_weight,
                    color: Colors.blue.shade600,
                    size: 28,
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Weight',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (currentWeight != null)
                        Text(
                          '${currentWeight.toStringAsFixed(1)} ${unit.displayName}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          'No entries yet',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Trend indicator
                if (provider.entries.length >= 2)
                  _buildTrendIndicator(context, provider),
              ],
            ),
            // BMI display (if height is set)
            if (provider.bmi != null) ...[
              AppSpacing.gapMd,
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getBmiColor(provider.bmi!).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      color: _getBmiColor(provider.bmi!),
                      size: 20,
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'BMI: ${provider.bmi!.toStringAsFixed(1)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getBmiColor(provider.bmi!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        provider.bmiCategory ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, WeightProvider provider) {
    final trend = provider.getTrend();
    final change = provider.getWeightChange();
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String label;

    if (trend > 0) {
      icon = Icons.trending_up;
      color = Colors.orange;
      label = '+${change?.toStringAsFixed(1) ?? '0'}';
    } else if (trend < 0) {
      icon = Icons.trending_down;
      color = Colors.green;
      label = '${change?.toStringAsFixed(1) ?? '0'}';
    } else {
      icon = Icons.trending_flat;
      color = Colors.grey;
      label = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(BuildContext context, WeightProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goal = provider.goal!;
    final progress = provider.goalProgress ?? 0;
    final remaining = provider.remainingToGoal ?? 0;
    final isAchieved = provider.isGoalAchieved;
    final unit = provider.preferredUnit;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAchieved
              ? Colors.green.shade300
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isAchieved ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAchieved ? Icons.emoji_events : Icons.flag,
                  color: isAchieved ? Colors.amber : Colors.blue.shade600,
                  size: 24,
                ),
                AppSpacing.gapSm,
                Text(
                  isAchieved ? 'Goal Achieved!' : 'Goal Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showGoalDialog(context, provider),
                  tooltip: 'Edit goal',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            AppSpacing.gapMd,
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.blue.shade50,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAchieved ? Colors.green : Colors.blue.shade400,
                ),
              ),
            ),
            AppSpacing.gapMd,
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  'Start',
                  '${goal.startWeight.toStringAsFixed(1)} ${unit.displayName}',
                ),
                _buildStatItem(
                  context,
                  'Target',
                  '${goal.targetWeight.toStringAsFixed(1)} ${unit.displayName}',
                ),
                _buildStatItem(
                  context,
                  isAchieved ? 'Status' : 'Remaining',
                  isAchieved
                      ? 'Done!'
                      : '${remaining.toStringAsFixed(1)} ${unit.displayName}',
                  highlight: true,
                ),
              ],
            ),
            if (goal.targetDate != null) ...[
              AppSpacing.gapMd,
              Text(
                'Target date: ${DateFormat('MMM d, yyyy').format(goal.targetDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: highlight ? Colors.blue.shade600 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLogEntryCard(BuildContext context, WeightProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unit = provider.preferredUnit;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle, color: Colors.blue.shade600, size: 24),
                AppSpacing.gapSm,
                Text(
                  'Log Weight',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            // Weight input
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Weight (${unit.displayName})',
                      hintText: 'e.g., ${unit == WeightUnit.kg ? '70.5' : '155.0'}',
                      border: const OutlineInputBorder(),
                      suffixText: unit.displayName,
                    ),
                  ),
                ),
                AppSpacing.gapMd,
                // Date picker
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isToday(_selectedDate)
                                ? 'Today'
                                : DateFormat('MMM d').format(_selectedDate),
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            // Note input
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g., After morning workout',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            AppSpacing.gapMd,
            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _logWeight(context, provider),
                icon: const Icon(Icons.check),
                label: const Text('Log Weight'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(BuildContext context, WeightProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unit = provider.preferredUnit;

    final weeklyAvg = provider.getAverageWeight(days: 7);
    final monthlyAvg = provider.getAverageWeight(days: 30);
    final totalChange = provider.totalChange;
    final streak = provider.getLoggingStreak();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.purple.shade600, size: 24),
                AppSpacing.gapSm,
                Text(
                  'Trends & Stats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildTrendStatItem(
                    context,
                    '7-Day Avg',
                    weeklyAvg != null
                        ? '${weeklyAvg.toStringAsFixed(1)} ${unit.displayName}'
                        : '-',
                    Icons.calendar_view_week,
                    Colors.blue,
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: _buildTrendStatItem(
                    context,
                    '30-Day Avg',
                    monthlyAvg != null
                        ? '${monthlyAvg.toStringAsFixed(1)} ${unit.displayName}'
                        : '-',
                    Icons.calendar_month,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            Row(
              children: [
                Expanded(
                  child: _buildTrendStatItem(
                    context,
                    'Total Change',
                    totalChange != null
                        ? '${totalChange > 0 ? '+' : ''}${totalChange.toStringAsFixed(1)} ${unit.displayName}'
                        : '-',
                    totalChange != null && totalChange < 0
                        ? Icons.trending_down
                        : Icons.trending_up,
                    totalChange != null && totalChange < 0
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: _buildTrendStatItem(
                    context,
                    'Logging Streak',
                    streak > 0 ? '$streak days' : '-',
                    Icons.local_fire_department,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, WeightProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = provider.entries.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: Colors.grey.shade600, size: 24),
            AppSpacing.gapSm,
            Text(
              'Recent Entries',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (entries.isNotEmpty)
              TextButton(
                onPressed: () => _showAllHistory(context, provider),
                child: const Text('View All'),
              ),
          ],
        ),
        AppSpacing.gapMd,
        if (entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.monitor_weight_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  AppSpacing.gapMd,
                  Text(
                    'No weight entries yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Log your first weight above',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildHistoryItem(context, provider, entry, index > 0 ? entries[index - 1] : null);
            },
          ),
      ],
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    WeightProvider provider,
    WeightEntry entry,
    WeightEntry? previousEntry,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unit = provider.preferredUnit;
    final weight = entry.weightIn(unit);

    // Calculate change from previous entry
    double? change;
    if (previousEntry != null) {
      change = weight - previousEntry.weightIn(unit);
    }

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade100,
        child: Icon(Icons.delete, color: Colors.red.shade700),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => provider.deleteEntry(entry.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              DateFormat('d').format(entry.timestamp),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              '${weight.toStringAsFixed(1)} ${unit.displayName}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (change != null && change != 0) ...[
              const SizedBox(width: 8),
              Text(
                '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: change < 0 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(entry.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (entry.note != null && entry.note!.isNotEmpty)
              Text(
                entry.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _showEditDialog(context, provider, entry),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  // Helper methods

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _logWeight(BuildContext context, WeightProvider provider) {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a weight')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0 || weight > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    provider.addEntry(
      weight: weight,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      timestamp: _selectedDate,
    );

    _weightController.clear();
    _noteController.clear();
    setState(() => _selectedDate = DateTime.now());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weight logged successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSettingsDialog(BuildContext context) {
    final provider = context.read<WeightProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weight Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              AppSpacing.gapLg,
              // Unit selection
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Unit'),
                subtitle: Text(provider.preferredUnit.fullName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _showUnitDialog(context);
                },
              ),
              // Height for BMI
              ListTile(
                leading: const Icon(Icons.height),
                title: const Text('Height (for BMI)'),
                subtitle: Text(
                  provider.height != null
                      ? '${provider.height!.toStringAsFixed(0)} cm'
                      : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _showHeightDialog(context);
                },
              ),
              // Goal
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Weight Goal'),
                subtitle: Text(
                  provider.goal != null
                      ? '${provider.goal!.targetWeight.toStringAsFixed(1)} ${provider.preferredUnit.displayName}'
                      : 'Not set',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  _showGoalDialog(context, provider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnitDialog(BuildContext context) {
    final provider = context.read<WeightProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: WeightUnit.values.map((unit) {
            return RadioListTile<WeightUnit>(
              title: Text(unit.fullName),
              value: unit,
              groupValue: provider.preferredUnit,
              onChanged: (value) {
                if (value != null) {
                  provider.setPreferredUnit(value);
                  Navigator.of(dialogContext).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showHeightDialog(BuildContext context) {
    final provider = context.read<WeightProvider>();
    final controller = TextEditingController(
      text: provider.height?.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Height'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            hintText: 'e.g., 175',
            suffixText: 'cm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final height = double.tryParse(controller.text);
              if (height != null && height > 50 && height < 300) {
                provider.setHeight(height);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WeightProvider provider) {
    final targetController = TextEditingController(
      text: provider.goal?.targetWeight.toStringAsFixed(1) ?? '',
    );
    DateTime? targetDate = provider.goal?.targetDate;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(provider.goal == null ? 'Set Goal' : 'Edit Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Weight',
                  suffixText: provider.preferredUnit.displayName,
                ),
              ),
              AppSpacing.gapMd,
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Target Date (optional)'),
                subtitle: Text(
                  targetDate != null
                      ? DateFormat('MMM d, yyyy').format(targetDate!)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: targetDate ?? DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() => targetDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            if (provider.goal != null)
              TextButton(
                onPressed: () {
                  provider.clearGoal();
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Remove Goal',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final target = double.tryParse(targetController.text);
                if (target != null && target > 0) {
                  provider.setGoal(
                    targetWeight: target,
                    startWeight: provider.currentWeight,
                    targetDate: targetDate,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WeightProvider provider,
    WeightEntry entry,
  ) {
    final weightController = TextEditingController(
      text: entry.weightIn(provider.preferredUnit).toStringAsFixed(1),
    );
    final noteController = TextEditingController(text: entry.note ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Weight',
                suffixText: provider.preferredUnit.displayName,
              ),
            ),
            AppSpacing.gapMd,
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final weight = double.tryParse(weightController.text);
              if (weight != null && weight > 0) {
                provider.updateEntry(
                  entry.copyWith(
                    weight: weight,
                    unit: provider.preferredUnit,
                    note: noteController.text.trim().isNotEmpty
                        ? noteController.text.trim()
                        : null,
                  ),
                );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAllHistory(BuildContext context, WeightProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _WeightHistoryScreen(provider: provider),
      ),
    );
  }
}

/// Full history screen
class _WeightHistoryScreen extends StatelessWidget {
  final WeightProvider provider;

  const _WeightHistoryScreen({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = provider.entries;
    final unit = provider.preferredUnit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight History'),
      ),
      body: entries.isEmpty
          ? Center(
              child: Text(
                'No entries yet',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final prevEntry = index < entries.length - 1
                    ? entries[index + 1]
                    : null;
                double? change;
                if (prevEntry != null) {
                  change = entry.weightIn(unit) - prevEntry.weightIn(unit);
                }

                return Card(
                  child: ListTile(
                    title: Text(
                      '${entry.weightIn(unit).toStringAsFixed(1)} ${unit.displayName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('EEEE, MMM d, yyyy at h:mm a')
                            .format(entry.timestamp)),
                        if (entry.note != null) Text(entry.note!),
                      ],
                    ),
                    trailing: change != null
                        ? Text(
                            '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                            style: TextStyle(
                              color: change < 0 ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
