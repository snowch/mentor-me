import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/clinical_assessment.dart';
import '../providers/assessment_provider.dart';
import '../theme/app_spacing.dart';
import 'clinical_assessment_screen.dart';

/// Dashboard showing clinical assessment history and trends
///
/// Features:
/// - List of all completed assessments with scores and dates
/// - Trend visualization showing changes over time
/// - Quick access to take new assessments
/// - Filter by assessment type
/// - Summary statistics for each assessment type
class AssessmentDashboardScreen extends StatefulWidget {
  const AssessmentDashboardScreen({super.key});

  @override
  State<AssessmentDashboardScreen> createState() => _AssessmentDashboardScreenState();
}

class _AssessmentDashboardScreenState extends State<AssessmentDashboardScreen> {
  AssessmentType? _filterType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Assessments'),
        elevation: 0,
      ),
      body: Consumer<AssessmentProvider>(
        builder: (context, provider, child) {
          final assessments = _filterType == null
              ? provider.assessments
              : provider.getByType(_filterType!);

          return Column(
            children: [
              // Filter chips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: colorScheme.surfaceContainerHighest,
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterType == null,
                      onSelected: (selected) {
                        setState(() => _filterType = null);
                      },
                    ),
                    ...AssessmentType.values.map((type) {
                      return FilterChip(
                        label: Text(type.shortName),
                        selected: _filterType == type,
                        onSelected: (selected) {
                          setState(() => _filterType = selected ? type : null);
                        },
                      );
                    }),
                  ],
                ),
              ),

              // Summary cards
              if (_filterType == null) ...[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: AssessmentType.values.map((type) {
                      final typeAssessments = provider.getByType(type);
                      final latestAssessment = typeAssessments.isNotEmpty ? typeAssessments.first : null;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          child: _SummaryCard(
                            type: type,
                            latestAssessment: latestAssessment,
                            totalCount: typeAssessments.length,
                            onTap: () => _takeAssessment(type),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showAssessmentPicker(),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Take Assessment'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Assessment history list
              Expanded(
                child: assessments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: assessments.length,
                        itemBuilder: (context, index) {
                          final assessment = assessments[index];
                          return _AssessmentListTile(assessment: assessment);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _filterType == null
                  ? 'No assessments yet'
                  : 'No ${_filterType!.shortName} assessments yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Track your mental wellbeing with validated clinical questionnaires',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _showAssessmentPicker(),
              icon: const Icon(Icons.add),
              label: const Text('Take Your First Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssessmentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Choose an assessment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            ...AssessmentType.values.map((type) {
              return ListTile(
                leading: Icon(
                  _getAssessmentIcon(type),
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(type.displayName),
                subtitle: Text(type.description),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _takeAssessment(type);
                },
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  IconData _getAssessmentIcon(AssessmentType type) {
    switch (type) {
      case AssessmentType.phq9:
        return Icons.sentiment_very_dissatisfied;
      case AssessmentType.gad7:
        return Icons.psychology;
      case AssessmentType.pss10:
        return Icons.monitor_heart;
    }
  }

  void _takeAssessment(AssessmentType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClinicalAssessmentScreen(assessmentType: type),
      ),
    );
  }
}

/// Summary card for each assessment type
class _SummaryCard extends StatelessWidget {
  final AssessmentType type;
  final AssessmentResult? latestAssessment;
  final int totalCount;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.type,
    required this.latestAssessment,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color severityColor = colorScheme.onSurfaceVariant;
    if (latestAssessment != null) {
      switch (latestAssessment!.severity) {
        case SeverityLevel.none:
        case SeverityLevel.minimal:
          severityColor = Colors.green;
          break;
        case SeverityLevel.mild:
          severityColor = Colors.blue;
          break;
        case SeverityLevel.moderate:
          severityColor = Colors.orange;
          break;
        case SeverityLevel.moderatelySevere:
          severityColor = Colors.deepOrange;
          break;
        case SeverityLevel.severe:
          severityColor = Colors.red;
          break;
      }
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                type.shortName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (latestAssessment != null) ...[
                Text(
                  latestAssessment!.totalScore.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                Text(
                  latestAssessment!.severity.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '$totalCount total',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Take',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
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

/// Individual assessment list tile
class _AssessmentListTile extends StatelessWidget {
  final AssessmentResult assessment;

  const _AssessmentListTile({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color severityColor;
    switch (assessment.severity) {
      case SeverityLevel.none:
      case SeverityLevel.minimal:
        severityColor = Colors.green;
        break;
      case SeverityLevel.mild:
        severityColor = Colors.blue;
        break;
      case SeverityLevel.moderate:
        severityColor = Colors.orange;
        break;
      case SeverityLevel.moderatelySevere:
        severityColor = Colors.deepOrange;
        break;
      case SeverityLevel.severe:
        severityColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  assessment.totalScore.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                Text(
                  assessment.severity.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        title: Text(assessment.type.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    assessment.severity.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(assessment.completedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showAssessmentDetails(context, assessment);
        },
      ),
    );
  }

  void _showAssessmentDetails(BuildContext context, AssessmentResult assessment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssessmentResultScreen(result: assessment),
      ),
    );
  }
}
