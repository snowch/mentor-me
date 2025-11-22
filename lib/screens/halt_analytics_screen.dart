// lib/screens/halt_analytics_screen.dart
// HALT Check-In Analytics and Insights Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../constants/app_strings.dart';
import 'guided_journaling_screen.dart';

class HaltAnalyticsScreen extends StatelessWidget {
  const HaltAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final journalProvider = context.watch<JournalProvider>();
    final haltAnalytics = _analyzeHaltData(journalProvider.entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HALT Analytics'),
        centerTitle: true,
      ),
      body: haltAnalytics.totalChecks == 0
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Stats
                  _buildOverviewCard(context, haltAnalytics),
                  const SizedBox(height: AppSpacing.md),

                  // Needs Breakdown
                  _buildNeedsBreakdown(context, haltAnalytics),
                  const SizedBox(height: AppSpacing.md),

                  // Recent Checks Timeline
                  _buildRecentChecks(context, haltAnalytics),
                  const SizedBox(height: AppSpacing.md),

                  // AI Insights
                  _buildInsightsCard(context, haltAnalytics),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GuidedJournalingScreen(isHaltCheck: true),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('HALT Check'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No HALT Check-ins Yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Take your first HALT check to see analytics and insights about your basic needs.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GuidedJournalingScreen(isHaltCheck: true),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Take HALT Check'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, HaltAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Total Checks',
                    value: analytics.totalChecks.toString(),
                    icon: Icons.checklist,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Last 7 Days',
                    value: analytics.checksLastWeek.toString(),
                    icon: Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    label: 'Last 30 Days',
                    value: analytics.checksLastMonth.toString(),
                    icon: Icons.date_range,
                  ),
                ),
              ],
            ),
            if (analytics.mostRecentCheck != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Last Check',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(analytics.mostRecentCheck!.createdAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNeedsBreakdown(BuildContext context, HaltAnalytics analytics) {
    final maxConcerns = [
      analytics.hungryConcerns,
      analytics.angryConcerns,
      analytics.lonelyConcerns,
      analytics.tiredConcerns,
    ].reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Needs Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'How often each need was flagged as a concern',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildNeedBar(
              context,
              label: '🍽️ Hungry',
              count: analytics.hungryConcerns,
              total: analytics.totalChecks,
              maxCount: maxConcerns,
              color: Colors.orange,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildNeedBar(
              context,
              label: '😤 Angry',
              count: analytics.angryConcerns,
              total: analytics.totalChecks,
              maxCount: maxConcerns,
              color: Colors.red,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildNeedBar(
              context,
              label: '🤝 Lonely',
              count: analytics.lonelyConcerns,
              total: analytics.totalChecks,
              maxCount: maxConcerns,
              color: Colors.blue,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildNeedBar(
              context,
              label: '😴 Tired',
              count: analytics.tiredConcerns,
              total: analytics.totalChecks,
              maxCount: maxConcerns,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedBar(
    BuildContext context, {
    required String label,
    required int count,
    required int total,
    required int maxCount,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    final barWidth = maxCount > 0 ? count / maxCount : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: barWidth,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 60,
          child: Text(
            '$count ($percentage%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChecks(BuildContext context, HaltAnalytics analytics) {
    final recentChecks = analytics.recentChecks.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Checks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (recentChecks.isEmpty)
              Text(
                'No recent checks',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              )
            else
              ...recentChecks.map((entry) {
                final summary = _summarizeHaltEntry(entry);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        summary['hasUrgentConcerns'] == true
                            ? Icons.warning_amber
                            : Icons.check_circle_outline,
                        size: 20,
                        color: summary['hasUrgentConcerns'] == true
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(entry.createdAt),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              summary['text'] as String,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, HaltAnalytics analytics) {
    final insights = _generateInsights(analytics);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          insight,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  HaltAnalytics _analyzeHaltData(List<JournalEntry> allEntries) {
    final haltEntries = allEntries.where((entry) {
      if (entry.type == JournalEntryType.guidedJournal && entry.qaPairs != null) {
        final guidedData = entry.toJson()['guidedJournalData'];
        if (guidedData != null && guidedData is Map) {
          return guidedData['reflectionType'] == 'halt';
        }
      }
      return false;
    }).toList();

    haltEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final lastMonth = now.subtract(const Duration(days: 30));

    int hungryConcerns = 0;
    int angryConcerns = 0;
    int lonelyConcerns = 0;
    int tiredConcerns = 0;

    for (final entry in haltEntries) {
      if (entry.qaPairs == null) continue;

      for (final pair in entry.qaPairs!) {
        final question = pair.question.toLowerCase();
        final answer = pair.answer.toLowerCase();

        if (question.contains('hungry') || question.contains('physical')) {
          if (answer.contains('not') ||
              answer.contains('haven\'t') ||
              answer.contains('skip') ||
              answer.contains('low')) {
            hungryConcerns++;
          }
        }

        if (question.contains('angry') || question.contains('frustrat')) {
          if (answer.contains('yes') ||
              answer.contains('frustrat') ||
              answer.contains('annoyed') ||
              answer.contains('upset') ||
              answer.length > 50) {
            angryConcerns++;
          }
        }

        if (question.contains('lonely') || question.contains('connection')) {
          if (answer.contains('no one') ||
              answer.contains('alone') ||
              answer.contains('isolated') ||
              answer.contains('haven\'t')) {
            lonelyConcerns++;
          }
        }

        if (question.contains('tired') || question.contains('sleep') || question.contains('rest')) {
          if (answer.contains('exhaust') ||
              answer.contains('not enough') ||
              answer.contains('bad') ||
              answer.contains('drained')) {
            tiredConcerns++;
          }
        }
      }
    }

    return HaltAnalytics(
      totalChecks: haltEntries.length,
      checksLastWeek: haltEntries.where((e) => e.createdAt.isAfter(lastWeek)).length,
      checksLastMonth: haltEntries.where((e) => e.createdAt.isAfter(lastMonth)).length,
      mostRecentCheck: haltEntries.isNotEmpty ? haltEntries.first : null,
      recentChecks: haltEntries,
      hungryConcerns: hungryConcerns,
      angryConcerns: angryConcerns,
      lonelyConcerns: lonelyConcerns,
      tiredConcerns: tiredConcerns,
    );
  }

  Map<String, dynamic> _summarizeHaltEntry(JournalEntry entry) {
    final concerns = <String>[];
    final strengths = <String>[];

    if (entry.qaPairs == null) {
      return {'text': 'Completed check', 'hasUrgentConcerns': false};
    }

    for (final pair in entry.qaPairs!) {
      final question = pair.question.toLowerCase();
      final answer = pair.answer.toLowerCase();

      if (question.contains('hungry') || question.contains('physical')) {
        if (answer.contains('not') || answer.contains('haven\'t') || answer.contains('skip')) {
          concerns.add('Hungry');
        } else if (answer.contains('good') || answer.contains('well')) {
          strengths.add('nourished');
        }
      }

      if (question.contains('angry') || question.contains('frustrat')) {
        if (answer.contains('yes') || answer.contains('frustrat') || answer.contains('upset')) {
          concerns.add('Angry');
        } else if (answer.contains('no') || answer.contains('calm')) {
          strengths.add('calm');
        }
      }

      if (question.contains('lonely') || question.contains('connection')) {
        if (answer.contains('no one') || answer.contains('alone') || answer.contains('isolated')) {
          concerns.add('Lonely');
        } else if (answer.contains('connected') || answer.contains('talked')) {
          strengths.add('connected');
        }
      }

      if (question.contains('tired') || question.contains('sleep')) {
        if (answer.contains('exhaust') || answer.contains('not enough') || answer.contains('bad')) {
          concerns.add('Tired');
        } else if (answer.contains('good') || answer.contains('rested')) {
          strengths.add('rested');
        }
      }
    }

    final hasUrgentConcerns = concerns.length >= 3;

    if (concerns.isNotEmpty) {
      return {
        'text': 'Concerns: ${concerns.join(", ")}',
        'hasUrgentConcerns': hasUrgentConcerns,
      };
    } else if (strengths.isNotEmpty) {
      return {
        'text': 'Doing well (${strengths.join(", ")})',
        'hasUrgentConcerns': false,
      };
    } else {
      return {'text': 'Checked in on basic needs', 'hasUrgentConcerns': false};
    }
  }

  List<String> _generateInsights(HaltAnalytics analytics) {
    final insights = <String>[];

    if (analytics.totalChecks == 0) {
      return ['No data yet - take your first HALT check to get insights!'];
    }

    // Frequency insight
    if (analytics.checksLastWeek >= 2) {
      insights.add('Great job staying consistent! You\'ve done ${analytics.checksLastWeek} checks this week.');
    } else if (analytics.totalChecks >= 3 && analytics.checksLastWeek == 0) {
      insights.add('It\'s been a while since your last check. A quick HALT check can help you stay grounded.');
    }

    // Primary concern identification
    final concerns = {
      'Hungry': analytics.hungryConcerns,
      'Angry': analytics.angryConcerns,
      'Lonely': analytics.lonelyConcerns,
      'Tired': analytics.tiredConcerns,
    };

    final maxConcern = concerns.entries.reduce((a, b) => a.value > b.value ? a : b);

    if (maxConcern.value > 0 && maxConcern.value >= analytics.totalChecks * 0.3) {
      final need = maxConcern.key;
      String suggestion = '';

      switch (need) {
        case 'Hungry':
          suggestion =
              'Physical nourishment seems to be a recurring theme. Consider setting regular meal times or keeping healthy snacks nearby.';
          break;
        case 'Angry':
          suggestion =
              'Frustration is coming up often. Exploring stress management techniques or talking to someone might help.';
          break;
        case 'Lonely':
          suggestion =
              'Connection is an important need. Consider reaching out to a friend or joining a community activity.';
          break;
        case 'Tired':
          suggestion =
              'Rest is crucial for wellbeing. Review your sleep habits and consider creating a wind-down routine.';
          break;
      }

      insights.add(suggestion);
    }

    // Multiple concerns pattern
    final avgConcernsPerCheck = analytics.totalChecks > 0
        ? (analytics.hungryConcerns +
                analytics.angryConcerns +
                analytics.lonelyConcerns +
                analytics.tiredConcerns) /
            analytics.totalChecks
        : 0;

    if (avgConcernsPerCheck >= 2) {
      insights.add(
          'You\'re experiencing multiple unmet needs regularly. This is important feedback - consider what small changes might help.');
    } else if (avgConcernsPerCheck < 0.5) {
      insights.add('Your basic needs are generally well-met. Keep up the good self-care practices!');
    }

    // Encouragement
    if (analytics.totalChecks >= 5) {
      insights.add('You\'ve completed ${analytics.totalChecks} HALT checks - this self-awareness is a powerful tool for wellbeing.');
    }

    if (insights.isEmpty) {
      insights.add('Keep checking in with yourself. Regular HALT checks help you catch needs before they become urgent.');
    }

    return insights;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hours = diff.inHours;
      if (hours == 0) {
        return 'Just now';
      } else if (hours == 1) {
        return '1 hour ago';
      } else {
        return '$hours hours ago';
      }
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

/// Data class for HALT analytics
class HaltAnalytics {
  final int totalChecks;
  final int checksLastWeek;
  final int checksLastMonth;
  final JournalEntry? mostRecentCheck;
  final List<JournalEntry> recentChecks;
  final int hungryConcerns;
  final int angryConcerns;
  final int lonelyConcerns;
  final int tiredConcerns;

  HaltAnalytics({
    required this.totalChecks,
    required this.checksLastWeek,
    required this.checksLastMonth,
    required this.mostRecentCheck,
    required this.recentChecks,
    required this.hungryConcerns,
    required this.angryConcerns,
    required this.lonelyConcerns,
    required this.tiredConcerns,
  });
}
