// lib/constants/app_strings.dart
// Centralized strings for consistency and easy internationalization

class AppStrings {
  // App Name
  static const String appName = 'MentorMe';
  static const String appTagline = 'Your AI-powered companion for personal growth';

  // Core Feature Names
  static const String featureMentor = 'Mentor';
  static const String featureJournal = 'Journal';
  static const String featureHabits = 'Habits';
  static const String featureGoals = 'Goals';
  static const String featureSettings = 'Settings';

  // Journal/Reflection Terminology
  static const String journalNoun = 'Journal';
  static const String journalVerb = 'Journal';
  static const String reflectVerb = 'Reflect';
  static const String newEntry = 'New Entry'; // Journal FAB button
  static const String reflectionNoun = 'Reflection';
  static const String writeVerb = 'Write';
  static const String deepDiveSession = 'Deep Dive Session'; // Mentor screen reflection button
  static const String structuredReflection = 'Structured Reflection'; // Journal menu option

  static const String journalEntry = 'journal entry';
  static const String journalEntries = 'entries';
  static const String guidedReflection = 'Guided Reflection';
  static const String quickEntry = 'Quick Entry';

  // Journal Screen Strings
  static const String entriesThisMonth = 'entries this month';
  static const String entryThisMonth = 'entry this month';
  static const String thisWeek = 'this week';
  static const String compact = 'Compact';
  static const String defaultView = 'Default';
  static const String searchEntries = 'Search entries...';
  static const String tipUseAiChat = 'Tip: Use AI Chat for deeper insights and pattern analysis';
  static const String all = 'All';
  static const String pulseCheck = 'Pulse Check';
  static const String justLogHowYouFeel = 'Just log how you feel (10 sec)';
  static const String fastSimpleNote = 'Fast, simple note (30 sec)';
  static const String stepByStepPrompts = 'Step-by-step prompts (3-5 min)';
  static const String recommended = 'Recommended';
  static const String guidedJournalCannotBeEdited = 'Guided journal entries cannot be edited';

  // Guided Journaling Strings
  static const String processing = 'Processing';
  static const String thereAreNoWrongAnswers = 'There are no wrong answers. Write freely.';
  static const String finish = 'Finish';
  static const String analyzingYourReflections = 'Analyzing Your Reflections';
  static const String aiIdentifyingThemes = 'AI is identifying themes and suggesting meaningful goals based on what you shared...';

  // Entry Details
  static const String viewDetails = 'View Details';
  static const String editEntry = 'Edit Entry';
  static const String deleteEntry = 'Delete Entry?';
  static const String deletePulseEntry = 'Delete Pulse Entry?';
  static const String saveChanges = 'Save Changes';
  static const String noContent = 'No content';
  static const String note = 'Note';
  static const String level = 'Level';
  static const String content = 'Content';
  static const String label = 'Label';

  // Time Formatting
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';

  // Check-in Terminology (always hyphenated for user-facing text)
  static const String checkIn = 'Check-in';
  static const String checkIns = 'Check-ins';
  static const String dailyCheckIn = 'Daily Check-in';
  static const String completeCheckIn = 'Complete Check-in';
  static const String skipCheckIn = 'Skip Check-in';

  // Goal Terminology
  static const String goal = 'Goal';
  static const String goals = 'Goals';
  static const String createGoal = 'Create Goal';
  static const String createNewGoal = 'Create New Goal';
  static const String editGoal = 'Edit Goal';
  static const String deleteGoal = 'Delete Goal';
  static const String targetDate = 'Target Date';
  static const String targetDateOptional = 'Target Date (Optional)';
  static const String milestone = 'Milestone';
  static const String milestones = 'Milestones';
  static const String progress = 'Progress';
  static const String status = 'Status';
  static const String active = 'Active';
  static const String backlog = 'Backlog';
  static const String addedToBacklog = '(added to backlog)';

  // Goal Form Labels and Hints
  static const String goalTitle = 'Goal Title';
  static const String goalTitleHint = 'e.g., Lose 10kg';
  static const String description = 'Description';
  static const String describeYourGoal = 'Describe your goal and why it matters';
  static const String category = 'Category';
  static const String noTargetDateSet = 'No target date set';

