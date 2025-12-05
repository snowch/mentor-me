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
  final _weightController = TextEditingController(); // kg/lbs or stone
  final _lbsController = TextEditingController(); // for stone: additional lbs
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _lbsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Get hint text for weight input based on unit
  String _getWeightHint(WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return 'e.g., 70.5';
      case WeightUnit.lbs:
        return 'e.g., 155.0';
      case WeightUnit.stone:
        return '10'; // Just stone number
    }
  }

  /// Format weight change for stone unit (shows lbs change)
  String _formatChangeForStone(double changeLbs) {
    final sign = changeLbs > 0 ? '+' : '';
    return '$sign${changeLbs.round()} lbs';
  }

  /// Format weight value for display based on unit
  /// For stone: weight is stored as total pounds when stones/pounds fields are set
  String _formatWeight(double weight, WeightUnit unit, {WeightEntry? entry}) {
    if (unit == WeightUnit.stone) {
      // Use exact integers from entry if available
      if (entry != null) {
        final st = entry.exactStones;
        final lbs = entry.exactPounds;
        if (lbs == 0) {
          return '$st st';
        }
        return '$st st $lbs lbs';
      }
      // Fall back to calculation (for goal display, etc.)
      final totalLbs = weight.round();
      final stones = totalLbs ~/ 14;
      final remainingLbs = totalLbs % 14;
      if (remainingLbs == 0) {
        return '$stones st';
      }
      return '$stones st $remainingLbs lbs';
    }
    return '${weight.toStringAsFixed(1)} ${unit.displayName}';
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
                          _formatWeight(currentWeight, unit, entry: provider.latestEntry),
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
                  _formatWeight(goal.startWeight, unit),
                ),
                _buildStatItem(
                  context,
                  'Target',
                  _formatWeight(goal.targetWeight, unit),
                ),
                _buildStatItem(
                  context,
                  isAchieved ? 'Status' : 'Remaining',
                  isAchieved
                      ? 'Done!'
                      : _formatWeight(remaining, unit),
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

  /// Build simple weight input for kg or lbs
  Widget _buildSimpleWeightInput(WeightUnit unit) {
    return TextField(
      controller: _weightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Weight (${unit.displayName})',
        hintText: _getWeightHint(unit),
        border: const OutlineInputBorder(),
        suffixText: unit.displayName,
      ),
    );
  }

  /// Build stone + lbs input for stone unit
  Widget _buildStoneInput(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stone',
              hintText: '10',
              border: OutlineInputBorder(),
              suffixText: 'st',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _lbsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Pounds',
              hintText: '7',
              border: OutlineInputBorder(),
              suffixText: 'lbs',
            ),
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
            // Weight input - different layout for stone vs kg/lbs
            if (unit == WeightUnit.stone)
              _buildStoneInput(context)
            else
              _buildSimpleWeightInput(unit),
            AppSpacing.gapSm,
            // Date picker row
            InkWell(
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
                        ? _formatWeight(weeklyAvg, unit)
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
                        ? _formatWeight(monthlyAvg, unit)
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
              _formatWeight(weight, unit, entry: entry),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (change != null && change != 0) ...[
              const SizedBox(width: 8),
              Text(
                unit == WeightUnit.stone
                    ? _formatChangeForStone(change)
                    : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
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
    final unit = provider.preferredUnit;
    double? weight;
    int? stonesValue;
    int? poundsValue;

    if (unit == WeightUnit.stone) {
      // Parse stone and lbs separately
      final stoneText = _weightController.text.trim();
      final lbsText = _lbsController.text.trim();

      if (stoneText.isEmpty && lbsText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a weight')),
        );
        return;
      }

      stonesValue = int.tryParse(stoneText) ?? 0;
      poundsValue = int.tryParse(lbsText) ?? 0;

      if (stonesValue < 0 || poundsValue < 0 || poundsValue >= 14 || (stonesValue == 0 && poundsValue == 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid stone/lbs values (lbs should be 0-13)')),
        );
        return;
      }

      // Store as total pounds for calculations, but also pass exact integers
      weight = (stonesValue * 14 + poundsValue).toDouble();
    } else {
      // Parse kg or lbs
      final weightText = _weightController.text.trim();
      if (weightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a weight')),
        );
        return;
      }

      weight = double.tryParse(weightText);
      if (weight == null || weight <= 0 || weight > 1000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight')),
        );
        return;
      }
    }

    provider.addEntry(
      weight: weight,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      timestamp: _selectedDate,
      stones: stonesValue,
      pounds: poundsValue,
    );

    _weightController.clear();
    _lbsController.clear();
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
                      ? _formatWeight(provider.goal!.targetWeight, provider.preferredUnit)
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

    // Convert cm to ft/in for display
    final currentHeightCm = provider.height;
    int feet = 0;
    int inches = 0;
    if (currentHeightCm != null) {
      final totalInches = currentHeightCm / 2.54;
      feet = (totalInches / 12).floor();
      inches = (totalInches % 12).round();
    }

    final cmController = TextEditingController(
      text: currentHeightCm?.toStringAsFixed(0) ?? '',
    );
    final feetController = TextEditingController(
      text: currentHeightCm != null ? feet.toString() : '',
    );
    final inchesController = TextEditingController(
      text: currentHeightCm != null ? inches.toString() : '',
    );
    bool useMetric = true; // Default to metric

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Height'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Unit toggle
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('cm')),
                  ButtonSegment(value: false, label: Text('ft / in')),
                ],
                selected: {useMetric},
                onSelectionChanged: (selected) {
                  setState(() => useMetric = selected.first);
                },
              ),
              AppSpacing.gapMd,
              if (useMetric)
                TextField(
                  controller: cmController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    hintText: 'e.g., 175',
                    suffixText: 'cm',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: feetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Feet',
                          hintText: '5',
                          suffixText: 'ft',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: inchesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Inches',
                          hintText: '10',
                          suffixText: 'in',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
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
                double? heightCm;
                if (useMetric) {
                  heightCm = double.tryParse(cmController.text);
                } else {
                  final ft = int.tryParse(feetController.text) ?? 0;
                  final inches = int.tryParse(inchesController.text) ?? 0;
                  if (ft > 0 || inches > 0) {
                    heightCm = (ft * 12 + inches) * 2.54;
                  }
                }
                if (heightCm != null && heightCm > 50 && heightCm < 300) {
                  provider.setHeight(heightCm);
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

  void _showGoalDialog(BuildContext context, WeightProvider provider) {
    final unit = provider.preferredUnit;

    // For stone, split into st and lbs
    int goalStone = 0;
    int goalLbs = 0;
    if (unit == WeightUnit.stone && provider.goal != null) {
      final totalLbs = provider.goal!.targetWeight * 14.0;
      goalStone = (totalLbs / 14).floor();
      goalLbs = (totalLbs % 14).round();
    }

    final targetController = TextEditingController(
      text: unit == WeightUnit.stone
          ? goalStone.toString()
          : (provider.goal?.targetWeight.toStringAsFixed(1) ?? ''),
    );
    final lbsController = TextEditingController(
      text: unit == WeightUnit.stone ? goalLbs.toString() : '',
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
              if (unit == WeightUnit.stone)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target Stone',
                          hintText: '10',
                          suffixText: 'st',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: lbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pounds',
                          hintText: '7',
                          suffixText: 'lbs',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                )
              else
                TextField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target Weight',
                    suffixText: unit.displayName,
                    border: const OutlineInputBorder(),
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
                double? target;
                if (unit == WeightUnit.stone) {
                  final stones = int.tryParse(targetController.text) ?? 0;
                  final lbs = int.tryParse(lbsController.text) ?? 0;
                  if (stones > 0 || lbs > 0) {
                    // Store as decimal stone
                    target = stones + (lbs / 14.0);
                  }
                } else {
                  target = double.tryParse(targetController.text);
                }
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
    final unit = provider.preferredUnit;
    final noteController = TextEditingController(text: entry.note ?? '');

    // For stone, use exact integers from entry
    final stoneController = TextEditingController(
      text: unit == WeightUnit.stone ? entry.exactStones.toString() : '',
    );
    final lbsEditController = TextEditingController(
      text: unit == WeightUnit.stone ? entry.exactPounds.toString() : '',
    );
    final weightController = TextEditingController(
      text: unit != WeightUnit.stone
          ? entry.weightIn(unit).toStringAsFixed(1)
          : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unit == WeightUnit.stone)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stoneController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stone',
                        suffixText: 'st',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lbsEditController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pounds',
                        suffixText: 'lbs',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              )
            else
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight',
                  suffixText: unit.displayName,
                  border: const OutlineInputBorder(),
                ),
              ),
            AppSpacing.gapMd,
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
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
              double? weight;
              int? stonesValue;
              int? poundsValue;

              if (unit == WeightUnit.stone) {
                stonesValue = int.tryParse(stoneController.text) ?? 0;
                poundsValue = int.tryParse(lbsEditController.text) ?? 0;
                if (stonesValue >= 0 && poundsValue >= 0 && poundsValue < 14 &&
                    (stonesValue > 0 || poundsValue > 0)) {
                  weight = (stonesValue * 14 + poundsValue).toDouble();
                }
              } else {
                weight = double.tryParse(weightController.text);
              }

              if (weight != null && weight > 0) {
                provider.updateEntry(
                  entry.copyWith(
                    weight: weight,
                    unit: unit,
                    note: noteController.text.trim().isNotEmpty
                        ? noteController.text.trim()
                        : null,
                    stones: stonesValue,
                    pounds: poundsValue,
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

  /// Format weight value for display based on unit
  String _formatWeight(double weight, WeightUnit unit, {WeightEntry? entry}) {
    if (unit == WeightUnit.stone) {
      // Use exact integers from entry if available
      if (entry != null) {
        final st = entry.exactStones;
        final lbs = entry.exactPounds;
        if (lbs == 0) {
          return '$st st';
        }
        return '$st st $lbs lbs';
      }
      // Fall back to calculation
      final totalLbs = weight.round();
      final stones = totalLbs ~/ 14;
      final remainingLbs = totalLbs % 14;
      if (remainingLbs == 0) {
        return '$stones st';
      }
      return '$stones st $remainingLbs lbs';
    }
    return '${weight.toStringAsFixed(1)} ${unit.displayName}';
  }

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
                      _formatWeight(entry.weightIn(unit), unit, entry: entry),
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
                            unit == WeightUnit.stone
                                ? '${change > 0 ? '+' : ''}${change.round()} lbs'
                                : '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
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
