// lib/screens/journal_screen.dart
// SIMPLIFIED: Removed quick check-in badges since we only have one mode now

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../models/pulse_entry.dart';
import '../models/pulse_type.dart';
import '../models/timeline_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/pulse_provider.dart';
import '../providers/pulse_type_provider.dart';
import '../providers/goal_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_strings.dart';
import '../utils/icon_mapper.dart';
import 'guided_journaling_screen.dart';
import 'structured_journaling_screen.dart';
import '../widgets/add_journal_dialog.dart';
import '../widgets/add_pulse_dialog.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String _searchQuery = '';
  String _selectedFilter = AppStrings.all; // All, Journal, Pulse
  bool _isCompactView = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journalProvider = context.watch<JournalProvider>();
    final pulseProvider = context.watch<PulseProvider>();

    // Merge journal and pulse entries into unified timeline
    var timelineEntries = <TimelineEntry>[
      ...journalProvider.entries.map((e) => TimelineEntry.journal(e)),
      ...pulseProvider.entries.map((e) => TimelineEntry.pulse(e)),
    ];

    // Apply filter by type
    if (_selectedFilter == AppStrings.journalNoun) {
      timelineEntries = timelineEntries.where((e) => e.type == TimelineEntryType.journal).toList();
    } else if (_selectedFilter == AppStrings.pulseCheck) {
      timelineEntries = timelineEntries.where((e) => e.type == TimelineEntryType.pulse).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      timelineEntries = timelineEntries.where((entry) {
        final query = _searchQuery.toLowerCase();
        if (entry.type == TimelineEntryType.journal) {
          return entry.journalEntry!.content?.toLowerCase().contains(query) ?? false;
        } else {
          // Search pulse entries by mood name or notes
          final pulse = entry.pulseEntry!;
          return pulse.mood.displayName.toLowerCase().contains(query) ||
                 (pulse.notes?.toLowerCase().contains(query) ?? false);
        }
      }).toList();
    }

    // Sort by timestamp (newest first)
    timelineEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Calculate stats
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisMonthStart = DateTime(now.year, now.month, 1);

    final allEntries = [
      ...journalProvider.entries.map((e) => TimelineEntry.journal(e)),
      ...pulseProvider.entries.map((e) => TimelineEntry.pulse(e)),
    ];

    final thisWeekCount = allEntries.where((e) => e.timestamp.isAfter(thisWeekStart)).length;
    final thisMonthCount = allEntries.where((e) => e.timestamp.isAfter(thisMonthStart)).length;

    return Scaffold(
      body: Column(
        children: [
          // Search bar, filters, and stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats summary
                if (allEntries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.insert_chart_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '$thisMonthCount ${thisMonthCount == 1 ? AppStrings.entryThisMonth : AppStrings.entriesThisMonth} · $thisWeekCount ${AppStrings.thisWeek}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                        const Spacer(),
                        // Compact view toggle
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isCompactView = !_isCompactView;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCompactView ? Icons.view_agenda : Icons.view_stream,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isCompactView ? AppStrings.compact : AppStrings.defaultView,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchEntries,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                // AI Chat tip
                if (_searchQuery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.tipUseAiChat,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Filter chips
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(AppStrings.all),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.journalNoun),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.pulseCheck),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Entries list grouped by day
          Expanded(
            child: journalProvider.isLoading || pulseProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : timelineEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.book_outlined, size: AppIconSize.hero, color: Theme.of(context).colorScheme.outline),
                            AppSpacing.gapLg,
                            Text(
                              _searchQuery.isNotEmpty || _selectedFilter != AppStrings.all
                                  ? AppStrings.noMatchingEntries
                                  : AppStrings.noEntriesYet,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            AppSpacing.gapSm,
                            Text(
                              _searchQuery.isNotEmpty || _selectedFilter != AppStrings.all
                                  ? AppStrings.tryAdjustingSearchOrFilter
                                  : AppStrings.startJournaling,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      )
                    : _buildGroupedEntries(context, timelineEntries),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'journal_fab',
        onPressed: () => _showJournalChoice(context),
        icon: const Icon(Icons.edit_note),
        label: const Text(AppStrings.reflectVerb),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      showCheckmark: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      selectedColor: Theme.of(context).colorScheme.primary,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        width: isSelected ? 1.5 : 1,
      ),
      elevation: isSelected ? 1 : 0,
    );
  }

  void _showJournalChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.howWouldYouLikeToReflect,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              AppSpacing.gapXl,

              // Goals & Habits Journal (formerly Guided Reflection) - RECOMMENDED
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GuidedJournalingScreen(isCheckIn: true),
                      ),
                    );
                  },
                  borderRadius: AppRadius.radiusLg,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: AppRadius.radiusLg,
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: Colors.white,
                          ),
                        ),
                        AppSpacing.gapHorizontalLg,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Goals & Habits Journal',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: AppRadius.radiusLg,
                                    ),
                                    child: const Text(
                                      AppStrings.recommended,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reflect on your goals and habits with AI-guided prompts',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              AppSpacing.gapMd,

              // 1-to-1 Mentor Session (formerly Structured Journaling)
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StructuredJournalingScreen(),
                      ),
                    );
                  },
                  borderRadius: AppRadius.radiusLg,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiaryContainer,
                            borderRadius: AppRadius.radiusLg,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                        AppSpacing.gapHorizontalLg,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '1-to-1 Mentor Session',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: AppRadius.radiusLg,
                                    ),
                                    child: const Text(
                                      'BETA',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Deep dive using therapeutic frameworks (CBT, Gratitude, etc.)',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              AppSpacing.gapMd,

              // Quick Entry option
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const AddJournalDialog(),
                    );
                  },
                  borderRadius: AppRadius.radiusLg,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: AppRadius.radiusLg,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        AppSpacing.gapHorizontalLg,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.quickEntry,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.fastSimpleNote,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

              AppSpacing.gapMd,

              // Pulse Check option
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const AddPulseDialog(),
                    );
                  },
                  borderRadius: AppRadius.radiusLg,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: AppRadius.radiusLg,
                          ),
                          child: Icon(
                            Icons.favorite_outline,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        AppSpacing.gapHorizontalLg,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.pulseCheck,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.justLogHowYouFeel,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedEntries(BuildContext context, List<TimelineEntry> entries) {
    // Group entries by day
    final Map<String, List<TimelineEntry>> entriesByDay = {};

    for (final entry in entries) {
      final timestamp = entry.timestamp;
      final dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';
      if (!entriesByDay.containsKey(dateKey)) {
        entriesByDay[dateKey] = [];
      }
      entriesByDay[dateKey]!.add(entry);
    }

    // Sort days (most recent first)
    final sortedDays = entriesByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Get today's date key to check if we should expand it by default
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added top padding
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDays[index];
        final dayEntries = entriesByDay[dateKey]!;
        final date = dayEntries.first.timestamp;

        // Sort entries within the day (most recent first)
        dayEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // Expand "Today" by default
        final isToday = dateKey == todayKey;

        return _buildDayCard(
          context,
          date,
          dayEntries,
          initiallyExpanded: isToday,
          key: ValueKey(dateKey),
        );
      },
    );
  }

  Widget _buildDayCard(BuildContext context, DateTime date, List<TimelineEntry> entries, {bool initiallyExpanded = false, Key? key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entries.length} ${entries.length == 1 ? AppStrings.entryThisMonth : AppStrings.journalEntries}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: entries.map((entry) => _buildTimelineItem(context, entry)).toList(),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, TimelineEntry entry) {
    switch (entry.type) {
      case TimelineEntryType.journal:
        return _buildJournalEntryItem(context, entry.journalEntry!);
      case TimelineEntryType.pulse:
        return _buildPulseEntryItem(context, entry.pulseEntry!);
    }
  }

  Widget _buildJournalEntryItem(BuildContext context, JournalEntry entry) {
    final compactPadding = _isCompactView ? 8.0 : 12.0;
    final compactMargin = _isCompactView ? 8.0 : 12.0;
    final maxLines = _isCompactView ? 1 : 3;

    return InkWell(
      onTap: () => _showEntryDetails(context, entry),
      onLongPress: () => _showEntryActions(context, entry),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: compactMargin),
        padding: EdgeInsets.all(compactPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Time
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const Spacer(),
                // Actions menu (hidden in compact view)
                if (!_isCompactView)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEntryActions(context, entry),
                  ),
              ],
            ),
            // Content text (1 line in compact, 3 lines in default)
            SizedBox(height: _isCompactView ? 4 : 8),
            Text(
              _getEntryPreview(entry),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            if (entry.goalIds.isNotEmpty) ...[
              SizedBox(height: _isCompactView ? 4 : 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: entry.goalIds.take(2).map((goalId) {
                  final goal = context.read<GoalProvider>().getGoalById(goalId);
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isCompactView ? 4 : 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      goal?.title ?? 'Goal',
                      style: TextStyle(
                        fontSize: _isCompactView ? 9 : 10,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPulseEntryItem(BuildContext context, PulseEntry entry) {
    final compactPadding = _isCompactView ? 8.0 : 12.0;
    final compactMargin = _isCompactView ? 8.0 : 12.0;
    final pulseTypeProvider = context.watch<PulseTypeProvider>();

    // Build list of available metrics from customMetrics
    final metrics = <Widget>[];

    // Display all custom metrics as chips
    for (final metricEntry in entry.customMetrics.entries) {
      final metricName = metricEntry.key;
      final metricValue = metricEntry.value;

      // Find the pulse type configuration for this metric
      final pulseType = pulseTypeProvider.activeTypes.firstWhere(
        (type) => type.name == metricName,
        orElse: () => PulseType(
          name: metricName,
          iconName: 'favorite',
          colorHex: 'FF9C27B0', // Default purple
        ),
      );

      metrics.add(_buildCustomMetricChip(
        context,
        metricName,
        metricValue,
        pulseType.iconName,
        pulseType.colorHex,
      ));
    }

    return InkWell(
      onTap: () => _showPulseDetails(context, entry),
      onLongPress: () => _showPulseActions(context, entry),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: compactMargin),
        padding: EdgeInsets.all(compactPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(_isCompactView ? 4 : 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.favorite_outline,
                    size: _isCompactView ? 12 : 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: _isCompactView ? 6 : 8),

                // Time
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTime(entry.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),

                const Spacer(),

                // Note indicator
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Icon(Icons.note_outlined, size: 14, color: Colors.grey[600]),

                // Actions menu (hidden in compact view)
                if (!_isCompactView)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showPulseActions(context, entry),
                  ),
              ],
            ),

            SizedBox(height: _isCompactView ? 6 : 10),

            // Metrics chips (wrappable)
            Wrap(
              spacing: _isCompactView ? 6 : 8,
              runSpacing: _isCompactView ? 6 : 8,
              children: metrics,
            ),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    
    // Compare calendar dates, not time differences
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(entryDate).inDays;

    if (difference == 0) {
      return AppStrings.today;
    } else if (difference == 1) {
      return AppStrings.yesterday;
    } else if (difference < 7) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildCustomMetricChip(
    BuildContext context,
    String metricName,
    int value,
    String iconName,
    String colorHex,
  ) {
    final color = Color(int.parse('0x$colorHex'));
    final icon = IconMapper.getIcon(iconName);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isCompactView ? 8 : AppSpacing.md,
        vertical: _isCompactView ? 4 : AppSpacing.sm - 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: _isCompactView ? 14 : AppIconSize.xs,
            color: color,
          ),
          SizedBox(width: _isCompactView ? 4 : AppSpacing.xs),
          Text(
            '$metricName: $value/5',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: AppTextStyles.medium,
              color: color.withOpacity(0.9),
              fontSize: _isCompactView ? 11 : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Extracts a preview from journal entry content, prioritizing user responses over question titles
  String _getEntryPreview(JournalEntry entry) {
    if (entry.type == JournalEntryType.quickNote) {
      return entry.content ?? '';
    } else if (entry.type == JournalEntryType.guidedJournal && entry.qaPairs != null) {
      // For guided journals, return the first answer as preview
      if (entry.qaPairs!.isNotEmpty) {
        return entry.qaPairs!.first.answer;
      }
    } else if (entry.type == JournalEntryType.structuredJournal) {
      // For structured journals (1-to-1 sessions), use content if available
      if (entry.content != null && entry.content!.isNotEmpty) {
        return entry.content!;
      }
      // Fallback: generate preview from structured data for old entries
      if (entry.structuredData != null && entry.structuredData!.isNotEmpty) {
        final buffer = StringBuffer();
        int count = 0;
        for (var fieldEntry in entry.structuredData!.entries) {
          if (count >= 2) break; // Show first 2 fields
          if (fieldEntry.value != null && fieldEntry.value.toString().isNotEmpty) {
            buffer.writeln('${fieldEntry.key}: ${fieldEntry.value}');
            count++;
          }
        }
        return buffer.toString().trim();
      }
    }
    return '';
  }

  void _showEntryActions(BuildContext context, JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text(AppStrings.viewDetails),
              onTap: () {
                Navigator.pop(context);
                _showEntryDetails(context, entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text(AppStrings.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, JournalEntry entry) {
    // Only allow editing quick notes for now
    // Guided journal entries are complex Q&A pairs and should not be edited
    if (entry.type != JournalEntryType.quickNote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.guidedJournalCannotBeEdited),
        ),
      );
      return;
    }

    final contentController = TextEditingController(text: entry.content ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime selectedDateTime = entry.createdAt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fixed header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        AppSpacing.gapHorizontalMd,
                        Expanded(
                          child: Text(
                            AppStrings.editEntry,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: AppSpacing.paddingXl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: contentController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.content,
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 12,
                            autofocus: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.pleaseWriteSomething;
                              }
                              return null;
                            },
                          ),
                          AppSpacing.gapXl,

                          // Date/Time selector
                          Card(
                            child: InkWell(
                              onTap: () async {
                                final DateTime? pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDateTime,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );

                                if (pickedDate != null && context.mounted) {
                                  final TimeOfDay? pickedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                                  );

                                  if (pickedTime != null) {
                                    setState(() {
                                      selectedDateTime = DateTime(
                                        pickedDate.year,
                                        pickedDate.month,
                                        pickedDate.day,
                                        pickedTime.hour,
                                        pickedTime.minute,
                                      );
                                    });
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Entry Date & Time',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDateTime(selectedDateTime),
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.gapXl,

                          FilledButton.icon(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final updatedEntry = JournalEntry(
                                  id: entry.id,
                                  createdAt: selectedDateTime,
                                  type: JournalEntryType.quickNote,
                                  content: contentController.text,
                                  goalIds: entry.goalIds,
                                  aiInsights: entry.aiInsights,
                                );

                                await context.read<JournalProvider>().updateEntry(updatedEntry);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text(AppStrings.entryUpdated)),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.save),
                            label: const Text(AppStrings.saveChanges),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(entryDate).inDays;

    String dateStr;
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Yesterday';
    } else if (difference == -1) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$dateStr at $hour:$minute';
  }

  void _showDeleteConfirmation(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteEntry),
        content: const Text(AppStrings.permanentlyDeleteJournalEntry),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<JournalProvider>().deleteEntry(entry.id);
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.entryDeleted)),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(BuildContext context, JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: AppSpacing.paddingXl,
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(entry.createdAt),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditDialog(context, entry);
                          },
                          tooltip: AppStrings.edit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            _showDeleteConfirmation(context, entry);
                          },
                          tooltip: AppStrings.delete,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                AppSpacing.gapXl,
                ..._buildFormattedContent(context, entry),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds formatted content based on entry type
  List<Widget> _buildFormattedContent(BuildContext context, JournalEntry entry) {
    final widgets = <Widget>[];

    // Handle quick notes - display as plain text
    if (entry.type == JournalEntryType.quickNote) {
      return [
        Text(
          entry.content ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ];
    }

    // Handle guided journal entries - display Q&A pairs
    if (entry.type == JournalEntryType.guidedJournal && entry.qaPairs != null) {
      for (int i = 0; i < entry.qaPairs!.length; i++) {
        final pair = entry.qaPairs![i];

        // Determine background color (alternating)
        final backgroundColor = i % 2 == 0
            ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
            : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.15);

        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Expanded(
                      child: Text(
                        pair.question,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                if (pair.answer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  // Answer
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      Expanded(
                        child: Text(
                          pair.answer,
                          style: Theme.of(context).textTheme.bodyMedium,
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

    return widgets.isNotEmpty
        ? widgets
        : [
            Text(
              entry.content ?? AppStrings.noContent,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ];
  }

  void _showPulseActions(BuildContext context, PulseEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text(AppStrings.viewDetails),
              onTap: () {
                Navigator.pop(context);
                _showPulseDetails(context, entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(AppStrings.delete, style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showPulseDeleteConfirmation(context, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPulseDetails(BuildContext context, PulseEntry entry) {
    final pulseTypeProvider = context.read<PulseTypeProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(entry.timestamp),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            _formatTime(entry.timestamp),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        Navigator.pop(context);
                        _showPulseDeleteConfirmation(context, entry);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Custom Metrics
                if (entry.customMetrics.isNotEmpty) ...[
                  ...entry.customMetrics.entries.map((metricEntry) {
                    final metricName = metricEntry.key;
                    final metricValue = metricEntry.value;

                    // Find the pulse type configuration
                    final pulseType = pulseTypeProvider.activeTypes.firstWhere(
                      (type) => type.name == metricName,
                      orElse: () => PulseType(
                        name: metricName,
                        iconName: 'favorite',
                        colorHex: 'FF9C27B0',
                      ),
                    );

                    final color = Color(int.parse('0x${pulseType.colorHex}'));
                    final icon = IconMapper.getIcon(pulseType.iconName);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 48,
                            color: color,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metricName,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                Text(
                                  '${AppStrings.level} $metricValue/5',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],

                // Notes
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.note,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.notes!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }


  void _showPulseDeleteConfirmation(BuildContext context, PulseEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deletePulseEntry),
        content: const Text(AppStrings.permanentlyDeletePulseEntry),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<PulseProvider>().deleteEntry(entry.id);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.pulseEntryDeleted)),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}