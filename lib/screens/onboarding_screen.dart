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
  String _userName = '';
  bool _isCreatingHabit = false;
  bool _isRestoring = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
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

    setState(() {
      _userName = name;
    });

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
    await Provider.of<HabitProvider>(context, listen: false).reload();
    await Provider.of<JournalProvider>(context, listen: false).reload();
    await Provider.of<CheckinProvider>(context, listen: false).reload();
    await Provider.of<PulseProvider>(context, listen: false).reload();
    await Provider.of<PulseTypeProvider>(context, listen: false).reload();
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
          if (shouldExit && mounted) {
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
                          for (int i = 0; i < 3; i++)
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
                  _buildNamePage(),
                  _buildFoundationPage(),
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
          Icons.auto_awesome,
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
          'Your AI-powered companion for personal growth and meaningful change',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

  Widget _buildNamePage() {
    return _buildPageWrapper(
      children: [
        Icon(
          Icons.person,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Let\'s get to know each other',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'I\'m your personal AI mentor. What should I call you?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
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
          onSubmitted: (_) => _saveNameAndContinue(),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saveNameAndContinue,
          icon: const Icon(Icons.arrow_forward),
          label: const Text(AppStrings.continue_),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
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