  // Goal Detail
  static const String addManually = 'Add Manually';
  static const String linkToGoal = 'Link to Goal (Optional)';
  static const String noGoalIndependentHabit = 'No goal (independent habit)';
  static const String linkingToGoalHelps = 'Linking to a goal helps track related habits together';

  // Goal Status Messages
  static const String limitReachedGoals = 'Limit reached: You have 2 active goals. New goals go to backlog.';
  static const String focusOnActiveGoals = 'Focus on 1-2 active goals at a time';
  static const String targetDatePassed = 'Target date passed';
  static const String dueToday = 'Due today';
  static const String dayRemaining = 'day remaining';
  static const String daysRemaining = 'days remaining';
  static const String onTrack = 'On Track';
  static const String avgProgress = 'Avg Progress';
  static const String activeGoals = 'Active Goals';
  static const String noActiveGoalsAddOrMove = 'No active goals. Add a goal or move one from backlog.';
  static const String goalsYourePlanningLater = 'Goals you\'re planning to work on later';

  // Milestone Terminology
  static const String addMilestone = 'Add Milestone';
  static const String milestoneTitle = 'Milestone Title';
  static const String milestoneTitleHint = 'e.g., Complete week 1 of training';
  static const String whatMilestoneInvolves = 'What does this milestone involve?';
  static const String aiSuggestedMilestones = 'AI-Suggested Milestones';
  static const String suggestedMilestones = 'Suggested Milestones';
  static const String aiSuggestedMilestonesWillBeAdded = 'AI-suggested milestones will be added to your goal';
  static const String generateWithAi = 'Generate with AI';
  static const String generateNewSuggestions = 'Generate new suggestions';
  static const String getAiMilestoneSuggestions = 'Get AI Milestone Suggestions';
  static const String gettingSuggestions = 'Getting suggestions...';
  static const String aiSuggest = 'AI Suggest';

  // Habit Terminology
  static const String habit = 'Habit';
  static const String habits = 'Habits';
  static const String createHabit = 'Create Habit';
  static const String createNewHabit = 'Create New Habit';
  static const String trackHabit = 'Track Habit';
  static const String habitStreak = 'streak';
  static const String frequency = 'Frequency';

  // Habit Form Labels and Hints
  static const String habitTitle = 'Habit Title';
  static const String habitTitleHint = 'e.g., Morning workout';
  static const String whatHabitInvolves = 'What does this habit involve?';

  // Habit Status Messages
  static const String limitReachedHabits = 'Limit reached: You have 2 active habits. New habits go to backlog.';
  static const String focusOnActiveHabits = 'Focus on 1-2 active habits at a time';
  static const String createFirstHabitBuildConsistency = 'Create your first habit to start building consistency';
  static const String completed = 'Completed';
  static const String remaining = 'Remaining';
  static const String activeHabits = 'Active Habits';
  static const String noActiveHabitsAddOrMove = 'No active habits. Add a habit or move one from backlog.';
  static const String toCompleteToday = 'To Complete Today';
  static const String completedToday = 'Completed Today';
  static const String habitsYourePlanningLater = 'Habits you\'re planning to work on later';

  // Challenge/Blocker Terminology
  // User-facing: "Challenge" (more positive)
  // Code: "Blocker" (technical term)
  static const String challenge = 'Challenge';
  static const String challenges = 'Challenges';
  static const String newChallengesDetected = 'New challenges detected';
  static const String challengesToAddress = 'Challenges to Address';
  static const String overcomingChallenges = 'Overcoming Challenges';

  // Mentor Terminology
  static const String mentor = 'Mentor';
  static const String yourMentor = 'Your Mentor';
  static const String mentorSays = 'Your Mentor Says...';
  static const String chatWithMentor = 'Chat with me';
  static const String aiMentor = 'AI Mentor';

