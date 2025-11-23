// lib/screens/onboarding_screen.dart
// Initial onboarding to guide users toward reflective journaling

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/checkin_provider.dart';
import '../providers/pulse_provider.dart';
import '../providers/pulse_type_provider.dart';
import '../providers/chat_provider.dart';
import 'home_screen.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';
import '../constants/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final StorageService _storage = StorageService();
  final BackupService _backupService = BackupService();
  final TextEditingController _nameController = TextEditingController();
  bool _isCreatingHabit = false;
  bool _isRestoring = false;

  // User selections for personalization
  final Set<String> _selectedNeeds = {};
  bool _needsEmergencySupport = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _showExitWarning() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Onboarding?'),
        content: const Text(
          'Are you sure you want to exit? You can always complete the setup later from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Future<void> _saveNameAndContinue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.pleaseEnterYourName)),
      );
      return;
    }

    // Save name to settings
    final settings = await _storage.loadSettings();
    settings['userName'] = name;
    await _storage.saveSettings(settings);

    _nextPage();
  }

  Future<void> _restoreFromBackup() async {
    setState(() => _isRestoring = true);

    try {
      final result = await _backupService.importBackup();

      if (!mounted) return;

      if (result.success) {
        // Mark onboarding as completed
        final settings = await _storage.loadSettings();
        settings['hasCompletedOnboarding'] = true;
        await _storage.saveSettings(settings);

        // Reload all providers with the restored data
        await _reloadProviders();

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isRestoring = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reloadProviders() async {
    if (!mounted) return;

    // Reload all providers to pick up the restored data
    await Provider.of<GoalProvider>(context, listen: false).reload();
    if (!mounted) return;
    await Provider.of<HabitProvider>(context, listen: false).reload();
    if (!mounted) return;
    await Provider.of<JournalProvider>(context, listen: false).reload();
    if (!mounted) return;
    await Provider.of<CheckinProvider>(context, listen: false).reload();
    if (!mounted) return;
    await Provider.of<PulseProvider>(context, listen: false).reload();
    if (!mounted) return;
    await Provider.of<PulseTypeProvider>(context, listen: false).reload();
    if (!mounted) return;
    await Provider.of<ChatProvider>(context, listen: false).reload();
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isCreatingHabit = true);

    try {
      // Create Daily Reflection habit
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);

      // Check if it already exists (shouldn't, but be safe)
      final existingHabit = habitProvider.habits.firstWhere(
        (h) => h.systemType == 'daily_reflection',
        orElse: () => Habit(title: '', description: '', frequency: HabitFrequency.daily),
      );

      if (existingHabit.title.isEmpty) {
        final journalHabit = Habit(
          title: 'Daily Reflection',
          description: 'Use the Journal tab daily for guided reflection to track your progress, capture insights, and maintain self-awareness.',
          frequency: HabitFrequency.daily,
          isSystemCreated: true,
          systemType: 'daily_reflection',
        );
        await habitProvider.addHabit(journalHabit);
      }

      // Mark onboarding as completed
      final settings = await _storage.loadSettings();
      settings['hasCompletedOnboarding'] = true;
      await _storage.saveSettings(settings);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _isCreatingHabit = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting up: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // On first page, show exit warning
        if (_currentPage == 0) {
          final shouldExit = await _showExitWarning();
          if (!mounted) return;
          if (shouldExit) {
            Navigator.of(context).pop();
          }
        } else {
          // On other pages, go back to previous page
          _previousPage();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator with back button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back button (hidden on first page)
                    if (_currentPage > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _previousPage,
                        tooltip: 'Back',
                      )
                    else
                      const SizedBox(width: 48), // Placeholder for alignment

                    // Progress indicators
                    Expanded(
                      child: Row(
                        children: [
                          for (int i = 0; i < 4; i++)
                            Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: i <= _currentPage
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // Balance layout
                  ],
                ),
              ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Prevent manual swipe
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(),
                  _buildNeedsAssessmentPage(),
                  _buildPersonalizedSetupPage(),
                  _buildNameAndFinishPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return _buildPageWrapper(
      children: [
        Icon(
          Icons.psychology,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          AppStrings.welcomeToMentorMe,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'An AI-powered mental health companion that combines:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildFeatureBadge(icon: Icons.healing, text: 'Evidence-based therapy techniques (CBT)'),
        const SizedBox(height: 12),
        _buildFeatureBadge(icon: Icons.flag, text: 'Personal coaching for your goals'),
        const SizedBox(height: 12),
        _buildFeatureBadge(icon: Icons.spa, text: 'Daily support for wellbeing'),
        const SizedBox(height: 32),
        Text(
          'Whether you\'re managing anxiety, building better habits, or working toward dreams, I\'m here to guide you.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        _isRestoring
            ? const CircularProgressIndicator()
            : FilledButton.icon(
                onPressed: _nextPage,
                icon: const Icon(Icons.arrow_forward),
                label: const Text(AppStrings.getStarted),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
        const SizedBox(height: 24),
        // Divider with "or" text
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[400])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[400])),
          ],
        ),
        const SizedBox(height: 24),
        // Restore from backup option
        TextButton.icon(
          onPressed: _isRestoring ? null : _restoreFromBackup,
          icon: const Icon(Icons.restore),
          label: const Text('Restore from Backup'),
        ),
        const SizedBox(height: 8),
        Text(
          'Have a backup file? Skip setup and restore your data.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNeedsAssessmentPage() {
    return _buildPageWrapper(
      children: [
        Icon(
          Icons.help_outline,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'What brings you here?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Select all that apply (honest, non-judgmental)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildCheckableCard('anxiety', 'Managing anxiety or worry', Icons.psychology),
        _buildCheckableCard('depression', 'Coping with low mood/depression', Icons.cloud),
        _buildCheckableCard('self_compassion', 'Building self-compassion', Icons.favorite),
        _buildCheckableCard('patterns', 'Understanding my patterns', Icons.insights),
        _buildCheckableCard('goals', 'Achieving goals', Icons.flag),
        _buildCheckableCard('habits', 'Building habits', Icons.check_circle),
        _buildCheckableCard('self_awareness', 'Reflection and self-awareness', Icons.auto_stories),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _selectedNeeds.isEmpty ? null : _nextPage,
          icon: const Icon(Icons.arrow_forward),
          label: const Text(AppStrings.continue_),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
        if (_selectedNeeds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildPersonalizedSetupPage() {
    final recommendations = _getRecommendations();

    return _buildPageWrapper(
      children: [
        Icon(
          Icons.auto_fix_high,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Your Personalized Plan',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Based on your selections, here\'s what I recommend:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ...recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildInfoCard(
            icon: rec['icon'] as IconData,
            title: rec['title'] as String,
            description: rec['description'] as String,
          ),
        )),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _nextPage,
          icon: const Icon(Icons.arrow_forward),
          label: const Text(AppStrings.continue_),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildNameAndFinishPage() {
    return _buildPageWrapper(
      children: [
        Icon(
          Icons.person,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Let\'s get to know each other',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'I\'m your personal AI mentor. What should I call you?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: AppStrings.yourName,
            hintText: 'Enter your first name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _saveNameAndComplete(),
        ),
        const SizedBox(height: 24),
        _isCreatingHabit
            ? const CircularProgressIndicator()
            : FilledButton.icon(
                onPressed: _saveNameAndComplete,
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Start Your Journey'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
      ],
    );
  }

  List<Map<String, dynamic>> _getRecommendations() {
    final recommendations = <Map<String, dynamic>>[];

    // Daily practices recommendation (always)
    recommendations.add({
      'icon': Icons.self_improvement,
      'title': 'Daily HALT Check-in',
      'description': 'Quick check on basic needs: Hungry, Angry, Lonely, Tired',
    });

    // Anxiety-specific
    if (_selectedNeeds.contains('anxiety')) {
      recommendations.add({
        'icon': Icons.schedule,
        'title': 'Worry Time (for anxiety)',
        'description': 'Contain anxiety with designated 15-min worry practice',
      });
    }

    // Depression-specific
    if (_selectedNeeds.contains('depression')) {
      recommendations.add({
        'icon': Icons.directions_run,
        'title': 'Behavioral Activation',
        'description': 'Schedule pleasant activities to improve mood',
      });
      recommendations.add({
        'icon': Icons.favorite,
        'title': 'Gratitude Practice',
        'description': 'Write 3 good things daily to shift focus',
      });
    }

    // Self-compassion
    if (_selectedNeeds.contains('self_compassion')) {
      recommendations.add({
        'icon': Icons.self_improvement,
        'title': 'Self-Compassion Exercises',
        'description': 'Treat yourself with kindness, reduce self-criticism',
      });
    }

    // Goals recommendation
    if (_selectedNeeds.contains('goals')) {
      recommendations.add({
        'icon': Icons.flag,
        'title': 'Your First Goal',
        'description': 'We\'ll help you create and track meaningful goals',
      });
    }

    // Habits recommendation
    if (_selectedNeeds.contains('habits')) {
      recommendations.add({
        'icon': Icons.check_circle,
        'title': 'Habit Tracking',
        'description': 'Build consistency with daily habit check-ins',
      });
    }

    // Reflection (always include)
    if (_selectedNeeds.contains('self_awareness') || _selectedNeeds.contains('patterns')) {
      recommendations.add({
        'icon': Icons.auto_stories,
        'title': 'AI Reflection Sessions',
        'description': 'Deep guided reflection with pattern recognition',
      });
    }

    return recommendations;
  }

  Future<void> _saveNameAndComplete() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.pleaseEnterYourName)),
      );
      return;
    }

    setState(() => _isCreatingHabit = true);

    try {
      // Save name and user selections to settings
      final settings = await _storage.loadSettings();
      settings['userName'] = name;
      settings['userNeeds'] = _selectedNeeds.toList();
      settings['hasCompletedOnboarding'] = true;
      settings['enableClinicalFeatures'] = true; // Enable mental health tools by default
      await _storage.saveSettings(settings);

      // Create Daily Reflection habit
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final existingHabit = habitProvider.habits.firstWhere(
        (h) => h.systemType == 'daily_reflection',
        orElse: () => Habit(title: '', description: '', frequency: HabitFrequency.daily),
      );

      if (existingHabit.title.isEmpty) {
        final journalHabit = Habit(
          title: 'Daily Reflection',
          description: 'Use the Journal tab daily for guided reflection to track your progress, capture insights, and maintain self-awareness.',
          frequency: HabitFrequency.daily,
          isSystemCreated: true,
          systemType: 'daily_reflection',
        );
        await habitProvider.addHabit(journalHabit);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _isCreatingHabit = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting up: $e')),
        );
      }
    }
  }

  Widget _buildCheckableCard(String key, String label, IconData icon) {
    final isSelected = _selectedNeeds.contains(key);

    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedNeeds.remove(key);
            } else {
              _selectedNeeds.add(key);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFoundationPage() {
    return _buildPageWrapper(
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your Foundation is Ready',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve set up everything you need to begin your growth journey',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Daily Reflection habit card
        _buildInfoCard(
          icon: Icons.auto_stories,
          title: 'Daily Reflection Habit',
          description: 'Your foundation habit will be created for you. Reflect daily to track progress and maintain self-awareness.',
        ),
        const SizedBox(height: 16),

        // Habits & Goals emerge card
        _buildInfoCard(
          icon: Icons.lightbulb_outline,
          title: 'Habits & Goals Will Emerge',
          description: 'As you reflect consistently, meaningful habits and goals will naturally reveal themselves.',
        ),
        const SizedBox(height: 16),

        // Create anytime card
        _buildInfoCard(
          icon: Icons.flag_outlined,
          title: 'Or Create Anytime',
          description: 'You can also create and track habits and goals manually from their respective tabs whenever you\'re ready.',
        ),

        const SizedBox(height: 48),

        // Get started button
        _isCreatingHabit
            ? const CircularProgressIndicator()
            : FilledButton.icon(
                onPressed: _completeOnboarding,
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Get Started'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
      ],
    );
  }

  /// Wraps onboarding page content with consistent vertical centering and scrolling
  Widget _buildPageWrapper({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 48, // Account for padding
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: children,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
