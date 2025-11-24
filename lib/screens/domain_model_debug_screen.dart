/// Domain Model Debug Screen for MentorMe application.
///
/// Provides debugging views for:
/// - Activity timeline (chronological user activity)
/// - LLM context preview (what data is sent to AI)
/// - LLM interaction history (requests and responses)
///
/// This helps understand how user activity affects AI responses.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/domain_model_debug_service.dart';
import '../services/debug_service.dart';
import '../theme/app_spacing.dart';

class DomainModelDebugScreen extends StatefulWidget {
  const DomainModelDebugScreen({super.key});

  @override
  State<DomainModelDebugScreen> createState() => _DomainModelDebugScreenState();
}

class _DomainModelDebugScreenState extends State<DomainModelDebugScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _debugService = DomainModelDebugService();
  final _logService = DebugService();

  ActivityTimelineResult? _timeline;
  LLMContextPreviewResult? _contextPreview;
  List<LogEntry>? _llmLogs;

  bool _isLoadingTimeline = false;
  bool _isLoadingContext = false;
  bool _isLoadingLogs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadTabData(_tabController.index);
    });
    // Load first tab data
    _loadTabData(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTabData(int index) async {
    switch (index) {
      case 0:
        if (_timeline == null) await _loadTimeline();
        break;
      case 1:
        if (_contextPreview == null) await _loadContextPreview();
        break;
      case 2:
        await _loadLLMLogs();
        break;
    }
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoadingTimeline = true);
    try {
      final timeline = await _debugService.buildActivityTimeline();
      setState(() => _timeline = timeline);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading timeline: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingTimeline = false);
    }
  }

  Future<void> _loadContextPreview() async {
    setState(() => _isLoadingContext = true);
    try {
      final context = await _debugService.buildLLMContextPreview();
      setState(() => _contextPreview = context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading context: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingContext = false);
    }
  }

  Future<void> _loadLLMLogs() async {
    setState(() => _isLoadingLogs = true);
    try {
      final logs = _logService.getLLMLogs();
      // Sort by timestamp descending (most recent first)
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() => _llmLogs = logs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading LLM logs: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingLogs = false);
    }
  }

  Future<void> _exportReport() async {
    try {
      final report = await _debugService.generateDebugReport();
      await Clipboard.setData(ClipboardData(text: report));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debug report copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domain Model Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Export full report',
            onPressed: _exportReport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadTabData(_tabController.index),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Timeline', icon: Icon(Icons.history)),
            Tab(text: 'LLM Context', icon: Icon(Icons.data_object)),
            Tab(text: 'LLM History', icon: Icon(Icons.chat)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimelineTab(),
          _buildContextTab(),
          _buildLLMHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_isLoadingTimeline) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_timeline == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No timeline data'),
            AppSpacing.gapMd,
            FilledButton.tonal(
              onPressed: _loadTimeline,
              child: const Text('Load Timeline'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary card
        Card(
          margin: const EdgeInsets.all(AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                AppSpacing.gapSm,
                Text(
                  'Total events: ${_timeline!.events.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_timeline!.firstActivity != null)
                  Text(
                    'First activity: ${_formatDate(_timeline!.firstActivity!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (_timeline!.lastActivity != null)
                  Text(
                    'Last activity: ${_formatDate(_timeline!.lastActivity!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                AppSpacing.gapSm,
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _timeline!.eventCounts.entries.map((e) {
                    return Chip(
                      label: Text('${e.key}: ${e.value}'),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        // Timeline list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: _timeline!.events.length,
            itemBuilder: (context, index) {
              final event = _timeline!.events[index];
              return _buildTimelineItem(event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(ActivityEvent event) {
    final color = _getEventColor(event.eventType);
    final icon = _getEventIcon(event.eventType);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          event.eventType,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              _formatDateTime(event.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        dense: true,
      ),
    );
  }

  Widget _buildContextTab() {
    if (_isLoadingContext) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_contextPreview == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No context data'),
            AppSpacing.gapMd,
            FilledButton.tonal(
              onPressed: _loadContextPreview,
              child: const Text('Load Context Preview'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Cloud AI Context
        _buildContextCard(
          title: 'Cloud AI Context (Claude)',
          tokens: _contextPreview!.cloudTokens,
          itemCounts: _contextPreview!.cloudItemCounts,
          contextText: _contextPreview!.cloudContext,
          color: Colors.blue,
        ),
        AppSpacing.gapLg,
        // Local AI Context
        _buildContextCard(
          title: 'Local AI Context (Gemma)',
          tokens: _contextPreview!.localTokens,
          itemCounts: _contextPreview!.localItemCounts,
          contextText: _contextPreview!.localContext,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildContextCard({
    required String title,
    required int tokens,
    required Map<String, int> itemCounts,
    required String contextText,
    required Color color,
  }) {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.memory, color: color),
        title: Text(title),
        subtitle: Text('$tokens estimated tokens'),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items included:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                AppSpacing.gapSm,
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: itemCounts.entries.map((e) {
                    return Chip(
                      label: Text('${e.key}: ${e.value}'),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                AppSpacing.gapMd,
                Row(
                  children: [
                    Text(
                      'Context preview:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy context',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: contextText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Context copied')),
                        );
                      },
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    contextText.isEmpty ? '(empty)' : contextText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLLMHistoryTab() {
    if (_isLoadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_llmLogs == null || _llmLogs!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            AppSpacing.gapMd,
            const Text('No LLM interactions logged yet'),
            AppSpacing.gapSm,
            const Text(
              'Chat with the AI mentor to see\nrequests and responses here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            AppSpacing.gapMd,
            FilledButton.tonal(
              onPressed: _loadLLMLogs,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _llmLogs!.length,
      itemBuilder: (context, index) {
        final log = _llmLogs![index];
        return _buildLLMLogItem(log);
      },
    );
  }

  Widget _buildLLMLogItem(LogEntry log) {
    final isRequest = log.category == 'LLM_REQUEST';
    final color = isRequest ? Colors.blue : Colors.green;
    final icon = isRequest ? Icons.upload : Icons.download;

    final metadata = log.metadata ?? {};
    final provider = metadata['provider'] ?? 'unknown';
    final model = metadata['model'] ?? 'unknown';
    final tokens = metadata['estimatedTokens'] ?? metadata['responseLength'];
    final duration = metadata['duration_ms'];
    final error = metadata['error'];
    final toolsUsed = metadata['toolsUsed'] as List?;

    // Get the actual content (prompt or response)
    final content = isRequest
        ? (metadata['prompt'] as String? ?? '')
        : (metadata['response'] as String? ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: error != null
              ? Colors.red.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.2),
          child: Icon(
            error != null ? Icons.error : icon,
            color: error != null ? Colors.red : color,
            size: 20,
          ),
        ),
        title: Text(
          isRequest ? 'REQUEST' : 'RESPONSE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: error != null ? Colors.red : color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[$provider] $model',
              style: const TextStyle(fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  _formatDateTime(log.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (duration != null) ...[
                  const Text(' • '),
                  Text(
                    '${duration}ms',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
                if (tokens != null) ...[
                  const Text(' • '),
                  Text(
                    '~$tokens tokens',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ],
            ),
            if (error != null)
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (toolsUsed != null && toolsUsed.isNotEmpty)
              Text(
                'Tools: ${toolsUsed.join(", ")}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.purple.shade700,
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isRequest ? 'Full Prompt:' : 'Full Response:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 300),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content.isEmpty ? '(empty)' : content,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                if (isRequest && metadata['contextItemCounts'] != null) ...[
                  AppSpacing.gapMd,
                  Text(
                    'Context items:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (metadata['contextItemCounts'] as Map).entries.map((e) {
                      return Chip(
                        label: Text('${e.key}: ${e.value}'),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(String eventType) {
    if (eventType.contains('GOAL')) return Colors.blue;
    if (eventType.contains('HABIT')) return Colors.green;
    if (eventType.contains('JOURNAL')) return Colors.orange;
    if (eventType.contains('PULSE')) return Colors.purple;
    if (eventType.contains('MILESTONE')) return Colors.teal;
    if (eventType.contains('CHAT')) return Colors.pink;
    return Colors.grey;
  }

  IconData _getEventIcon(String eventType) {
    if (eventType.contains('GOAL')) return Icons.flag;
    if (eventType.contains('HABIT')) return Icons.repeat;
    if (eventType.contains('JOURNAL')) return Icons.book;
    if (eventType.contains('PULSE')) return Icons.favorite;
    if (eventType.contains('MILESTONE')) return Icons.check_circle;
    if (eventType.contains('CHAT')) return Icons.chat;
    return Icons.circle;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