  // Common Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String done = 'Done';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String skip = 'Skip';
  static const String continue_ = 'Continue'; // _ to avoid keyword conflict
  static const String getStarted = 'Get Started';
  static const String acceptChallenge = 'Accept Challenge';
  static const String notNow = 'Not now';
  static const String createCustomChallenge = 'Create Custom Challenge';
  static const String add = 'Add';
  static const String show = 'Show';
  static const String hide = 'Hide';
  static const String clear = 'Clear';
  static const String ok = 'OK';
  static const String gotIt = 'Got it';
  static const String addAll = 'Add All';
  static const String addAnyway = 'Add Anyway';
  static const String refresh = 'Refresh';
  static const String export = 'Export';
  static const String import = 'Import';
  static const String copy = 'Copy';
  static const String or = 'or';

  // Action States (with progress indicators)
  static const String generating = 'Generating...';
  static const String testing = 'Testing...';
  static const String exporting = 'Exporting...';
  static const String importing = 'Importing...';
  static const String downloading = 'Downloading...';
  static const String resetting = 'Resetting app...';

  // Common Phrases
  static const String howAreYouDoing = 'How are you doing?';
  static const String whatsOnYourMind = 'What\'s on your mind?';
  static const String anyChallengesOrWins = 'Any challenges or wins to share?';
  static const String shareHowYourFeeling = 'Share how you\'re feeling...';

  // Onboarding
  static const String welcomeToMentorMe = 'Welcome to MentorMe';
  static const String growthStartsWithReflection = 'Growth Starts with Reflection';
  static const String startWithGuidedReflection = 'Start with Guided Reflection';
  static const String chooseYourPath = 'Choose Your Path';
  static const String letUsGetToKnow = 'Let\'s get to know each other';
  static const String imYourPersonalMentor = 'I\'m your personal AI mentor. What should I call you?';

  // Pulse Check-In
  static const String quickCheckIn = 'Pulse Check-in';
  static const String howWouldYouLikeToReflect = 'How would you like to reflect?';

  // Mentor Screen
  static const String yourFocusToday = 'Your Focus Today';
  static const String thisWeeksProgress = 'This Week\'s Progress';
  static const String recommendedActions = 'Recommended Actions';
  static const String activeStreaks = 'Active Streaks';

  // Screen Titles
  static const String aiSettings = 'AI Settings';
  static const String mentorReminders = 'Mentor Reminders';
  static const String debugConsole = 'Debug Console';
  static const String profileSettings = 'Profile Settings';

  // Settings
  static const String settings = 'Settings';
  static const String profile = 'Profile';
  static const String yourName = 'Your Name';
  static const String editYourName = 'Edit Your Name';
  static const String aiModel = 'AI Model';
  static const String backupAndRestore = 'Backup & Restore';
  static const String exportBackup = 'Export Backup';
  static const String importBackup = 'Import Backup';
  static const String resetApp = 'Reset App';
  static const String dangerZone = 'Danger Zone';
  static const String notifications = 'Notifications';
  static const String scheduleCheckInReminders = 'Schedule when to receive check-in reminders';
  static const String pulseCheckTypes = 'Pulse Check Types';
  static const String activeTypes = 'active type(s)';
  static const String exportAndImportData = 'Export and import your data';
  static const String configureAiSettings = 'Configure AI provider and model settings';
  static const String debugAndTesting = 'Debug & Testing';
  static const String toolsForTroubleshooting = 'Tools for troubleshooting and diagnostics';
  static const String irreversibleActions = 'Irreversible actions';
  static const String clearAllDataAndStartOver = 'Clear all data and start over';
  static const String setUpYourProfile = 'Set up your profile';

  // Messages
  static const String nameUpdatedSuccessfully = 'Name updated successfully!';
  static const String noActiveGoalsYet = 'No active goals yet';
  static const String startByCreatingYourFirstGoal = 'Start by creating your first goal';
  static const String noCheckInsScheduled = 'No check-ins scheduled';

  // Time-based Greetings
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';

  // Validation Messages
  static const String pleaseEnterTitle = 'Please enter a title';
  static const String pleaseEnterDescription = 'Please enter a description';
  static const String pleaseEnterTitleAndDescription = 'Please enter a title and description first';
  static const String pleaseEnterYourName = 'Please enter your name';
  static const String pleaseWriteSomething = 'Please write something';

