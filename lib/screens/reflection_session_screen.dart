import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_strings.dart';
import '../models/reflection_session.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../providers/goal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/pulse_provider.dart';
import '../providers/checkin_template_provider.dart';
import '../services/reflection_session_service.dart';
import '../services/reflection_analysis_service.dart';
import '../services/reflection_action_service.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/intervention_card_widget.dart';
import '../widgets/action_confirmation_dialog.dart';

/// Screen for conducting AI-driven reflection sessions.
///
/// This screen provides a conversational interface where the AI mentor
/// guides users through deep reflection, identifies patterns, and
/// suggests evidence-based interventions.
class ReflectionSessionScreen extends StatefulWidget {
  final ReflectionSessionType sessionType;
  final String? linkedGoalId;

  const ReflectionSessionScreen({
    super.key,
    this.sessionType = ReflectionSessionType.general,
    this.linkedGoalId,
  });

  @override
  State<ReflectionSessionScreen> createState() =>
      _ReflectionSessionScreenState();
}

class _ReflectionSessionScreenState extends State<ReflectionSessionScreen> {
  final _sessionService = ReflectionSessionService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  // Session state
  ReflectionSession? _session;
  SessionPhase _phase = SessionPhase.loading;
  String _currentQuestion = '';
  String? _sessionId;
  bool _isLoading = false;
  bool _showCrisisResources = false;

  // Analysis results
  ReflectionAnalysis? _analysis;
  Intervention? _selectedIntervention;

