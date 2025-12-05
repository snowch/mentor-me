// lib/screens/symptom_tracker_screen.dart
// Symptom tracking screen with logging, history, and trend analysis

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/symptom_provider.dart';
import '../models/symptom.dart';
import '../theme/app_spacing.dart';

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Symptom Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSymptomTypesSettings(context),
            tooltip: 'Manage Symptoms',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Log', icon: Icon(Icons.add_circle)),
            Tab(text: 'History', icon: Icon(Icons.history)),
            Tab(text: 'Trends', icon: Icon(Icons.insights)),
          ],
        ),
      ),
      body: Consumer<SymptomProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _LogTab(provider: provider),
              _HistoryTab(provider: provider),
              _TrendsTab(provider: provider),
            ],
          );
        },
      ),
    );
  }

  void _showSymptomTypesSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _SymptomTypeManagementScreen(),
      ),
    );
  }
}

/// Tab for logging symptoms
class _LogTab extends StatefulWidget {
  final SymptomProvider provider;

  const _LogTab({required this.provider});

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  final Map<String, int> _selectedSymptoms = {};
  final _notesController = TextEditingController();
  final _triggersController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _notesController.dispose();
    _triggersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeTypes = widget.provider.activeTypes;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick log section
          Card(
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
                      Icon(Icons.healing, color: Colors.purple.shade600),
                      AppSpacing.gapSm,
                      Text(
                        'How are you feeling?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Tap symptoms and rate their severity (1-5)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapMd,

                  // Date picker
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isToday(_selectedDate)
                                ? 'Today'
                                : DateFormat('MMM d, yyyy').format(_selectedDate),
                          ),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.gapMd,

                  // Symptom chips
                  if (activeTypes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No symptoms configured.\nTap settings to add symptoms to track.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activeTypes.map((type) {
                        final isSelected = _selectedSymptoms.containsKey(type.id);
                        final severity = _selectedSymptoms[type.id];
                        return _SymptomChip(
                          type: type,
                          isSelected: isSelected,
                          severity: severity,
                          onTap: () => _toggleSymptom(type),
                          onSeverityChanged: isSelected
                              ? (newSeverity) => _setSeverity(type.id, newSeverity)
                              : null,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          AppSpacing.gapMd,

          // Notes and triggers
          if (_selectedSymptoms.isNotEmpty) ...[
            TextField(
              controller: _triggersController,
              decoration: const InputDecoration(
                labelText: 'Triggers (optional)',
                hintText: 'e.g., Stress, weather, food',
                border: OutlineInputBorder(),
              ),
            ),
            AppSpacing.gapMd,
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional details',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            AppSpacing.gapMd,

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _logSymptoms,
                icon: const Icon(Icons.check),
                label: Text('Log ${_selectedSymptoms.length} Symptom(s)'),
              ),
            ),
          ],

          // Today's entries
          if (widget.provider.todayEntries.isNotEmpty) ...[
            AppSpacing.gapLg,
            Text(
              'Logged Today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            ...widget.provider.todayEntries.map((entry) => _EntryCard(
              entry: entry,
              provider: widget.provider,
            )),
          ],

          AppSpacing.gapXl,
        ],
      ),
    );
  }

  void _toggleSymptom(SymptomType type) {
    setState(() {
      if (_selectedSymptoms.containsKey(type.id)) {
        _selectedSymptoms.remove(type.id);
      } else {
        _selectedSymptoms[type.id] = 3; // Default severity
      }
    });
  }

  void _setSeverity(String typeId, int severity) {
    setState(() {
      _selectedSymptoms[typeId] = severity;
    });
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _logSymptoms() {
    if (_selectedSymptoms.isEmpty) return;

    widget.provider.logMultipleSymptoms(
      symptoms: Map.from(_selectedSymptoms),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      triggers: _triggersController.text.isNotEmpty ? _triggersController.text : null,
      timestamp: _selectedDate,
    );

    // Clear form
    setState(() {
      _selectedSymptoms.clear();
      _notesController.clear();
      _triggersController.clear();
      _selectedDate = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Symptoms logged successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Symptom chip with severity slider
class _SymptomChip extends StatelessWidget {
  final SymptomType type;
  final bool isSelected;
  final int? severity;
  final VoidCallback onTap;
  final ValueChanged<int>? onSeverityChanged;

  const _SymptomChip({
    required this.type,
    required this.isSelected,
    this.severity,
    required this.onTap,
    this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!isSelected) {
      return ActionChip(
        avatar: Text(type.emoji),
        label: Text(type.name),
        onPressed: onTap,
      );
    }

    return Card(
      elevation: 0,
      color: _getSeverityColor(severity ?? 3).withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _getSeverityColor(severity ?? 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 20)),
                AppSpacing.gapSm,
                Text(
                  type.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppSpacing.gapSm,
                InkWell(
                  onTap: onTap,
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${SymptomSeverity.displayName(severity ?? 3)} ($severity)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            SizedBox(
              width: 150,
              child: Slider(
                value: (severity ?? 3).toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: onSeverityChanged != null
                    ? (value) => onSeverityChanged!(value.round())
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// History tab
class _HistoryTab extends StatelessWidget {
  final SymptomProvider provider;

  const _HistoryTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entries = provider.entries;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              AppSpacing.gapMd,
              Text(
                'No symptom entries yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapSm,
              Text(
                'Start logging symptoms in the Log tab',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group entries by date
    final groupedEntries = <String, List<SymptomEntry>>{};
    for (final entry in entries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.timestamp);
      groupedEntries.putIfAbsent(dateKey, () => []).add(entry);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: groupedEntries.length,
      itemBuilder: (context, index) {
        final dateKey = groupedEntries.keys.elementAt(index);
        final dayEntries = groupedEntries[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) AppSpacing.gapMd,
            Text(
              _formatDateHeader(date),
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapSm,
            ...dayEntries.map((entry) => _EntryCard(
              entry: entry,
              provider: provider,
            )),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }
}

/// Entry card for history
class _EntryCard extends StatelessWidget {
  final SymptomEntry entry;
  final SymptomProvider provider;

  const _EntryCard({
    required this.entry,
    required this.provider,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEntryDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('h:mm a').format(entry.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _confirmDelete(context),
                    visualDensity: VisualDensity.compact,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.symptoms.entries.map((e) {
                  final type = provider.getTypeById(e.key);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(e.value).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getSeverityColor(e.value).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type?.emoji ?? '?'),
                        AppSpacing.gapXs,
                        Text(
                          type?.name ?? 'Unknown',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AppSpacing.gapXs,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(e.value),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${e.value}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (entry.triggers != null || entry.notes != null) ...[
                AppSpacing.gapSm,
                if (entry.triggers != null)
                  Text(
                    'Triggers: ${entry.triggers}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (entry.notes != null)
                  Text(
                    entry.notes!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showEntryDetails(BuildContext context) {
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
              Text(
                'Symptom Entry',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.gapSm,
              Text(
                DateFormat('EEEE, MMM d at h:mm a').format(entry.timestamp),
                style: theme.textTheme.bodyMedium,
              ),
              AppSpacing.gapLg,
              ...entry.symptoms.entries.map((e) {
                final type = provider.getTypeById(e.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(type?.emoji ?? '?', style: const TextStyle(fontSize: 24)),
                      AppSpacing.gapSm,
                      Expanded(
                        child: Text(
                          type?.name ?? 'Unknown',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(e.value),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${e.value}/5 - ${SymptomSeverity.displayName(e.value)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (entry.triggers != null) ...[
                AppSpacing.gapMd,
                Text(
                  'Triggers',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(entry.triggers!),
              ],
              if (entry.notes != null) ...[
                AppSpacing.gapMd,
                Text(
                  'Notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(entry.notes!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this symptom entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteEntry(entry.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Trends tab
class _TrendsTab extends StatelessWidget {
  final SymptomProvider provider;

  const _TrendsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = provider.weekSummary;
    final trendingSymptoms = provider.getTrendingSymptoms();

    if (provider.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              AppSpacing.gapMd,
              Text(
                'Not enough data yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapSm,
              Text(
                'Log symptoms for a few days to see trends',
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
          // Weekly summary card
          Card(
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
                      Icon(Icons.calendar_view_week, color: Colors.purple.shade600),
                      AppSpacing.gapSm,
                      Text(
                        'This Week',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'Entries',
                          value: '${summary.totalEntries}',
                          icon: Icons.edit_note,
                          color: Colors.blue,
                        ),
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: _StatBox(
                          label: 'Avg Severity',
                          value: _getAverageSeverity(summary).toStringAsFixed(1),
                          icon: Icons.trending_flat,
                          color: _getSeverityColor(_getAverageSeverity(summary).round()),
                        ),
                      ),
                    ],
                  ),
                  if (summary.mostFrequentSymptom != null) ...[
                    AppSpacing.gapMd,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade600),
                          AppSpacing.gapSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Most Frequent',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                Text(
                                  _getSymptomName(summary.mostFrequentSymptom!),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AppSpacing.gapMd,

          // Trending symptoms
          if (trendingSymptoms.isNotEmpty) ...[
            Card(
              elevation: 0,
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.red.shade600),
                        AppSpacing.gapSm,
                        Text(
                          'Increasing Symptoms',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'These symptoms are trending higher this week compared to last week:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                    AppSpacing.gapMd,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: trendingSymptoms.map((id) {
                        final type = provider.getTypeById(id);
                        return Chip(
                          avatar: Text(type?.emoji ?? '?'),
                          label: Text(type?.name ?? 'Unknown'),
                          backgroundColor: Colors.red.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapMd,
          ],

          // Frequency by symptom
          Text(
            'Symptom Frequency (7 days)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          AppSpacing.gapSm,
          ...summary.occurrencesByType.entries.map((e) {
            final type = provider.getTypeById(e.key);
            if (type == null) return const SizedBox.shrink();
            return _FrequencyBar(
              symptomName: type.name,
              emoji: type.emoji,
              count: e.value,
              maxCount: summary.occurrencesByType.values
                  .fold(1, (max, v) => v > max ? v : max),
            );
          }),

          AppSpacing.gapXl,
        ],
      ),
    );
  }

  String _getSymptomName(String id) {
    final type = provider.getTypeById(id);
    return type != null ? '${type.emoji} ${type.name}' : 'Unknown';
  }

  double _getAverageSeverity(SymptomSummary summary) {
    if (summary.averageSeverityByType.isEmpty) return 0;
    final total = summary.averageSeverityByType.values.reduce((a, b) => a + b);
    return total / summary.averageSeverityByType.length;
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Stat box widget
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frequency bar widget
class _FrequencyBar extends StatelessWidget {
  final String symptomName;
  final String emoji;
  final int count;
  final int maxCount;

  const _FrequencyBar({
    required this.symptomName,
    required this.emoji,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = count / maxCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji),
              AppSpacing.gapSm,
              Expanded(child: Text(symptomName)),
              Text(
                '$count',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

/// Symptom type management screen
class _SymptomTypeManagementScreen extends StatelessWidget {
  const _SymptomTypeManagementScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Symptoms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTypeDialog(context),
            tooltip: 'Add custom symptom',
          ),
        ],
      ),
      body: Consumer<SymptomProvider>(
        builder: (context, provider, child) {
          final types = provider.types;

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            onReorder: (oldIndex, newIndex) {
              provider.reorderSymptomTypes(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final type = types[index];
              return Card(
                key: Key(type.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Text(type.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(type.name),
                  subtitle: Text(
                    type.isSystemDefined ? 'System' : 'Custom',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: type.isActive,
                        onChanged: (_) => provider.toggleSymptomTypeActive(type.id),
                      ),
                      if (!type.isSystemDefined)
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmDeleteType(context, provider, type),
                        ),
                      const Icon(Icons.drag_handle),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddTypeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: '🔹');
    SymptomCategory category = SymptomCategory.other;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Custom Symptom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Symptom Name',
                  hintText: 'e.g., Dizziness',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.gapMd,
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  border: OutlineInputBorder(),
                ),
              ),
              AppSpacing.gapMd,
              DropdownButtonFormField<SymptomCategory>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: SymptomCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
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
                if (nameController.text.isNotEmpty) {
                  context.read<SymptomProvider>().addSymptomType(
                    SymptomType(
                      name: nameController.text,
                      emoji: emojiController.text.isNotEmpty
                          ? emojiController.text
                          : '🔹',
                      category: category,
                      isSystemDefined: false,
                    ),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteType(
    BuildContext context,
    SymptomProvider provider,
    SymptomType type,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Symptom Type'),
        content: Text('Delete "${type.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSymptomType(type.id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