  // Error Messages
  static const String errorOccurred = 'An error occurred';
  static const String failedToGenerateSuggestions = 'Failed to generate suggestions. Check your API key.';
  static const String noSuggestionsAvailable = 'No suggestions available. Try again later.';
  static const String checkYourApiKey = 'Check your API key.';
  static const String downloadInProgress = 'Download in progress...';
  static const String downloadFailed = 'Download failed';
  static const String exportFailed = 'Export failed';
  static const String importFailed = 'Import failed';
  static const String failedToDeleteModel = 'Failed to delete model';
  static const String errorResettingApp = 'Error resetting app';

  // Success Messages
  static const String savedSuccessfully = 'Saved successfully!';
  static const String deletedSuccessfully = 'Deleted successfully';
  static const String progressUpdated = 'Progress updated to';
  static const String entryUpdated = 'Entry updated';
  static const String entryDeleted = 'Entry deleted';
  static const String pulseEntryDeleted = 'Pulse entry deleted';
  static const String milestoneAdded = 'Milestone added';
  static const String milestoneCompleted = 'completed!';
  static const String milestonesAdded = 'milestone(s) added!';
  static const String goalDeleted = 'Goal deleted';
  static const String goalCreatedSuccessfully = 'Goal created successfully';
  static const String goalCreatedWithMilestones = 'Goal created with';
  static const String habitCreatedSuccessfully = 'Habit created successfully! 🎯';
  static const String reminderAdded = 'Reminder added:';
  static const String reminderUpdated = 'Reminder updated';
  static const String reminderDeleted = 'Reminder deleted';
  static const String modelDownloadedSuccessfully = 'Model downloaded successfully!';
  static const String modelDeletedSuccessfully = 'Model deleted successfully';
  static const String backupSaved = 'Backup Saved';
  static const String importSuccessful = 'Import Successful';
  static const String appResetSuccessfully = 'App reset successfully. Welcome back!';
  static const String logsCopiedToClipboard = 'Logs copied to clipboard';
  static const String logsExportedAs = 'Logs exported as';

  // Dialog Titles
  static const String deleteGoalTitle = 'Delete Goal?';
  static const String deleteModel = 'Delete Model?';
  static const String deleteReminder = 'Delete Reminder?';
  static const String clearAllLogs = 'Clear All Logs?';
  static const String resetAppTitle = 'Reset App?';

  // Confirmation Messages
  static const String thisActionCannotBeUndone = 'This action cannot be undone.';
  static const String permanentlyDeleteJournalEntry = 'This will permanently delete this journal entry. This action cannot be undone.';
  static const String permanentlyDeletePulseEntry = 'This will permanently delete this pulse entry. This action cannot be undone.';
  static const String areYouSureDeleteGoal = 'Are you sure you want to delete this goal? This action cannot be undone.';
  static const String permanentlyDeleteDebugLogs = 'This will permanently delete all debug logs. This action cannot be undone.';
  static const String thisWillPermanentlyDelete = 'This will permanently delete:';
  static const String allGoalsAndMilestones = 'All goals and milestones';
  static const String allJournalEntries = 'All journal entries';
  static const String allHabitsAndCheckIns = 'All habits and check-ins';
  static const String allPulseEntries = 'All pulse entries';
  static const String allChatConversations = 'All chat conversations';
  static const String allAppSettings = 'All app settings';
  static const String exportBackupFirst = 'Export a backup first to save your data!';
  static const String deleteModelConfirmation = 'This will delete the downloaded Gemma model (554.6 MB). You can download it again later if needed.';

  // Empty States
  static const String noEntriesYet = 'No entries yet';
  static const String startJournaling = 'Start by reflecting on your day';
  static const String noHabitsYet = 'No habits yet';
  static const String noChallengesDetected = 'No challenges detected';
  static const String noMilestonesYet = 'No milestones yet';
  static const String breakDownGoal = 'Break down your goal into smaller steps';
  static const String noRemindersScheduled = 'No reminders scheduled';
  static const String addYourFirstReminder = 'Add your first reminder to get started';
  static const String noMatchingEntries = 'No matching entries';
  static const String tryAdjustingSearchOrFilter = 'Try adjusting your search or filter';
  static const String noLogsToDisplay = 'No logs to display';

