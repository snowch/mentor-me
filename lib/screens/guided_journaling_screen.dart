// lib/screens/guided_journaling_screen.dart
// Guided reflection prompts for onboarding and check-ins
// When used as check-in (isCheckIn=true), shows scheduling after completion
// When used in onboarding (isCheckIn=false), navigates to goal suggestions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/habit_provider.dart';
import '../services/ai_service.dart';
import '../services/feature_discovery_service.dart';
import '../constants/app_strings.dart';
import 'goal_suggestions_screen.dart';

class GuidedJournalingScreen extends StatefulWidget {
  final bool isCheckIn;
  final bool isHaltCheck;

  const GuidedJournalingScreen({
    super.key,
    this.isCheckIn = false,
    this.isHaltCheck = false,
  });

  @override
  State<GuidedJournalingScreen> createState() => _GuidedJournalingScreenState();
}

class _GuidedJournalingScreenState extends State<GuidedJournalingScreen> {
  int _currentPromptIndex = 0;
  final List<TextEditingController> _controllers = [];
  final List<String> _responses = [];
  bool _isAnalyzing = false;
  bool _showCompletionScreen = false;
  String? _mentorFeedback;
  bool _isFetchingFeedback = false;

  // Prompts for initial onboarding (discovering goals)
  final List<ReflectionPrompt> _onboardingPrompts = [
    ReflectionPrompt(
      title: 'Where Are You Now?',
      prompt: 'Take a moment to reflect on your life right now. What\'s going well? What feels challenging?',
      hint: 'Be honest with yourself. This is just for you...',
      icon: Icons.location_on_outlined,
    ),
    ReflectionPrompt(
      title: 'What Matters Most?',
      prompt: 'When you imagine your ideal life 6 months from now, what has changed? What matters most to you?',
      hint: 'Health, relationships, career, personal growth...',
      icon: Icons.favorite_outline,
    ),
    ReflectionPrompt(
      title: 'What\'s Holding You Back?',
      prompt: 'Think about times you\'ve tried to make positive changes. What typically gets in the way?',
      hint: 'Time, energy, motivation, external factors...',
      icon: Icons.warning_amber_outlined,
    ),
    ReflectionPrompt(
      title: 'Your Why',
      prompt: 'Why do you want to grow and change? What would be different if you succeed?',
      hint: 'What drives you? What would success feel like?',
      icon: Icons.psychology_outlined,
    ),
  ];

  // Prompts for check-ins (tracking progress)
  final List<ReflectionPrompt> _checkInPrompts = [
    ReflectionPrompt(
      title: 'How Are Your Goals Going?',
      prompt: 'Think about the goals you\'re working on. Which ones are you making progress on? Which feel stuck?',
      hint: 'Be specific about what\'s working and what\'s not...',
      icon: Icons.flag_outlined,
    ),
    ReflectionPrompt(
      title: 'Habit Check',
      prompt: 'How are you doing with your daily habits? Which habits are you consistently completing? Which ones are you struggling with?',
      hint: 'Celebrate wins, acknowledge challenges...',
      icon: Icons.check_circle_outline,
    ),
    ReflectionPrompt(
      title: 'Wins & Challenges',
      prompt: 'What\'s one win (big or small) since your last check-in? What\'s been your biggest challenge?',
      hint: 'Progress isn\'t always linear...',
      icon: Icons.emoji_events_outlined,
    ),
    ReflectionPrompt(
      title: 'Next Steps',
      prompt: 'Looking ahead, what\'s one action you can take to move forward? What support or resources do you need?',
      hint: 'Small steps add up to big changes...',
      icon: Icons.arrow_forward_outlined,
    ),
  ];

  // HALT Check-In Prompts (Hungry, Angry, Lonely, Tired)
  final List<ReflectionPrompt> _haltPrompts = [
    ReflectionPrompt(
      title: 'Hungry - Physical Needs',
      prompt: 'Have you eaten recently? How\'s your physical energy and nourishment? Are you taking care of your basic physical needs?',
      hint: 'When did you last eat? How\'s your energy level?',
      icon: Icons.restaurant_outlined,
    ),
    ReflectionPrompt(
      title: 'Angry - Emotions',
      prompt: 'What\'s frustrating or irritating you right now? Are you feeling angry, annoyed, or resentful about anything?',
      hint: 'Be honest about what\'s bothering you...',
      icon: Icons.sentiment_dissatisfied_outlined,
    ),
    ReflectionPrompt(
      title: 'Lonely - Connection',
      prompt: 'Who have you connected with today? Are you feeling isolated or disconnected? How\'s your sense of belonging?',
      hint: 'Think about meaningful connections, not just interactions...',
      icon: Icons.people_outline,
    ),
    ReflectionPrompt(
      title: 'Tired - Rest & Energy',
      prompt: 'How\'s your sleep been? Are you running on empty? What\'s draining your energy right now?',
      hint: 'Physical tiredness, mental fatigue, emotional exhaustion...',
      icon: Icons.bedtime_outlined,
    ),
    ReflectionPrompt(
      title: 'What You Need',
      prompt: 'Based on these reflections, what\'s one thing you could do for yourself right now to address these needs?',
      hint: 'Small, actionable steps work best...',
      icon: Icons.self_improvement_outlined,
    ),
  ];

