import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mentor_me/models/journal_template.dart';
import 'package:mentor_me/models/structured_journaling_session.dart';
import 'package:mentor_me/models/chat_message.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/models/ai_provider.dart';
import 'package:mentor_me/providers/journal_template_provider.dart';
import 'package:mentor_me/providers/journal_provider.dart';
import 'package:mentor_me/providers/goal_provider.dart';
import 'package:mentor_me/providers/habit_provider.dart';
import 'package:mentor_me/services/structured_journaling_service.dart';
import 'package:mentor_me/services/ai_service.dart';
import 'package:mentor_me/services/debug_service.dart';
import 'package:mentor_me/services/storage_service.dart';
import 'package:mentor_me/theme/app_spacing.dart';
import 'package:mentor_me/screens/template_settings_screen.dart';

class StructuredJournalingScreen extends StatefulWidget {
  final JournalTemplate? template;
  final StructuredJournalingSession? existingSession;

  const StructuredJournalingScreen({
    super.key,
    this.template,
    this.existingSession,
  });

  @override
  State<StructuredJournalingScreen> createState() =>
      _StructuredJournalingScreenState();
}

class _StructuredJournalingScreenState extends State<StructuredJournalingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _service = StructuredJournalingService();
  final _debug = DebugService();

  JournalTemplate? _selectedTemplate;
  StructuredJournalingSession? _currentSession;
  bool _isTyping = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingSession != null) {
      _currentSession = widget.existingSession;
      _selectedTemplate = context
          .read<JournalTemplateProvider>()
          .getTemplateById(widget.existingSession!.templateId);
    } else if (widget.template != null) {
      _selectedTemplate = widget.template;
      _startNewSession();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startNewSession() async {
    if (_selectedTemplate == null) return;

    final provider = context.read<JournalTemplateProvider>();
    final session = await provider.startSession(_selectedTemplate!);

    setState(() {
      _currentSession = session;
    });

    // Send the first AI message to start the conversation
    await _sendInitialMessage();
  }

  Future<void> _sendInitialMessage() async {
    if (_selectedTemplate == null || _currentSession == null) return;

    setState(() {
      _isTyping = true;
    });

    try {
      // Use compact mode for local AI to avoid context overflow
      final aiService = AIService();
      final isLocalAI = aiService.getProvider() == AIProvider.local;

      final systemPrompt = _service.generateSystemPrompt(
        _selectedTemplate!,
        _currentSession!.currentStep ?? 0,
        useCompactMode: isLocalAI,
      );

      // Combine system prompt with user prompt
      final fullPrompt = '$systemPrompt\n\nStart the journaling session. Greet the user warmly and ask the first question.';

      // Get user's goals and habits for context
      final goals = context.read<GoalProvider>().goals;
      final habits = context.read<HabitProvider>().habits;

      final response = await AIService().getCoachingResponse(
        prompt: fullPrompt,
        goals: goals,
        habits: habits,
      );

      final aiMessage = ChatMessage(
        content: response,
        sender: MessageSender.mentor,
        timestamp: DateTime.now(),
      );

      final updatedSession = _currentSession!.copyWith(
        conversation: [..._currentSession!.conversation, aiMessage],
        currentStep: 0,
      );

      await context.read<JournalTemplateProvider>().updateSession(updatedSession);

      setState(() {
        _currentSession = updatedSession;
      });

      _scrollToBottom();
    } catch (e, stackTrace) {
      await _debug.error(
        'StructuredJournalingScreen',
        'Failed to send initial message',
        
        stackTrace: stackTrace.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start session. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _isTyping = false;
      });
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentSession == null || _selectedTemplate == null) {
      return;
    }

    _messageController.clear();

    // Add user message
    final userMessage = ChatMessage(
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    final updatedConversation = [..._currentSession!.conversation, userMessage];
    var updatedSession = _currentSession!.copyWith(
      conversation: updatedConversation,
    );

    await context.read<JournalTemplateProvider>().updateSession(updatedSession);

    setState(() {
      _currentSession = updatedSession;
      _isTyping = true;
    });

    _scrollToBottom();

    // Generate AI response
    try {
      final currentStep = _currentSession!.currentStep ?? 0;
      final nextStep = currentStep + 1;

      // Use compact mode for local AI to avoid context overflow
      final aiService = AIService();
      final isLocalAI = aiService.getProvider() == AIProvider.local;

      final systemPrompt = _service.generateSystemPrompt(
        _selectedTemplate!,
        nextStep,
        useCompactMode: isLocalAI,
      );

      // Build conversation context
      final conversationContext = _currentSession!.conversation
          .map((m) => '${m.sender.name}: ${m.content}')
          .join('\n');

      final isComplete = nextStep >= _selectedTemplate!.fields.length;

      final prompt = isComplete
          ? 'The user has completed all fields. Provide a warm summary and closing message.'
          : 'Continue the conversation. Move to the next question.';

      // Combine system prompt with conversation context
      final fullPrompt = '$systemPrompt\n\n$prompt\n\nConversation so far:\n$conversationContext';

      // Get user's goals and habits for context
      final goals = context.read<GoalProvider>().goals;
      final habits = context.read<HabitProvider>().habits;

      final response = await AIService().getCoachingResponse(
        prompt: fullPrompt,
        goals: goals,
        habits: habits,
      );

      final aiMessage = ChatMessage(
        content: response,
        sender: MessageSender.mentor,
        timestamp: DateTime.now(),
      );

      updatedSession = updatedSession.copyWith(
        conversation: [...updatedSession.conversation, aiMessage],
        currentStep: nextStep,
        isComplete: isComplete,
      );

      await context.read<JournalTemplateProvider>().updateSession(updatedSession);

      setState(() {
        _currentSession = updatedSession;
      });

      _scrollToBottom();

      // If complete, show save option
      if (isComplete) {
        _showSaveDialog();
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'StructuredJournalingScreen',
        'Failed to generate AI response',

        stackTrace: stackTrace.toString(),
      );

      if (mounted) {
        // Check if session should be complete (even though AI failed)
        final currentStep = _currentSession!.currentStep ?? 0;
        final nextStep = currentStep + 1;
        final shouldBeComplete = nextStep >= _selectedTemplate!.fields.length;

        if (shouldBeComplete) {
          // Mark session as complete even though AI failed
          final completedSession = updatedSession.copyWith(isComplete: true);
          await context.read<JournalTemplateProvider>().updateSession(completedSession);

          setState(() {
            _currentSession = completedSession;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session complete! AI response failed but you can still save.'),
              duration: Duration(seconds: 3),
            ),
          );

          // Show save dialog anyway
          _showSaveDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to get response. Please try again.'),
              action: _canManuallyComplete()
                  ? SnackBarAction(
                      label: 'Complete Anyway',
                      onPressed: () => _manuallyCompleteSession(),
                    )
                  : null,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  /// Check if the session has answered enough required fields to allow manual completion
  bool _canManuallyComplete() {
    if (_currentSession == null || _selectedTemplate == null) return false;
    if (_currentSession!.isComplete) return false;

    // Count user messages (responses to questions)
    final userMessageCount = _currentSession!.conversation
        .where((msg) => msg.sender == MessageSender.user)
        .length;

    // Count required fields
    final requiredFieldCount = _selectedTemplate!.fields
        .where((field) => field.required)
        .length;

    // Can complete if user has answered at least all required fields
    return userMessageCount >= requiredFieldCount;
  }

  /// Manually mark session as complete and show save dialog
  Future<void> _manuallyCompleteSession() async {
    if (_currentSession == null) return;

    final updatedSession = _currentSession!.copyWith(
      isComplete: true,
    );

    await context.read<JournalTemplateProvider>().updateSession(updatedSession);

    setState(() {
      _currentSession = updatedSession;
    });

    _showSaveDialog();
  }

  Future<void> _saveSession() async {
    if (_currentSession == null || _selectedTemplate == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Extract structured data
      final structuredData = await _service.extractStructuredData(
        _selectedTemplate!,
        _currentSession!.conversation,
      );

      // Update session with extracted data
      final finalSession = _currentSession!.copyWith(
        extractedData: structuredData,
        isComplete: true,
      );

      await context.read<JournalTemplateProvider>().updateSession(finalSession);

      // Generate a summary of the conversation for the journal entry content
      final conversationSummary = _generateConversationSummary();

      // Create journal entry with summary content
      final journalEntry = JournalEntry(
        type: JournalEntryType.structuredJournal,
        structuredSessionId: finalSession.id,
        structuredData: structuredData,
        content: conversationSummary, // Summary for journal list view and mentor context
        createdAt: finalSession.createdAt,
      );

      await context.read<JournalProvider>().addEntry(journalEntry);

      await _debug.info(
        'StructuredJournalingScreen',
        'Saved structured journal entry',
        metadata: {
          'templateId': _selectedTemplate!.id,
          'sessionId': finalSession.id,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry saved!')),
        );

        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'StructuredJournalingScreen',
        'Failed to save session',

        stackTrace: stackTrace.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save entry. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Generate a readable summary of the conversation for journal list view and mentor context
  String _generateConversationSummary() {
    if (_currentSession == null || _selectedTemplate == null) {
      return '';
    }

    final buffer = StringBuffer();

    // Add template name as header
    buffer.writeln('${_selectedTemplate!.emoji ?? ''} ${_selectedTemplate!.name}'.trim());
    buffer.writeln();

    // Get user messages only (these contain the actual journal content)
    final userMessages = _currentSession!.conversation
        .where((msg) => msg.sender == MessageSender.user)
        .toList();

    // Create a readable summary of user responses
    for (int i = 0; i < userMessages.length; i++) {
      final message = userMessages[i];

      // Try to match with template fields to add context
      if (i < _selectedTemplate!.fields.length) {
        final field = _selectedTemplate!.fields[i];
        // Use the prompt (actual question) instead of label for better readability
        buffer.writeln('${field.prompt}');
        buffer.writeln(message.content);
      } else {
        // Fallback if we have more messages than fields
        buffer.writeln(message.content);
      }

      if (i < userMessages.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete'),
        content: const Text(
          'You\'ve completed all the questions! Would you like to save this journal entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveSession();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Session?'),
        content: const Text(
          'Are you sure you want to discard this journaling session? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_currentSession != null) {
                await context
                    .read<JournalTemplateProvider>()
                    .deleteSession(_currentSession!.id);
              }
              if (mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close screen
              }
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Session'),
              onTap: () {
                Navigator.pop(context);
                _exportSession();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSession() async {
    if (_currentSession == null || _selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No session to export')),
      );
      return;
    }

    if (_currentSession!.conversation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to export')),
      );
      return;
    }

    try {
      // Format session as text
      final buffer = StringBuffer();
      buffer.writeln('1-to-1 Mentor Session Export');
      buffer.writeln('Session: ${_selectedTemplate!.emoji ?? ''} ${_selectedTemplate!.name}'.trim());
      buffer.writeln('Created: ${_currentSession!.createdAt.toString().substring(0, 19)}');
      buffer.writeln('Status: ${_currentSession!.isComplete ? 'Complete' : 'In Progress'}');
      buffer.writeln('Messages: ${_currentSession!.conversation.length}');
      buffer.writeln();
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final message in _currentSession!.conversation) {
        final sender = message.sender == MessageSender.user ? 'You' : 'Mentor';
        final timestamp = message.timestamp.toString().substring(11, 16);
        buffer.writeln('[$timestamp] $sender:');
        buffer.writeln(message.content);
        buffer.writeln();
      }

      // Share using share_plus
      await Share.share(
        buffer.toString(),
        subject: '1-to-1 Session: ${_selectedTemplate!.name}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTemplate == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('1-to-1 Mentor Session')),
        body: _buildTemplateSelection(),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            if (_selectedTemplate!.emoji != null)
              Text(_selectedTemplate!.emoji!, style: const TextStyle(fontSize: 24)),
            if (_selectedTemplate!.emoji != null) AppSpacing.gapHorizontalSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTemplate!.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_selectedTemplate!.showProgressIndicator &&
                      _currentSession != null)
                    Text(
                      'Step ${(_currentSession!.currentStep ?? 0) + 1} of ${_selectedTemplate!.fields.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_currentSession != null && !_currentSession!.isComplete) ...[
            // Show manual complete button when user has answered enough fields
            if (_canManuallyComplete())
              FilledButton.icon(
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Complete'),
                onPressed: _manuallyCompleteSession,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDiscardDialog,
              tooltip: 'Discard',
            ),
          ],
          if (_currentSession != null && _currentSession!.isComplete)
            FilledButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, size: 18),
              label: const Text('Save'),
              onPressed: _isSaving ? null : _saveSession,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
              ),
            ),
          if (_currentSession != null && _currentSession!.conversation.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMenu,
              tooltip: 'More options',
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _currentSession == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 24),
                          Text(
                            'Starting your session...',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your AI mentor is preparing personalized questions',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount:
                        _currentSession!.conversation.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _currentSession!.conversation.length) {
                        return _buildTypingIndicator();
                      }

                      final message = _currentSession!.conversation[index];
                      return _buildMessageBubble(context, message);
                    },
                  ),
          ),

          // Input field
          if (_currentSession != null && !_currentSession!.isComplete)
            _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildTemplateSelection() {
    final aiService = AIService();
    final hasAI = aiService.isAvailable(); // Check currently selected provider
    final currentProvider = aiService.getProvider();
    final storage = StorageService();

    return Consumer<JournalTemplateProvider>(
      builder: (context, provider, child) {
        final allTemplates = provider.allTemplates;

        if (allTemplates.isEmpty) {
          return const Center(
            child: Text('No templates available'),
          );
        }

        // Load enabled templates and filter
        return FutureBuilder<List<String>>(
          future: storage.getEnabledTemplates(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final enabledIds = snapshot.data!;
            final templates = allTemplates
                .where((t) => enabledIds.contains(t.id))
                .toList();

            return Column(
              children: [
                // AI availability warning
                if (!hasAI)
                  Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        AppSpacing.gapHorizontalSm,
                        Expanded(
                          child: Text(
                            currentProvider == AIProvider.cloud
                                ? 'AI is not available. Please set up your Claude API key in Settings to use 1-to-1 Mentor Sessions.'
                                : 'Local AI model not downloaded. Please download the model in Settings to use 1-to-1 Mentor Sessions.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Info banner about enabled templates
                Container(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      AppSpacing.gapHorizontalSm,
                      Expanded(
                        child: Text(
                          'Showing ${templates.length} of ${allTemplates.length} templates',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TemplateSettingsScreen(),
                            ),
                          );
                          // Rebuild to refresh template list after returning from settings
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Manage'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),

                // Template list
                Expanded(
                  child: templates.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                AppSpacing.gapLg,
                                Text(
                                  'No templates enabled',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                AppSpacing.gapSm,
                                Text(
                                  'Enable templates in Settings to start journaling',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                AppSpacing.gapLg,
                                FilledButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TemplateSettingsScreen(),
                                      ),
                                    );
                                    // Rebuild to refresh template list after returning from settings
                                    if (mounted) setState(() {});
                                  },
                                  icon: const Icon(Icons.settings),
                                  label: const Text('Manage Templates'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg + 80, // Extra bottom padding to clear nav bar
                          ),
                          itemCount: templates.length,
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: ListTile(
                                enabled: hasAI, // Disable if no AI
                                leading: template.emoji != null
                                    ? Text(template.emoji!,
                                        style: const TextStyle(fontSize: 32))
                                    : const Icon(Icons.article),
                                title: Text(template.name),
                                subtitle: Text(template.description),
                                trailing: hasAI
                                    ? const Icon(Icons.arrow_forward)
                                    : Icon(Icons.lock,
                                        color: Theme.of(context).colorScheme.outline),
                                onTap: hasAI
                                    ? () {
                                        setState(() {
                                          _selectedTemplate = template;
                                        });
                                        _startNewSession();
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.psychology,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            AppSpacing.gapHorizontalSm,
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppRadius.lg),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content.replaceAll('\\n', '\n'), // Convert literal \n to actual newlines
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        strong: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        em: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            AppSpacing.gapHorizontalSm,
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.psychology,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          AppSpacing.gapHorizontalSm,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                AppSpacing.gapHorizontalXs,
                _buildTypingDot(200),
                AppSpacing.gapHorizontalXs,
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delayMs) {
    return _AnimatedDot(delay: Duration(milliseconds: delayMs));
  }

  Widget _buildMessageInput(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your response...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            AppSpacing.gapHorizontalSm,
            FilledButton(
              onPressed: _isTyping ? null : _sendMessage,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated dot widget for typing indicator
class _AnimatedDot extends StatefulWidget {
  final Duration delay;

  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