  // Home Screen Strings
  static const String yourJourneyBegins = 'Your Journey Begins!';
  static const String dailyReflectionHabitCreated = 'Daily Reflection Habit Created';
  static const String startReflecting = 'Start Reflecting';
  static const String notificationsAreDisabled = 'Notifications are currently disabled.';
  static const String wontReceiveRemindersUntilEnabled = 'You won\'t receive mentor reminders until you enable them.';
  static const String tapOpenSettingsNotifications = 'Tap "Open Settings" to enable notifications in Android settings.';
  static const String exactAlarmsDisabled = 'Exact alarms are currently disabled.';
  static const String scheduledRemindersWontWork = 'Your scheduled reminders won\'t work until you enable exact alarms.';
  static const String tapOpenSettingsAlarms = 'Tap "Open Settings" to enable "Alarms & reminders" in Android settings.';
  static const String permissionsEnabled = '✅ Permissions enabled!';
  static const String openSettings = 'Open Settings';
  static const String aiNotConfigured = 'AI Not Configured';
  static const String aiFeaturesCurrentlyUnavailable = 'AI features are currently unavailable.';
  static const String youNeedToConfigure = 'You need to configure either:';
  static const String cloudAiEnterApiKey = '• Cloud AI - Enter your Claude API key';
  static const String localAiDownloadModel = '• Local AI - Download the on-device model';
  static const String tapConfigureAi = 'Tap "Configure AI" to set up AI features in Settings.';
  static const String configureAi = 'Configure AI';

  // Notifications
  static const String timeToReflect = 'Time to reflect';
  static const String challengesDetectedNotification = 'AI Mentor detected new challenges';

  // AI Settings Strings
  static const String aiProvider = 'AI Provider';
  static const String chooseProvider = 'Choose between on-device AI (private, offline) or cloud AI (more powerful)';
  static const String provider = 'Provider';
  static const String claudeApiKey = 'Claude API Key';
  static const String requiredForClaudeAi = 'Required for accessing Claude AI';
  static const String showApiKey = 'Show API key';
  static const String hideApiKey = 'Hide API key';
  static const String howToGetApiKey = 'How to get an API key';
  static const String toUseClaudeAi = 'To use Claude AI, you need an API key:';
  static const String createAccountAnthropic = 'Create account at console.anthropic.com';
  static const String navigateToApiKeys = 'Navigate to API Keys section';
  static const String createNewApiKey = 'Create a new API key';
  static const String copyAndPasteHere = 'Copy and paste it here';
  static const String apiKeyStoredSecurely = 'Your API key is stored securely on your device and used only for Claude AI requests.';
  static const String huggingFaceToken = 'HuggingFace Token';
  static const String enterHuggingFaceToken = 'Enter your HuggingFace token';
  static const String requiredForGemmaModels = 'Required for downloading Gemma models';
  static const String showToken = 'Show token';
  static const String hideToken = 'Hide token';
  static const String howToGetToken = 'How to get a token';
  static const String tokenStoredSecurely = 'Your token is stored securely on your device and only used for model downloads.';
  static const String selectClaudeModel = 'Select which Claude model to use for AI features';
  static const String model = 'Model';
  static const String modelDownloadRequired = 'Model Download Required';
  static const String gemmaDownloadDescription = 'Gemma 3-1B-IT (554.6 MB) needs to be downloaded for on-device AI. This is a one-time download. Powered by Google LiteRT LLM.';
  static const String largeDownloadWakeLock = 'Large download - wake lock will keep your phone awake. You can leave this screen during download.';
  static const String enterTokenFirst = 'Enter Token First';
  static const String downloadModel = 'Download Model (554.6 MB)';
  static const String downloadingModel = 'Downloading Model...';
  static const String modelDownloadedReady = 'Model downloaded and ready!';
  static const String modelLoadsOnAppOpen = 'Model loads when app opens (10-30 seconds). Subsequent uses are fast until app is closed.';

  // Test Connection Strings
  static const String testConnection = 'Test Connection';
  static const String sendTestMessage = 'Send a simple test message to verify your AI settings are working correctly';
  static const String firstTestMayTake = 'First test may take 10-30 seconds as the model loads into memory. Subsequent responses will be much faster until the app is closed.';
  static const String testCloudConnection = 'Test Cloud Connection';
  static const String testLocalModel = 'Test Local Model';
  static const String testSuccessful = 'Test Successful';
  static const String testFailed = 'Test Failed';
  static const String responseTime = 'Response Time';
  static const String response = 'Response:';

