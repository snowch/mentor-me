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
import '../models/chat_message.dart';
import '../models/mentor_message.dart';
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
        // This can be extended as needed
        break;
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
                .withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