  late final List<ReflectionPrompt> _prompts;

  @override
  void initState() {
    super.initState();

    // Choose prompts based on the type of reflection
    if (widget.isHaltCheck) {
      // HALT check-in prompts
      _prompts = _haltPrompts;
    } else if (widget.isCheckIn) {
      // For check-ins, build prompts dynamically based on what user has set up
      _prompts = _buildCheckInPrompts();
    } else {
      // Onboarding prompts
      _prompts = _onboardingPrompts;
    }

    // Initialize controllers for the selected prompts
    for (int i = 0; i < _prompts.length; i++) {
      _controllers.add(TextEditingController());
      _responses.add('');
    }
  }

  /// Build check-in prompts dynamically based on user's setup
  List<ReflectionPrompt> _buildCheckInPrompts() {
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final journalProvider = Provider.of<JournalProvider>(context, listen: false);

    final hasGoals = goalProvider.goals.isNotEmpty;
    final hasHabits = habitProvider.habits.isNotEmpty;
    final isFirstReflection = journalProvider.entries.isEmpty;

    final prompts = <ReflectionPrompt>[];

    // Only ask about goals if user has goals - with specific goal names
    if (hasGoals) {
      final goalCount = goalProvider.goals.length;
      final goalNames = goalProvider.goals.take(3).map((g) => "'${g.title}'").join(', ');
      final moreGoals = goalCount > 3 ? ' and ${goalCount - 3} more' : '';

      // Adapt language for singular vs plural
      final String promptText;
      final String titleText;
      if (goalCount == 1) {
        titleText = 'How Is Your Goal Going?';
        promptText = 'Think about your goal: $goalNames. Are you making progress or does it feel stuck?';
      } else {
        titleText = 'How Are Your Goals Going?';
        promptText = 'Think about your goals: $goalNames$moreGoals. Which ones are you making progress on? Which feel stuck?';
      }

      prompts.add(ReflectionPrompt(
        title: titleText,
        prompt: promptText,
        hint: 'Be specific about what\'s working and what\'s not...',
        icon: Icons.flag_outlined,
      ));
    }

    // Only ask about habits if user has habits - with specific habit names
    if (hasHabits) {
      final habitCount = habitProvider.habits.length;
      final habitNames = habitProvider.habits.take(3).map((h) => "'${h.title}'").join(', ');
      final moreHabits = habitCount > 3 ? ' and ${habitCount - 3} more' : '';

      // Check if habits are newly created (within last hour)
      final now = DateTime.now();
      final hasNewHabits = habitProvider.habits.any((h) =>
        now.difference(h.createdAt).inHours < 1
      );

      // Check if it's just the auto-created "Daily Reflection" habit
      final isOnlyDailyReflection = habitCount == 1 &&
          habitProvider.habits.first.systemType == 'daily_reflection';

      // Adapt language for new vs established habits
      final String promptText;
      final String titleText;
      final String hintText;

      if (hasNewHabits && isOnlyDailyReflection) {
        // Special welcome for auto-created Daily Reflection habit
        titleText = 'Welcome to Daily Reflection!';
        promptText = 'This is your foundation habit for personal growth. Take a moment to reflect on your day. What\'s on your mind right now?';
        hintText = 'Your thoughts, feelings, or anything worth noting...';
      } else if (hasNewHabits) {
        // Ask about motivation for user-created habits
        if (habitCount == 1) {
          titleText = 'Welcome to Your New Habit!';
          promptText = 'You\'ve just started tracking $habitNames. What motivated you to begin this habit? What are you hoping to achieve?';
          hintText = 'Your intentions, hopes, or what inspired you...';
        } else {
          titleText = 'Welcome to Your New Habits!';
          promptText = 'You\'ve just started tracking $habitNames$moreHabits. What motivated you to begin these habits? What are you hoping to achieve?';
          hintText = 'Your intentions, hopes, or what inspired you...';
        }
      } else {
        // Progress check for established habits
        titleText = 'Habit Check';
        if (habitCount == 1) {
          promptText = 'How are you doing with your habit: $habitNames? Are you completing it consistently or struggling with it?';
        } else {
          promptText = 'How are you doing with your habits: $habitNames$moreHabits? Which ones are you consistently completing? Which ones are you struggling with?';
        }
        hintText = 'Celebrate wins, acknowledge challenges...';
      }

      prompts.add(ReflectionPrompt(
        title: titleText,
        prompt: promptText,
        hint: hintText,
        icon: Icons.check_circle_outline,
      ));
    }

    // Always include wins/challenges and next steps
    // Adapt "Wins & Challenges" prompt for first-time users
    if (isFirstReflection) {
      prompts.add(ReflectionPrompt(
        title: 'Wins & Challenges',
        prompt: 'What\'s one win (big or small) you\'ve had recently? What\'s been your biggest challenge?',
        hint: 'Progress isn\'t always linear...',
        icon: Icons.emoji_events_outlined,
      ));
    } else {
      prompts.add(_checkInPrompts[2]); // Wins & Challenges (with "since your last check-in")
    }
    prompts.add(_checkInPrompts[3]); // Next Steps

    // If user has neither goals nor habits, add a general reflection prompt
    if (!hasGoals && !hasHabits) {
      prompts.insert(0, ReflectionPrompt(
        title: 'How Are You Feeling?',
        prompt: 'Take a moment to check in with yourself. How are you feeling today? What\'s on your mind?',
        hint: 'Your thoughts, emotions, energy level...',
        icon: Icons.favorite_outline,
      ));
    }

    return prompts;
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _nextPrompt() async {
    if (_controllers[_currentPromptIndex].text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.pleaseWriteSomething),
        ),
      );
      return;
    }

    _responses[_currentPromptIndex] = _controllers[_currentPromptIndex].text;

    if (_currentPromptIndex < _prompts.length - 1) {
      setState(() => _currentPromptIndex++);
    } else {
      // Show completion screen for check-ins, finish immediately for onboarding
      if (widget.isCheckIn) {
        setState(() => _showCompletionScreen = true);
      } else {
        await _finishReflection();
      }
    }
  }

  void _previousPrompt() {
    if (_currentPromptIndex > 0) {
      setState(() => _currentPromptIndex--);
    }
  }

  Future<void> _getMentorFeedback() async {
    setState(() => _isFetchingFeedback = true);

    try {
      final goalProvider = Provider.of<GoalProvider>(context, listen: false);
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);

      // Build context for AI analysis
      final goalsContext = goalProvider.goals.isNotEmpty
          ? goalProvider.goals.map((g) => '- ${g.title}').join('\n')
          : 'No goals set yet';

      final habitsContext = habitProvider.habits.isNotEmpty
          ? habitProvider.habits.map((h) => '- ${h.title}').join('\n')
          : 'No habits set yet';

      // Build Q&A pairs for context
      final reflectionText = StringBuffer();
      for (int i = 0; i < _prompts.length; i++) {
        reflectionText.writeln('Q: ${_prompts[i].title}');
        reflectionText.writeln('A: ${_responses[i]}');
        reflectionText.writeln();
      }

      // Create prompt for AI
      final prompt = '''You are a supportive mentor reviewing a user's journal reflection. Analyze their responses and provide constructive, empathetic feedback.

User's Current Goals:
$goalsContext

User's Current Habits:
$habitsContext

Their Journal Reflection:
$reflectionText

Please provide:
1. A brief acknowledgment of what they shared (1-2 sentences)
2. 2-3 specific insights or observations about their progress, challenges, or patterns
3. 1-2 actionable suggestions or questions to help them move forward

Keep your tone warm, encouraging, and focused on growth. Be specific and reference their actual words where possible.''';

      final aiService = AIService();
      final response = await aiService.getCoachingResponse(prompt: prompt);

      setState(() {
        _mentorFeedback = response;
        _isFetchingFeedback = false;
      });
    } catch (e) {
      setState(() => _isFetchingFeedback = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to get mentor feedback: $e')),
        );
      }
    }
  }

  Future<void> _finishReflection() async {
    setState(() => _isAnalyzing = true);

    try {
      final journalProvider = Provider.of<JournalProvider>(context, listen: false);

      // Save all reflections as structured Q&A pairs
      final List<QAPair> qaPairs = [];
      for (int i = 0; i < _prompts.length; i++) {
        if (_responses[i].isNotEmpty) {
          qaPairs.add(QAPair(
            question: _prompts[i].title,
            answer: _responses[i],
          ));
        }
      }

      if (qaPairs.isNotEmpty) {
        // Determine reflection type based on context
        final reflectionType = widget.isHaltCheck ? 'halt' :
            (widget.isCheckIn ? 'checkin' :
            (journalProvider.entries.isEmpty ? 'onboarding' : 'general'));

        // Include AI insights if mentor feedback was fetched
        final aiInsights = _mentorFeedback != null
            ? {'mentorFeedback': _mentorFeedback!}
            : null;

        final entry = JournalEntry(
          type: JournalEntryType.guidedJournal,
          reflectionType: reflectionType,
          qaPairs: qaPairs,
          aiInsights: aiInsights,
        );
        await journalProvider.addEntry(entry);

        // Track that user has completed guided reflection
        await FeatureDiscoveryService().markGuidedReflectionCompleted();
      }

      if (mounted) {
        if (widget.isCheckIn) {
          // This was a check-in - mark as completed
          final checkinProvider = Provider.of<CheckinProvider>(context, listen: false);
          await checkinProvider.completeCheckin({
            'reflections': _responses.join('\n\n'),
          });

          // Pop back to check-in screen
          Navigator.of(context).pop();
        } else {
          // This was initial onboarding - navigate to goal suggestions
          final aiService = AIService();
          final hasApiKey = aiService.hasApiKey();

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GoalSuggestionsScreen(
                reflections: _responses,
                prompts: _prompts,
                hasApiKey: hasApiKey,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reflections: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.processing),
          automaticallyImplyLeading: false,
        ),
        body: _buildAnalyzingView(),
      );
    }

    if (_showCompletionScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reflection Complete'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() => _showCompletionScreen = false);
            },
          ),
        ),
        body: _buildCompletionScreen(),
      );
    }

    final currentPrompt = _prompts[_currentPromptIndex];
    final progress = (_currentPromptIndex + 1) / _prompts.length;
    final screenTitle = widget.isHaltCheck ? AppStrings.haltCheckIn :
        (widget.isCheckIn ? AppStrings.checkIn : AppStrings.reflectionNoun);

    return Scaffold(
      appBar: AppBar(
        title: Text('$screenTitle ${_currentPromptIndex + 1} of ${_prompts.length}'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentPrompt.icon,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Prompt title
                        Text(
                          currentPrompt.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Prompt text
                        Text(
                          currentPrompt.prompt,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                        ),

                        const SizedBox(height: 32),

                        // Text field
                        TextField(
                          controller: _controllers[_currentPromptIndex],
                          maxLines: 10,
                          decoration: InputDecoration(
                            hintText: currentPrompt.hint,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          autofocus: true,
                          textCapitalization: TextCapitalization.sentences,
                        ),

                        const SizedBox(height: 24),

                        // Encouragement
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppStrings.thereAreNoWrongAnswers,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation buttons
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                    children: [
                      if (_currentPromptIndex > 0)
                        OutlinedButton.icon(
                          onPressed: _previousPrompt,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(AppStrings.back),
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _nextPrompt,
                        icon: Icon(
                          _currentPromptIndex == _prompts.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          _currentPromptIndex == _prompts.length - 1
                              ? AppStrings.finish
                              : AppStrings.next,
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCompletionScreen() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Great work!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  'You\'ve completed your reflection. Here\'s what you shared:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Summary of responses
                ...List.generate(_prompts.length, (index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _prompts[index].icon,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _prompts[index].title,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _responses[index],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Mentor feedback section
                if (_mentorFeedback == null && !_isFetchingFeedback)
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.psychology_outlined,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Want personalized feedback?',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Get AI-powered insights on your reflection, including patterns, observations, and actionable suggestions.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: _getMentorFeedback,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Get Mentor Feedback'),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isFetchingFeedback)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing your reflection...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_mentorFeedback != null)
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      leading: Icon(
                        Icons.psychology,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        'Mentor Feedback',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: MarkdownBody(
                            data: _mentorFeedback!,
                            styleSheet: MarkdownStyleSheet(
                              p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                              strong: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    height: 1.6,
                                  ),
                              em: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.6,
                                  ),
                              listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // Save & Finish button
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: _finishReflection,
              icon: const Icon(Icons.check),
              label: const Text('Save & Finish'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.analyzingYourReflections,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.aiIdentifyingThemes,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ReflectionPrompt {
  final String title;
  final String prompt;
  final String hint;
  final IconData icon;

  ReflectionPrompt({
    required this.title,
    required this.prompt,
    required this.hint,
    required this.icon,
  });
}