  // Backup & Restore Strings
  static const String aboutBackups = 'About Backups';
  static const String backupsDescription = 'Backups include all your goals, journal entries, habits, check-ins, pulse checks, and chat conversations. Export your data for safekeeping or transfer to another device.';
  static const String exportData = 'Export Data';
  static const String saveCopyOfData = 'Save a copy of all your data to a file';
  static const String exportAllData = 'Export All Data';
  static const String importData = 'Import Data';
  static const String restoreFromBackup = 'Restore your data from a backup file';
  static const String importFromBackup = 'Import from Backup';
  static const String importingBackupWarning = 'Importing a backup will replace all your current data. Make sure to export your current data first if you want to keep it.';
  static const String yourBackupSavedTo = 'Your backup has been saved to:';
  static const String dataRestoredFromBackup = 'Your data has been restored from the backup. All your goals, journal entries, habits, and check-ins have been updated.';

  // Auto Backup Location Strings
  static const String autoBackupLocation = 'Auto-Backup Location';
  static const String chooseBackupLocation = 'Choose where automatic backups are saved';
  static const String internalStorage = 'Internal Storage';
  static const String internalStorageDescription = 'Private and secure. Deleted when app is uninstalled.';
  static const String downloadsFolder = 'Downloads Folder';
  static const String downloadsFolderDescription = 'Public folder. Persists after uninstall. Easy to find.';
  static const String customFolder = 'Custom Folder';
  static const String customFolderDescription = 'Choose your own backup location.';
  static const String selectCustomFolder = 'Select Custom Folder';
  static const String customFolderNotSet = 'Custom folder not set';
  static const String backupLocationUpdated = 'Backup location updated';
  static const String currentBackupPath = 'Current backup path';
  static const String notAvailable = 'Not available';

  // Reminder Strings
  static const String scheduleTimesForReminders = 'Schedule times when your mentor will send you a reminder to check in. The contextual guidance appears when you open the app.';
  static const String considerFewerReminders = 'Consider Fewer Reminders';
  static const String mostPeopleFindReminders = 'Most people find 1-3 daily reminders works best. Too many reminders can become noise rather than helpful nudges.\n\nAre you sure you want to add another reminder?';
  static const String selectReminderTime = 'Select reminder time';
  static const String reminderLabel = 'Reminder Label';
  static const String reminderLabelHint = 'e.g., Morning Planning, Evening Reflection';
  static const String addReminder = 'Add Reminder';
  static const String morningCheckIn = 'Morning Check-in';
  static const String middayReflection = 'Midday Reflection';
  static const String eveningReflection = 'Evening Reflection';
  static const String removeReminder = 'Remove "%s" reminder?';
  static const String tipReminders = 'Tip: Most people find 1-2 daily reminders most effective for building consistent habits.';
  static const String nextReminder = 'Next Reminder';
  static const String nextReminders = 'Next Reminders';
  static const String manageReminders = 'Manage Reminders';
  static const String notificationsDisabled = 'Notifications Disabled';
  static const String enableNotificationsToReceiveReminders = 'Enable notifications to receive reminders';
  static const String enableExactAlarmsToReceiveReminders = 'Enable exact alarms to receive scheduled reminders';

  // Debug Console Strings
  static const String copyToClipboard = 'Copy to Clipboard';
  static const String exportLogs = 'Export Logs';
  static const String exportAsText = 'Export as Text';
  static const String exportAsJson = 'Export as JSON';
  static const String clearLogs = 'Clear Logs';
  static const String total = 'Total';
  static const String debug = 'Debug';
  static const String info = 'Info';
  static const String warning = 'Warning';
  static const String error = 'Error';
  static const String apiCalls = 'API Calls:';
  static const String searchLogs = 'Search logs...';
  static const String allLevels = 'All Levels';
  static const String allCategories = 'All Categories';
  static const String showingLogs = 'Showing %d log(s)';
  static const String autoScroll = 'Auto-scroll';
  static const String metadata = 'Metadata:';
  static const String stackTrace = 'Stack Trace:';

