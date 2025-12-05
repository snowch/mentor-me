// lib/screens/chat_screen.dart
// Phase 3: Conversational Interface - Chat UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/chat_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/pulse_provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/food_log_provider.dart';
import '../providers/win_provider.dart';
import '../models/chat_message.dart';
import '../models/journal_entry.dart';
import '../models/mentor_message.dart';
import '../models/ai_provider.dart';
import '../models/win.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';
import '../services/feature_discovery_service.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatScreen({super.key, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Pre-fill message if provided
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }

    // Track that user has discovered chat feature
    FeatureDiscoveryService().markChatOpened();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    if (text.isEmpty) return;

    _messageController.clear();

    final chatProvider = context.read<ChatProvider>();
    final goalProvider = context.read<GoalProvider>();
    final habitProvider = context.read<HabitProvider>();
    final journalProvider = context.read<JournalProvider>();
    final pulseProvider = context.read<PulseProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();
    final weightProvider = context.read<WeightProvider>();
    final foodLogProvider = context.read<FoodLogProvider>();

    // Send user message (adds to conversation, sets typing state)
    await chatProvider.sendUserMessage(text, skipAutoResponse: true);
    _scrollToBottom();

    // Generate contextual AI response with full user context
    try {
      final response = await chatProvider.generateContextualResponse(
        userMessage: text,
        goals: goalProvider.goals,
        habits: habitProvider.habits,
        journalEntries: journalProvider.entries,
        pulseEntries: pulseProvider.entries,
        exercisePlans: exerciseProvider.plans,
        workoutLogs: exerciseProvider.workoutLogs,
        weightEntries: weightProvider.entries,
        weightGoal: weightProvider.goal,
        foodEntries: foodLogProvider.entries,
        nutritionGoal: foodLogProvider.goal,
      );

      await chatProvider.addMentorMessage(response);
      _scrollToBottom();
    } catch (e) {
      // Error already handled in provider
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            AppSpacing.gapHorizontalMd,
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.yourMentor,
                  style: TextStyle(fontSize: 16),
                ),
                const Text(
                  'Here to help',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading model indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (!chatProvider.isLoadingModel) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    AppSpacing.gapHorizontalSm,
                    Text(
                      chatProvider.loadingMessage ?? 'Loading...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              );
            },
          ),

          // AI Provider Privacy Indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final isCloudAi = chatProvider.currentAiProvider == AIProvider.cloud;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isCloudAi
                      ? Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: (isCloudAi
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.primary)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCloudAi ? Icons.cloud_outlined : Icons.phone_android,
                      size: 14,
                      color: isCloudAi
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCloudAi ? AppStrings.usingCloudAi : AppStrings.usingLocalAi,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isCloudAi
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    if (isCloudAi) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 12,
                        color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.messages;

                if (messages.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  itemCount: messages.length + (chatProvider.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      // Typing indicator
                      return _buildTypingIndicator(key: const ValueKey('typing_indicator'));
                    }

                    final message = messages[index];
                    return _buildMessageBubble(
                      context,
                      message,
                      key: ValueKey(message.id),
                    );
                  },
                );
              },
            ),
          ),

          // Input field
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            AppSpacing.gapLg,
            Text(
              'Start a conversation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AppSpacing.gapSm,
            Text(
              'Ask me about your goals, get advice, or just chat!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildSuggestionChip(context, 'How am I doing overall?'),
                _buildSuggestionChip(context, 'What should I focus on today?'),
                _buildSuggestionChip(context, 'Why am I not making progress?'),
                _buildSuggestionChip(context, 'Help me reflect on my week'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      ),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, {Key? key}) {
    final isUser = message.isFromUser;

    return Padding(
      key: key,
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
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                // Action buttons (only for mentor messages)
                if (message.hasSuggestedActions) ...[
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: message.suggestedActions!.map((action) {
                      return _buildActionButton(context, action);
                    }).toList(),
                  ),
                ],
              ],
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

  Widget _buildTypingIndicator({Key? key}) {
    return Padding(
      key: key,
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final isProcessing = chatProvider.isTyping || chatProvider.isLoadingModel;

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
                  color: Colors.black.withValues(alpha: 0.05),
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
                    enabled: !isProcessing,
                    decoration: InputDecoration(
                      hintText: isProcessing
                          ? 'AI is thinking...'
                          : 'Message your mentor...',
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
                    onSubmitted: isProcessing ? null : (_) => _sendMessage(),
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                IconButton.filled(
                  onPressed: isProcessing ? null : _sendMessage,
                  icon: isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, MentorAction action) {
    return FilledButton.tonal(
      onPressed: () => _handleAction(context, action),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getActionIcon(action.type), size: 18),
          AppSpacing.gapHorizontalXs,
          Text(action.label),
        ],
      ),
    );
  }

  IconData _getActionIcon(MentorActionType type) {
    switch (type) {
      case MentorActionType.navigate:
        return Icons.arrow_forward;
      case MentorActionType.chat:
        return Icons.chat;
      case MentorActionType.quickAction:
        return Icons.check_circle_outline;
    }
  }

  void _handleAction(BuildContext context, MentorAction action) {
    switch (action.type) {
      case MentorActionType.navigate:
        if (action.destination != null) {
          Navigator.pushNamed(
            context,
            action.destination!,
            arguments: action.context,
          );
        }
        break;
      case MentorActionType.chat:
        if (action.chatPreFill != null) {
          _messageController.text = action.chatPreFill!;
        }
        break;
      case MentorActionType.quickAction:
        // Handle quick actions based on context
        final actionType = action.context?['action'] as String?;
        if (actionType == 'record_win') {
          _handleRecordWin(context, action.context!);
        }
        break;
    }
  }

  /// Handle the record_win quick action
  Future<void> _handleRecordWin(BuildContext context, Map<String, dynamic> winContext) async {
    final description = winContext['description'] as String? ?? '';
    final category = winContext['category'] as String? ?? 'personal';

    // Show confirmation dialog to let user edit the win description
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _RecordWinDialog(
        initialDescription: description,
        initialCategory: category,
      ),
    );

    if (result != null && mounted) {
      try {
        final winProvider = context.read<WinProvider>();

        // Parse category
        WinCategory? winCategory;
        try {
          winCategory = WinCategory.values.firstWhere(
            (c) => c.name.toLowerCase() == (result['category'] as String).toLowerCase(),
          );
        } catch (e) {
          winCategory = WinCategory.personal;
        }

        await winProvider.recordWin(
          description: result['description'] as String,
          source: WinSource.manual, // From chat, treated as manual
          category: winCategory,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Win recorded!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View Wins',
                textColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () {
                  Navigator.pushNamed(context, '/wins');
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to record win: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveAsJournal() async {
    final chatProvider = context.read<ChatProvider>();
    final goalProvider = context.read<GoalProvider>();
    final journalProvider = context.read<JournalProvider>();

    try {
      // Get formatted conversation content and linked goals
      final result = chatProvider.saveConversationAsJournal(
        goals: goalProvider.goals,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No messages to save')),
          );
        }
        return;
      }

      // Create journal entry
      final journalEntry = JournalEntry(
        type: JournalEntryType.quickNote,
        content: result['content'] as String,
        goalIds: result['goalIds'] as List<String>,
      );

      await journalProvider.addEntry(journalEntry);

      if (mounted) {
        final goalCount = (result['goalIds'] as List<String>).length;
        final message = goalCount > 0
            ? 'Saved to journal and linked to $goalCount goal${goalCount > 1 ? 's' : ''}!'
            : 'Saved to journal!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => Navigator.pushNamed(context, '/journal'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _exportChat() async {
    final chatProvider = context.read<ChatProvider>();
    final conversation = chatProvider.currentConversation;

    if (conversation == null || conversation.messages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No messages to export')),
        );
      }
      return;
    }

    try {
      // Format conversation as text
      final buffer = StringBuffer();
      buffer.writeln('Chat Export');
      buffer.writeln('Title: ${conversation.title}');
      buffer.writeln('Created: ${conversation.createdAt.toString().substring(0, 19)}');
      buffer.writeln('Messages: ${conversation.messages.length}');
      buffer.writeln();
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final message in conversation.messages) {
        final sender = message.isFromUser ? 'You' : 'Mentor';
        final timestamp = message.timestamp.toString().substring(11, 16);
        buffer.writeln('[$timestamp] $sender:');
        buffer.writeln(message.content);
        buffer.writeln();
      }

      // Use share_plus to share the text
      await Share.share(
        buffer.toString(),
        subject: 'Chat: ${conversation.title}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat exported successfully!')),
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

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Start New Conversation'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().startNewConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Save to Journal'),
              subtitle: const Text('Save this conversation as a journal entry'),
              onTap: () {
                Navigator.pop(context);
                _saveAsJournal();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Current Chat'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().clearCurrentConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Chat'),
              onTap: () {
                Navigator.pop(context);
                _exportChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Conversation History'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to conversation history screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
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
                .withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Dialog for recording a win from chat
class _RecordWinDialog extends StatefulWidget {
  final String initialDescription;
  final String initialCategory;

  const _RecordWinDialog({
    required this.initialDescription,
    required this.initialCategory,
  });

  @override
  State<_RecordWinDialog> createState() => _RecordWinDialogState();
}

class _RecordWinDialogState extends State<_RecordWinDialog> {
  late TextEditingController _descriptionController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.emoji_events,
            color: Theme.of(context).colorScheme.primary,
          ),
          AppSpacing.gapHorizontalMd,
          const Text('Record Win'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe your accomplishment:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.gapSm,
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What did you achieve?',
                border: OutlineInputBorder(),
              ),
            ),
            AppSpacing.gapLg,
            Text(
              'Category:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            AppSpacing.gapSm,
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'personal', child: Text('Personal')),
                DropdownMenuItem(value: 'health', child: Text('Health')),
                DropdownMenuItem(value: 'fitness', child: Text('Fitness')),
                DropdownMenuItem(value: 'career', child: Text('Career')),
                DropdownMenuItem(value: 'learning', child: Text('Learning')),
                DropdownMenuItem(value: 'relationships', child: Text('Relationships')),
                DropdownMenuItem(value: 'finance', child: Text('Finance')),
                DropdownMenuItem(value: 'habit', child: Text('Habit')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final description = _descriptionController.text.trim();
            if (description.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a description')),
              );
              return;
            }
            Navigator.pop(context, {
              'description': description,
              'category': _selectedCategory,
            });
          },
          child: const Text('Record Win'),
        ),
      ],
    );
  }
}