  // Agentic action tracking
  final List<ProposedAction> _proposedActions = [];
  final List<ExecutedAction> _executedActions = [];
  ReflectionActionService? _actionService;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _phase = SessionPhase.loading;
      _isLoading = true;
    });

    // Check if Claude AI is configured - mandatory for reflection sessions
    final aiService = AIService();
    if (!aiService.hasApiKey()) {
      setState(() {
        _phase = SessionPhase.noAi;
        _isLoading = false;
      });
      return;
    }

    // Initialize ReflectionActionService with providers
    _actionService = ReflectionActionService(
      goalProvider: context.read<GoalProvider>(),
      habitProvider: context.read<HabitProvider>(),
      journalProvider: context.read<JournalProvider>(),
      templateProvider: context.read<CheckInTemplateProvider>(),
      notificationService: NotificationService(),
    );

    // Inject action service into session service
    _sessionService.setActionService(_actionService!);

    final goals = context.read<GoalProvider>().goals;
    final habits = context.read<HabitProvider>().habits;
    final journals = context.read<JournalProvider>().entries;
    final pulse = context.read<PulseProvider>().entries;

    try {
      final result = await _sessionService.startSession(
        type: widget.sessionType,
        linkedGoalId: widget.linkedGoalId,
        goals: goals,
        habits: habits,
        recentJournals: journals.take(5).toList(),
        recentPulse: pulse.take(3).toList(),
      );

      setState(() {
        _sessionId = result.sessionId;
        _session = ReflectionSession(
          id: result.sessionId,
          startedAt: DateTime.now(),
          type: result.type,
          linkedGoalId: result.linkedGoalId,
        );
        _currentQuestion = '${result.greeting}\n\n${result.openingQuestion}';
        _phase = SessionPhase.conversation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _phase = SessionPhase.error;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitResponse() async {
    final response = _textController.text.trim();
    if (response.isEmpty || _isLoading) return;

    // Check for crisis indicators
    if (_sessionService.checkForCrisisIndicators(response)) {
      setState(() => _showCrisisResources = true);
    }

    // Store the current question before it gets updated
    final currentQuestionForExchange = _currentQuestion;

    setState(() => _isLoading = true);
    _textController.clear();

    // Decide whether to continue conversation or move to analysis
    if (_session!.exchanges.length >= 4) {
      // After 5th response (4 existing + 1 new), move to analysis
      // Add the final exchange before analysis
      final newExchange = ReflectionExchange(
        mentorQuestion: currentQuestionForExchange,
        userResponse: response,
        sequenceOrder: _session!.exchanges.length,
      );

      final updatedExchanges = [..._session!.exchanges, newExchange];
      setState(() {
        _session = _session!.copyWith(exchanges: updatedExchanges);
      });

      await _performAnalysis();
    } else {
      // Generate follow-up question (with potential actions)
      try {
        final followUpResult = await _sessionService.generateFollowUp(
          previousExchanges: _session!.exchanges,
          latestResponse: response,
          type: widget.sessionType,
        );

        final message = followUpResult['message'] as String;
        final proposedActions = followUpResult['proposedActions'] as List<ProposedAction>;

        // NOW add the exchange with the completed Q&A pair
        final newExchange = ReflectionExchange(
          mentorQuestion: currentQuestionForExchange,
          userResponse: response,
          sequenceOrder: _session!.exchanges.length,
        );

        final updatedExchanges = [..._session!.exchanges, newExchange];

        setState(() {
          _session = _session!.copyWith(exchanges: updatedExchanges);
          _currentQuestion = message;
          _isLoading = false;
        });

        _scrollToBottom();

        // Handle proposed actions if any
        if (proposedActions.isNotEmpty && mounted) {
          await _handleProposedActions(proposedActions);
        }
      } catch (e) {
        // On error, still add the exchange but show error state
        final newExchange = ReflectionExchange(
          mentorQuestion: currentQuestionForExchange,
          userResponse: response,
          sequenceOrder: _session!.exchanges.length,
        );

        final updatedExchanges = [..._session!.exchanges, newExchange];

        setState(() {
          _session = _session!.copyWith(exchanges: updatedExchanges);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleProposedActions(List<ProposedAction> actions) async {
    for (final action in actions) {
      // Add to proposed actions list
      setState(() => _proposedActions.add(action));

      // Show confirmation dialog
      final approved = await ActionConfirmationDialog.show(context, action);

      if (approved && mounted && _actionService != null) {
        // Execute the action
        setState(() => _isLoading = true);

        try {
          final executedAction = await _sessionService.executeAction(action);

          setState(() {
            _executedActions.add(executedAction);
            _isLoading = false;
          });

          // Show success/failure feedback
          if (mounted) {
            final message = executedAction.success
                ? _getSuccessMessage(action.type)
                : 'Failed: ${executedAction.errorMessage ?? "Unknown error"}';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: executedAction.success
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          setState(() => _isLoading = false);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${AppStrings.errorExecutingAction}: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } else {
        // User declined - record as not executed
        final declinedAction = ExecutedAction(
          proposedActionId: action.id,
          type: action.type,
          description: action.description,
          parameters: action.parameters,
          confirmed: false,
          executedAt: DateTime.now(),
          success: false,
        );
        setState(() => _executedActions.add(declinedAction));
      }
    }
  }

  String _getSuccessMessage(ActionType type) {
    switch (type) {
      case ActionType.createGoal:
        return AppStrings.goalCreatedSuccessfully;
      case ActionType.createHabit:
        return AppStrings.habitCreatedSuccessfully;
      case ActionType.createMilestone:
        return AppStrings.milestoneAdded;
      case ActionType.createCheckInTemplate:
        return AppStrings.checkInTemplateCreated;
      case ActionType.moveGoalToBacklog:
        return AppStrings.goalMovedToBacklog;
      case ActionType.moveGoalToActive:
        return AppStrings.goalActivated;
      case ActionType.completeGoal:
        return AppStrings.goalMarkedComplete;
      case ActionType.saveSessionAsJournal:
        return AppStrings.sessionSavedToJournal;
      case ActionType.scheduleFollowUp:
        return AppStrings.followUpReminderScheduled;
      default:
        return AppStrings.actionCompletedSuccessfully;
    }
  }

  String _getActionDescription(ActionType type) {
    switch (type) {
      case ActionType.createGoal:
        return 'Created a new goal';
      case ActionType.updateGoal:
        return 'Updated goal';
      case ActionType.deleteGoal:
        return 'Deleted goal';
      case ActionType.moveGoalToActive:
        return 'Activated a goal';
      case ActionType.moveGoalToBacklog:
        return 'Moved goal to backlog';
      case ActionType.completeGoal:
        return 'Completed a goal';
      case ActionType.abandonGoal:
        return 'Abandoned a goal';
      case ActionType.createMilestone:
        return 'Added a milestone';
      case ActionType.updateMilestone:
        return 'Updated milestone';
      case ActionType.deleteMilestone:
        return 'Deleted milestone';
      case ActionType.completeMilestone:
        return 'Completed milestone';
      case ActionType.uncompleteMilestone:
        return 'Reopened milestone';
      case ActionType.createHabit:
        return 'Created a new habit';
      case ActionType.updateHabit:
        return 'Updated habit';
      case ActionType.deleteHabit:
        return 'Deleted habit';
      case ActionType.pauseHabit:
        return 'Paused habit';
      case ActionType.activateHabit:
        return 'Activated habit';
      case ActionType.archiveHabit:
        return 'Archived habit';
      case ActionType.markHabitComplete:
        return 'Marked habit complete for a day';
      case ActionType.unmarkHabitComplete:
        return 'Unmarked habit completion';
      case ActionType.createCheckInTemplate:
        return 'Created check-in template';
      case ActionType.scheduleCheckInReminder:
        return 'Scheduled check-in reminder';
      case ActionType.saveSessionAsJournal:
        return 'Saved session as journal entry';
      case ActionType.scheduleFollowUp:
        return 'Scheduled follow-up reminder';
    }
  }

  /// Generate formatted text version of the session for copying
  String _generateSessionText() {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('REFLECTION SESSION');
    buffer.writeln('=' * 50);
    buffer.writeln('Date: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('Type: ${widget.sessionType.name}');
    buffer.writeln();

    // Conversation
    buffer.writeln('CONVERSATION');
    buffer.writeln('-' * 50);
    for (var i = 0; i < _session!.exchanges.length; i++) {
      final exchange = _session!.exchanges[i];
      buffer.writeln();
      buffer.writeln('Q${i + 1}: ${exchange.mentorQuestion}');
      buffer.writeln();
      buffer.writeln('A${i + 1}: ${exchange.userResponse}');
      buffer.writeln();
    }

    // Analysis
    if (_analysis != null) {
      buffer.writeln();
      buffer.writeln('ANALYSIS');
      buffer.writeln('-' * 50);

      if (_analysis!.summary.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Summary:');
        buffer.writeln(_analysis!.summary);
      }

      if (_analysis!.patterns.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Patterns Detected:');
        for (final pattern in _analysis!.patterns) {
          buffer.writeln('• ${pattern.type.displayName}: ${pattern.description}');
        }
      }

      if (_analysis!.recommendations.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Recommended Practices:');
        for (final rec in _analysis!.recommendations) {
          buffer.writeln('• ${rec.name}');
          buffer.writeln('  ${rec.description}');
        }
      }

      if (_analysis!.affirmation.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Affirmation:');
        buffer.writeln(_analysis!.affirmation);
      }
    }

    // Actions
    if (_proposedActions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('ACTIONS SUGGESTED');
      buffer.writeln('-' * 50);
      for (final action in _proposedActions) {
        buffer.writeln('• ${action.description}');
      }
    }

    final acceptedActions = _executedActions.where((a) => a.confirmed && a.success).toList();
    if (acceptedActions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('ACTIONS ACCEPTED');
      buffer.writeln('-' * 50);
      for (final action in acceptedActions) {
        buffer.writeln('✓ ${action.description}');
      }
    }

    return buffer.toString();
  }

  /// Copy session to clipboard
  Future<void> _copySessionToClipboard() async {
    final text = _generateSessionText();
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _performAnalysis() async {
    setState(() {
      _phase = SessionPhase.analyzing;
      _isLoading = true;
    });

    try {
      final analysis = await _sessionService.analyzeSession(
        exchanges: _session!.exchanges,
      );

      setState(() {
        _analysis = analysis;
        _phase = SessionPhase.patterns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _phase = SessionPhase.error;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeSession() async {
    setState(() => _isLoading = true);

    // Create session outcome with executed actions
    final outcome = SessionOutcome(
      actionsProposed: _proposedActions,
      actionsExecuted: _executedActions,
      checkInTemplatesCreated: _executedActions
          .where((a) =>
              a.type == ActionType.createCheckInTemplate &&
              a.success &&
              a.resultId != null)
          .map((a) => a.resultId!)
          .toList(),
      sessionSummary: _analysis?.summary,
    );

    // Update session with outcome
    final updatedSession = _session!.copyWith(
      completedAt: DateTime.now(),
      outcome: outcome,
    );

    // Save session to journal
    final journalProvider = context.read<JournalProvider>();

    // Convert exchanges to QAPairs for guided journal format
    final qaPairs = updatedSession.exchanges
        .map((e) => QAPair(
              question: e.mentorQuestion,
              answer: e.userResponse,
            ))
        .toList();

    // Add summary as final Q&A pair
    final analysisService = ReflectionAnalysisService();
    final summary = analysisService.generateSessionSummary(
      updatedSession.exchanges,
      _analysis?.patterns ?? [],
      _analysis?.recommendations ?? [],
    );
    qaPairs.add(QAPair(
      question: 'Session Summary',
      answer: summary,
    ));

    // Add proposed actions summary if any actions were suggested
    if (_proposedActions.isNotEmpty) {
      final proposedSummary = _proposedActions
          .map((a) => '• ${a.description}')
          .join('\n');
      qaPairs.add(QAPair(
        question: 'Actions Suggested',
        answer: proposedSummary,
      ));
    }

    // Add accepted actions summary if actions were executed
    final acceptedActions = _executedActions.where((a) => a.confirmed && a.success).toList();
    if (acceptedActions.isNotEmpty) {
      final actionSummary = acceptedActions
          .map((a) => '✓ ${a.description}')
          .join('\n');
      qaPairs.add(QAPair(
        question: AppStrings.actionsTaken,
        answer: actionSummary,
      ));
    }

    // Add declined/failed actions summary if any
    final declinedActions = _executedActions.where((a) => !a.confirmed || !a.success).toList();
    if (declinedActions.isNotEmpty) {
      final declinedSummary = declinedActions
          .map((a) => '✗ ${a.description}${!a.success && a.errorMessage != null ? " (${a.errorMessage})" : ""}')
          .join('\n');
      qaPairs.add(QAPair(
        question: 'Actions Declined/Failed',
        answer: declinedSummary,
      ));
    }

    final journalEntry = JournalEntry(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      type: JournalEntryType.guidedJournal,
      reflectionType: 'reflection_session',
      qaPairs: qaPairs,
      goalIds: widget.linkedGoalId != null ? [widget.linkedGoalId!] : [],
    );

    await journalProvider.addEntry(journalEntry);

    // Create habit if intervention selected
    if (_selectedIntervention?.habitSuggestion != null) {
      final habitProvider = context.read<HabitProvider>();
      final habit = Habit(
        id: _uuid.v4(),
        title: _selectedIntervention!.habitSuggestion!,
        description:
            'Practice from reflection session: ${_selectedIntervention!.name}',
        createdAt: DateTime.now(),
        isSystemCreated: true,
        systemType: 'reflection_intervention',
        linkedGoalId: widget.linkedGoalId,
      );
      await habitProvider.addHabit(habit);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      // Show completion dialog with action summary
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(AppStrings.sessionComplete),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Affirmation
                Text(
                  _analysis?.affirmation ?? AppStrings.reflectionSaved,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),

                // Summary of what was saved
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Session Summary',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '• ${_session!.exchanges.length} conversation exchanges saved',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_analysis != null) ...[
                  Text(
                    '• ${_analysis!.patterns.length} patterns identified',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '• ${_analysis!.recommendations.length} practices recommended',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                // Actions summary
                if (_proposedActions.isNotEmpty || _executedActions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_proposedActions.isNotEmpty)
                    Text(
                      '• ${_proposedActions.length} actions suggested',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (acceptedActions.isNotEmpty)
                    Text(
                      '✓ ${acceptedActions.length} actions accepted',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],

                // Habit creation notice
                if (_selectedIntervention != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Habit created: "${_selectedIntervention!.habitSuggestion}"',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your reflection has been saved to your journal.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await _copySessionToClipboard();
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Session'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text(AppStrings.done),
            ),
          ],
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reflectionSession),
        actions: [
          if (_phase == SessionPhase.conversation && !_isLoading)
            TextButton(
              onPressed: _session!.exchanges.length >= 2
                  ? _performAnalysis
                  : null,
              child: const Text('Finish Early'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            if (_phase == SessionPhase.conversation)
              LinearProgressIndicator(
                value: _session!.exchanges.length / 5,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),

            // Main content
            Expanded(
              child: _buildContent(theme, colorScheme),
            ),

            // Crisis resources banner
            if (_showCrisisResources) _buildCrisisResourcesBanner(colorScheme),

            // Safety disclaimer at bottom
            if (_phase == SessionPhase.conversation)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  AppStrings.safetyDisclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    switch (_phase) {
      case SessionPhase.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text('Preparing your session...'),
            ],
          ),
        );

      case SessionPhase.noAi:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Claude AI Required',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Reflection sessions require Claude AI to provide personalized, '
                  'thoughtful guidance. Please configure your Claude API key in settings.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to AI settings would be ideal
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Go to Settings'),
                ),
              ],
            ),
          ),
        );

      case SessionPhase.conversation:
        return _buildConversationView(theme, colorScheme);

      case SessionPhase.analyzing:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text('Analyzing your responses...'),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Finding patterns and helpful practices',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        );

      case SessionPhase.patterns:
        return _buildPatternsView(theme, colorScheme);

      case SessionPhase.recommendations:
        return _buildRecommendationsView(theme, colorScheme);

      case SessionPhase.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Something went wrong'),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _startSession,
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildConversationView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Previous exchanges
              for (final exchange in _session!.exchanges) ...[
                _buildMentorBubble(exchange.mentorQuestion, theme, colorScheme),
                const SizedBox(height: AppSpacing.sm),
                _buildUserBubble(exchange.userResponse, theme, colorScheme),
                const SizedBox(height: AppSpacing.md),
              ],

              // Current question
              _buildMentorBubble(_currentQuestion, theme, colorScheme),

              if (_isLoading) ...[
                const SizedBox(height: AppSpacing.md),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: AppStrings.takeYourTime,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  onSubmitted: (_) => _submitResponse(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: _isLoading ? null : _submitResponse,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMentorBubble(
      String message, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(
            Icons.psychology,
            size: 18,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(width: 32), // Balance spacing
      ],
    );
  }

  Widget _buildUserBubble(
      String message, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 32), // Balance spacing
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primary,
          child: Icon(
            Icons.person,
            size: 18,
            color: colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternsView(ThemeData theme, ColorScheme colorScheme) {
    final patterns = _analysis?.patterns ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.summarize, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppStrings.sessionSummary,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _analysis?.summary ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Patterns section
          Text(
            AppStrings.patternsNoticed,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            patterns.isEmpty
                ? AppStrings.noPatternDetectedMessage
                : AppStrings.basedOnWhatYouShared,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (patterns.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                          'No concerning patterns detected. Let\'s look at some general wellness practices.'),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final pattern in patterns) ...[
              DetectedPatternWidget(pattern: pattern),
              const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.xl),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                setState(() => _phase = SessionPhase.recommendations);
              },
              child: const Text('See Recommended Practices'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsView(ThemeData theme, ColorScheme colorScheme) {
    final recommendations = _analysis?.recommendations ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.recommendedPractices,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.basedOnPatterns,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Intervention cards
          for (final intervention in recommendations) ...[
            InterventionCardWidget(
              intervention: intervention,
              isSelected: _selectedIntervention == intervention,
              onSelect: () {
                setState(() {
                  _selectedIntervention =
                      _selectedIntervention == intervention
                          ? null
                          : intervention;
                });
              },
              onCreateHabit: intervention.habitSuggestion != null
                  ? () {
                      setState(() => _selectedIntervention = intervention);
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Affirmation
          if (_analysis?.affirmation != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite, color: colorScheme.tertiary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _analysis!.affirmation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Complete session button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _completeSession,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_selectedIntervention != null
                      ? 'Complete & Create Habit'
                      : 'Complete Session'),
            ),
          ),

          if (_selectedIntervention == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Tip: Select a practice above to create a habit for it',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCrisisResourcesBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(Icons.warning, color: colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'If you\'re in crisis, please reach out for support.',
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: () => _showCrisisDialog(),
            child: const Text('Resources'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _showCrisisResources = false),
            color: colorScheme.onErrorContainer,
          ),
        ],
      ),
    );
  }

  void _showCrisisDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.crisisResourcesTitle),
        content: const Text(AppStrings.crisisResourcesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}

/// Phases of a reflection session
enum SessionPhase {
  loading,
  noAi,  // Claude AI not configured
  conversation,
  analyzing,
  patterns,
  recommendations,
  error,
}