  // Reflection Session Strings
  static const String reflectionSession = 'Reflection Session';
  static const String startReflectionSession = 'Start Reflection Session';
  static const String deeperReflection = 'Deeper Reflection';
  static const String reflectionSessionDescription = 'A guided conversation to explore what\'s on your mind and discover helpful practices';
  static const String letsReflectTogether = 'Let\'s reflect together';
  static const String whatsBenOnYourMind = 'What\'s been on your mind lately?';
  static const String howAreYouFeelingRightNow = 'How are you feeling right now?';
  static const String tellMeMore = 'Tell me more...';
  static const String takeYourTime = 'Take your time. There\'s no rush.';
  static const String patternsNoticed = 'Patterns Noticed';
  static const String basedOnWhatYouShared = 'Based on what you shared, I noticed some patterns that many people experience:';
  static const String doesThisResonate = 'Does this resonate with you?';
  static const String recommendedPractices = 'Recommended Practices';
  static const String basedOnPatterns = 'Based on what we explored, here are some evidence-based techniques that might help:';
  static const String selectPracticeToTry = 'Select a practice you\'d like to try';
  static const String createHabitForPractice = 'Create a habit for this practice';
  static const String howToPractice = 'How to practice';
  static const String sessionComplete = 'Session Complete';
  static const String reflectionSaved = 'Your reflection has been saved to your journal';
  static const String scheduleFollowUp = 'Schedule Follow-up';
  static const String wouldYouLikeToSchedule = 'Would you like to schedule a follow-up reflection session?';
  static const String notRightNow = 'Not right now';
  static const String safetyDisclaimer = 'This is a self-reflection tool, not therapy. If you\'re experiencing a crisis, please reach out to a mental health professional or crisis line.';
  static const String crisisResourcesTitle = 'Crisis Resources';
  static const String crisisResourcesMessage = 'If you\'re in crisis or having thoughts of self-harm, please reach out:\n\n• National Suicide Prevention Lifeline: 988\n• Crisis Text Line: Text HOME to 741741\n• International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/';
  static const String skipQuestion = 'Skip this question';
  static const String endSessionEarly = 'End session early';
  static const String sessionSummary = 'Session Summary';
  static const String keyThemesExplored = 'Key themes explored';
  static const String interventionSelected = 'Practice selected';
  static const String noPatternDetectedMessage = 'I didn\'t detect any specific patterns from our conversation, but that\'s okay. Sometimes reflection itself is valuable.';
  static const String generalWellnessRecommendation = 'Here are some general practices that support wellbeing:';

  // Agentic Action Confirmation
  static const String actionsTaken = 'Actions Taken';
  static const String doIt = 'Do It';
  static const String errorExecutingAction = 'Error executing action';

  // Action Success Messages (additional ones - reuse existing constants where available)
  static const String checkInTemplateCreated = 'Check-in template created!';
  static const String goalMovedToBacklog = 'Goal moved to backlog';
  static const String goalActivated = 'Goal activated!';
  static const String goalMarkedComplete = 'Goal marked as complete!';
  static const String sessionSavedToJournal = 'Session saved to journal';
  static const String followUpReminderScheduled = 'Follow-up reminder scheduled';
  static const String actionCompletedSuccessfully = 'Action completed successfully';

  // Helper function to get time-appropriate greeting
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return goodMorning;
    if (hour < 17) return goodAfternoon;
    return goodEvening;
  }

  // Helper function for pluralization
  static String pluralize(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }

  // Helper for greeting with name
  static String greetingWithName(String name) {
    return '${getGreeting()}, ${name.isEmpty ? "there" : name}';
  }

  // Helper for reminder time descriptions
  static String alsoTodayAt(String label, String time) {
    return 'Also today: $label at $time';
  }

  static String tomorrowAt(String label, String time) {
    return 'Tomorrow: $label at $time';
  }

  // Helper for completed count
  static String completedCount(int count) {
    return 'Completed ($count)';
  }

  // Helper for established routines count
  static String establishedRoutinesCount(int count) {
    return 'Established Routines ($count)';
  }
}
