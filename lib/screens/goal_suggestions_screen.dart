// lib/screens/goal_suggestions_screen.dart
// AI-powered goal suggestions based on user reflections

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';
import '../providers/habit_provider.dart';
import '../services/ai_service.dart';
import '../services/debug_service.dart';
import '../services/storage_service.dart';
import '../models/habit.dart';
import '../constants/app_strings.dart';
import 'guided_journaling_screen.dart';
import 'home_screen.dart';
import 'dart:convert';

class GoalSuggestionsScreen extends StatefulWidget {
  final List<String> reflections;
  final List<ReflectionPrompt> prompts;
  final bool hasApiKey;

  const GoalSuggestionsScreen({
    super.key,
    required this.reflections,
    required this.prompts,
    this.hasApiKey = false,
  });

  @override
  State<GoalSuggestionsScreen> createState() => _GoalSuggestionsScreenState();
}

class _GoalSuggestionsScreenState extends State<GoalSuggestionsScreen> {
  final AIService _aiService = AIService();
  final DebugService _debug = DebugService();
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  String? _error;
  List<SuggestedGoal> _suggestions = [];
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _createDailyReflectionHabit();
    _generateSuggestions();
  }

  /// Create the Daily Reflection habit immediately on load
  /// This ensures it's truly "included automatically" as the UI claims
  Future<void> _createDailyReflectionHabit() async {
    try {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);

      // Check if Daily Reflection habit already exists
      final existingHabit = habitProvider.habits.firstWhere(
        (h) => h.systemType == 'daily_reflection',
        orElse: () => Habit(title: '', description: '', frequency: HabitFrequency.daily),
      );

      // Only create if it doesn't exist
      if (existingHabit.title.isEmpty) {
        final journalHabit = Habit(
          title: 'Daily Reflection',
          description: 'Use the Journal tab daily for guided reflection to track your progress, capture insights, and maintain self-awareness.',
          frequency: HabitFrequency.daily,
          isSystemCreated: true,
          systemType: 'daily_reflection',
        );
        await habitProvider.addHabit(journalHabit);

        await _debug.info(
          'GoalSuggestions',
          'Created Daily Reflection habit automatically',
        );
      }
    } catch (e) {
      await _debug.warning('GoalSuggestions', 'Failed to create Daily Reflection habit: $e');
    }
  }

  Future<void> _generateSuggestions() async {
    // If no API key, skip directly to showing the journal habit
    if (!widget.hasApiKey) {
      setState(() {
        _isLoading = false;
        _error = null; // No error, just no AI suggestions
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {

      // Build context from reflections
      final reflectionContext = StringBuffer();
      for (int i = 0; i < widget.prompts.length; i++) {
        reflectionContext.writeln('${widget.prompts[i].title}:');
        reflectionContext.writeln(widget.reflections[i]);
        reflectionContext.writeln();
      }

      await _debug.info('GoalSuggestions', 'Generating goal suggestions from reflections');

      final prompt = '''Based on these reflections from someone starting their personal growth journey, suggest 3-5 meaningful, achievable goals.

Reflections:
$reflectionContext

For each goal, provide:
1. title (concise, 3-8 words)
2. description (2-3 sentences explaining why this matters based on their reflections)
3. category (one of: health, fitness, career, learning, finance, relationships, creativity, mindfulness, other)
4. reasoning (1-2 sentences connecting to specific things they mentioned)

Return ONLY valid JSON array in this exact format:
[
  {
    "title": "Goal title here",
    "description": "Why this matters...",
    "category": "health",
    "reasoning": "Based on your mention of..."
  }
]

Focus on goals that are:
- Specific and actionable
- Based on their actual words and concerns
- Achievable within 2-6 months
- Meaningful to their expressed values''';

      final response = await _aiService.getCoachingResponse(prompt: prompt);

      // Parse suggestions
      _suggestions = _parseSuggestions(response);

      await _debug.info('GoalSuggestions', 'Generated ${_suggestions.length} suggestions');

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      await _debug.error(
        'GoalSuggestions',
        'Failed to generate suggestions: $e',
        stackTrace: stackTrace.toString(),
      );

      setState(() {
        _error = 'Failed to generate suggestions. You can still create goals manually.';
        _isLoading = false;
      });
    }
  }

  List<SuggestedGoal> _parseSuggestions(String response) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('No JSON array found in response');
      }

      final jsonStr = response.substring(jsonStart, jsonEnd);
      final List<dynamic> parsed = json.decode(jsonStr);

      return parsed.map((item) {
        return SuggestedGoal(
          title: item['title'] ?? 'Untitled Goal',
          description: item['description'] ?? '',
          category: _parseCategory(item['category']),
          reasoning: item['reasoning'] ?? '',
        );
      }).toList();
    } catch (e) {
      _debug.warning('GoalSuggestions', 'Failed to parse suggestions: $e');
      return [];
    }
  }

  GoalCategory _parseCategory(String? categoryStr) {
    if (categoryStr == null) return GoalCategory.other;

    final lower = categoryStr.toLowerCase();
    for (final category in GoalCategory.values) {
      if (category.toString().toLowerCase().contains(lower)) {
        return category;
      }
    }
    return GoalCategory.other;
  }

  Future<void> _saveSelectedGoals() async {
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);

    // Determine which goals should be active vs backlog
    Set<int> activeGoalIndices = _selectedIndices;

    // If more than 2 goals selected, ask user to prioritize
    if (_selectedIndices.length > 2) {
      final prioritizedIndices = await _showPrioritizationDialog();
      if (prioritizedIndices == null) {
        // User cancelled
        return;
      }
      activeGoalIndices = prioritizedIndices;
    }

    // Create selected goals with appropriate status
    for (final index in _selectedIndices) {
      final suggestion = _suggestions[index];
      final isActive = activeGoalIndices.contains(index);

      final goal = Goal(
        title: suggestion.title,
        description: '${suggestion.description}\n\nWhy this matters: ${suggestion.reasoning}',
        category: suggestion.category,
        targetDate: DateTime.now().add(const Duration(days: 90)), // 3 months
        status: isActive ? GoalStatus.active : GoalStatus.backlog,
      );
      await goalProvider.addGoal(goal);
    }

    // Note: Daily Reflection habit was already created in initState()

    final activeCount = activeGoalIndices.length;
    final backlogCount = _selectedIndices.length - activeCount;

    await _debug.info(
      'GoalSuggestions',
      'Created $activeCount active goal(s) and $backlogCount backlog goal(s)',
    );

    // Mark onboarding as completed
    final settings = await _storage.loadSettings();
    settings['hasCompletedOnboarding'] = true;
    await _storage.saveSettings(settings);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  Future<Set<int>?> _showPrioritizationDialog() async {
    final selectedGoals = _selectedIndices.toList();
    final prioritizedIndices = <int>{};

    return await showDialog<Set<int>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Focus on 2 Goals'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We recommend starting with 2 active goals to maintain focus. Which goals would you like to prioritize?',
                ),
                const SizedBox(height: 16),
                const Text(
                  'The other goals will be saved in your backlog.',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),
                ...selectedGoals.map((index) {
                  final suggestion = _suggestions[index];
                  final isChecked = prioritizedIndices.contains(index);
                  final canCheck = prioritizedIndices.length < 2 || isChecked;

                  return CheckboxListTile(
                    value: isChecked,
                    onChanged: canCheck
                        ? (value) {
                            setState(() {
                              if (value == true) {
                                prioritizedIndices.add(index);
                              } else {
                                prioritizedIndices.remove(index);
                              }
                            });
                          }
                        : null,
                    title: Text(
                      suggestion.title,
                      style: TextStyle(
                        color: canCheck ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      suggestion.category.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: canCheck ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: prioritizedIndices.length == 2
                  ? () => Navigator.of(context).pop(prioritizedIndices)
                  : null,
              child: Text('${AppStrings.continue_} with ${prioritizedIndices.length}/2'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _skipToHome() async {
    // Mark onboarding as completed
    final settings = await _storage.loadSettings();
    settings['hasCompletedOnboarding'] = true;
    await _storage.saveSettings(settings);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Your Foundation'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skipToHome,
            child: const Text(AppStrings.skip),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildSuggestionsView(),
      bottomNavigationBar: !_isLoading && _error == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FilledButton.icon(
                  onPressed: _saveSelectedGoals,
                  icon: const Icon(Icons.check),
                  label: Text(
                    _selectedIndices.isEmpty
                        ? 'Start Your Journey'
                        : 'Create ${_selectedIndices.length} Goal(s) & Start',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingView() {
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
              'Crafting Your Path',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'AI is analyzing your reflections to suggest meaningful goals...',
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.orange[700],
            ),
            const SizedBox(height: 24),
            Text(
              'AI Suggestions Unavailable',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set up your API key in Settings to unlock AI-powered goal suggestions and insights.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _skipToHome,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to App'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Text(
          widget.hasApiKey ? 'Your Essential Habit & Goals' : 'Start Your Journey',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.hasApiKey
              ? 'Based on your reflections, here\'s your foundation habit and suggested goals. Select up to 2 goals to focus on first. Others will be saved in your backlog.'
              : 'Your reflections have been saved. Start with daily reflection and goals will emerge naturally.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),

        const SizedBox(height: 24),

        // Daily reflection habit (always shown)
        _buildJournalHabitCard(),

        const SizedBox(height: 16),

        // Suggested goals
        if (_suggestions.isNotEmpty) ...[
          Text(
            'Suggested Goals',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._suggestions.asMap().entries.map((entry) {
            return _buildSuggestionCard(entry.key, entry.value);
          }),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.hasApiKey
                      ? 'Start with Daily Reflection'
                      : 'Goals Will Emerge Naturally',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Reflection is the foundation of growth. Reflect daily and you\'ll discover what matters most. When you\'re ready, you can set specific goals.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (!widget.hasApiKey) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add your API key in Settings to get AI-powered goal suggestions',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 100), // Space for bottom button
      ],
    );
  }

  Widget _buildJournalHabitCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.book_outlined,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Daily Reflection',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ESSENTIAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Habit • Daily',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Daily reflection is the foundation of personal growth. It helps you maintain self-awareness, track progress, and discover new goals.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Already added for you',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(int index, SuggestedGoal suggestion) {
    final isSelected = _selectedIndices.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          suggestion.category.icon,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                suggestion.category.displayName,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: suggestion.description,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium,
                  strong: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  em: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                  listBullet: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MarkdownBody(
                        data: suggestion.reasoning,
                        styleSheet: MarkdownStyleSheet(
                          p: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                          strong: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                          em: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                          listBullet: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuggestedGoal {
  final String title;
  final String description;
  final GoalCategory category;
  final String reasoning;

  SuggestedGoal({
    required this.title,
    required this.description,
    required this.category,
    required this.reasoning,
  });
}
