// lib/main.dart
// UPDATED: Added Onboarding

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/goal_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/checkin_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/pulse_provider.dart';
import 'providers/pulse_type_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/journal_template_provider.dart';
import 'providers/checkin_template_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/assessment_provider.dart';
import 'providers/behavioral_activation_provider.dart';
import 'providers/gratitude_provider.dart';
import 'providers/worry_provider.dart';
import 'providers/self_compassion_provider.dart';
import 'providers/values_provider.dart';
import 'providers/implementation_intention_provider.dart';
import 'providers/intervention_provider.dart';
import 'providers/meditation_provider.dart';
import 'providers/urge_surfing_provider.dart';
import 'providers/hydration_provider.dart';
import 'providers/digital_wellness_provider.dart';
import 'providers/weight_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/win_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';
import 'services/ai_service.dart';
import 'services/debug_service.dart';
import 'services/storage_service.dart';
import 'services/auto_backup_service.dart';
import 'services/feature_discovery_service.dart';
import 'services/structured_journaling_service.dart';
import 'theme/app_theme.dart';

void main() async {
  // Wrap entire main in error handler to prevent startup crashes
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Lock app to portrait orientation only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize debug service first
    final debugService = DebugService();
    await debugService.initialize();

    // Initialize services with error handling
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
    } catch (e) {
      debugPrint('Warning: Notification service initialization failed: $e');
      // Continue app launch even if notifications fail
    }

    // IMPORTANT: Initialize AI service to load API key
    try {
      final aiService = AIService();
      await aiService.initialize();
    } catch (e) {
      debugPrint('Warning: AI service initialization failed: $e');
      // Continue app launch even if AI service fails
    }

    // Initialize feature discovery service
    try {
      final featureDiscoveryService = FeatureDiscoveryService();
      await featureDiscoveryService.initialize();
    } catch (e) {
      debugPrint('Warning: Feature discovery service initialization failed: $e');
      // Continue app launch even if feature discovery fails
    }

    // Run data migrations if needed (BEFORE loading any data)
    final storage = StorageService();
    try {
      await storage.runMigrationsIfNeeded();
    } catch (e, stackTrace) {
      debugPrint('Warning: Migration failed: $e');
      debugPrint('Stack trace: $stackTrace');
      // Continue app launch - providers will use potentially outdated data
    }

    // ============================================================================
    // WIRE UP AUTO-BACKUP SERVICE
    // ============================================================================
    // Register AutoBackupService as a persistence listener on StorageService.
    // This ensures automatic backups are triggered whenever domain data changes,
    // without requiring manual calls in each provider.
    //
    // IMPORTANT: This MUST be registered BEFORE providers load data, so that
    // any data changes during initialization are captured.
    try {
      final autoBackup = AutoBackupService();
      storage.addPersistenceListener((dataType) async {
        await debugService.info('main', 'Data change detected - triggering auto-backup', metadata: {
          'dataType': dataType,
          'timestamp': DateTime.now().toIso8601String(),
        });
        await autoBackup.scheduleAutoBackup();
      });
      await debugService.info('main', 'Auto-backup listener registered successfully');
    } catch (e) {
      debugPrint('Warning: Auto-backup listener registration failed: $e');
      // Continue app launch even if auto-backup fails
    }

    // Check if first launch
    final settings = await storage.loadSettings();
    final hasCompletedOnboarding = settings['hasCompletedOnboarding'] as bool? ?? false;

    // Schedule mentor reminders (Android only)
    try {
      final notificationService = NotificationService();
      await notificationService.scheduleAllReminders();
      await notificationService.schedulePeriodicCriticalChecks();
    } catch (e) {
      debugPrint('Warning: Reminder scheduling failed: $e');
      // Continue app launch even if scheduling fails
    }

    // Initialize structured journaling templates
    // Note: Templates are loaded lazily in JournalTemplateProvider initialization
    // No explicit service initialization needed here

    runApp(MyApp(showOnboarding: !hasCompletedOnboarding));
  } catch (e, stackTrace) {
    // If initialization completely fails, show error screen
    debugPrint('FATAL ERROR during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Please try:\n1. Force stop the app\n2. Clear app data\n3. Restart the app',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => CheckinProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => PulseProvider()),
        ChangeNotifierProvider(create: (_) => PulseTypeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        ChangeNotifierProvider(create: (_) => BehavioralActivationProvider()),
        ChangeNotifierProvider(create: (_) => GratitudeProvider()),
        ChangeNotifierProvider(create: (_) => WorryProvider()),
        ChangeNotifierProvider(create: (_) => SelfCompassionProvider()),
        ChangeNotifierProvider(create: (_) => ValuesProvider()),
        ChangeNotifierProvider(create: (_) => ImplementationIntentionProvider()),
        ChangeNotifierProvider(create: (_) => InterventionProvider()),
        ChangeNotifierProvider(create: (_) => MeditationProvider()),
        ChangeNotifierProvider(create: (_) => UrgeSurfingProvider()),
        ChangeNotifierProvider(create: (_) => HydrationProvider()),
        ChangeNotifierProvider(create: (_) => WeightProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => DigitalWellnessProvider()),
        ChangeNotifierProvider(create: (_) => WinProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = JournalTemplateProvider();
          // Initialize system templates
          final service = StructuredJournalingService();
          provider.setSystemTemplates(service.getDefaultTemplates());
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => CheckInTemplateProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = SettingsProvider();
          // Load settings on initialization
          provider.loadSettings();
          return provider;
        }),
      ],
      child: MaterialApp(
        title: 'MentorMe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system, // Respects system dark mode setting
        home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
      ),
    );
  }
}
