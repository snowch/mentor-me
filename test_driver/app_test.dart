// test_driver/app_test.dart
// Gherkin test configuration and runner
// This file configures how Gherkin tests are executed

import 'dart:async';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';

// Import step definitions
import '../test/steps/common_steps.dart';
import '../test/steps/goal_steps.dart';

Future<void> main() {
  final config = FlutterTestConfiguration()
    // Specify feature files to run
    ..features = [RegExp(r'test/features/.*\.feature')]

    // Reporters (what output to generate)
    ..reporters = [
      ProgressReporter(), // Console progress dots
      TestRunSummaryReporter(), // Final summary
      JsonReporter(path: './reports/gherkin-report.json'), // JSON report
    ]

    // Register all step definitions
    ..stepDefinitions = [
      // Common steps (reusable across features)
      GivenTheAppIsRunning(),
      GivenIAmOnHomeScreen(),
      WhenITapOn(),
      WhenITapGoalToViewDetails(),
      WhenINavigateToGoalDetails(),
      WhenITapMenuButton(),
      WhenISelect(),
      WhenIConfirmDeletion(),
      WhenIWaitForAIGeneration(),
      WhenICloseApp(),
      WhenIRestartApp(),
      ThenIShouldSee(),
      ThenIShouldSeeAtLeastMilestones(),
      ThenMilestonesShouldHaveTitleAndDescription(),
      ThenShouldNotAppearInList(),
      ThenShouldNotAppearInActiveGoals(),
      ThenGoalShouldAppearIn(),
      ThenIShouldStillSeeAllGoals(),
      ThenDataShouldBePreserved(),
      ThenGoalShouldBeTaggedWithCategory(),
      ThenIShouldBeAbleToFilterBy(),

      // Goal-specific steps
      GivenIHaveAnActiveGoal(),
      GivenIHaveAGoalWithMilestones(),
      GivenIHaveAGoalWithProgress(),
      WhenINavigateToGoalsScreen(),
      WhenITapButton(),
      WhenIEnterGoalTitle(),
      WhenIEnterDescription(),
      WhenISelectCategory(),
      WhenIAddMilestones(),
      WhenIMarkMilestoneComplete(),
      WhenICreateGoalInCategory(),
      ThenIShouldSeeGoalInList(),
      ThenGoalStatusShouldBe(),
      ThenGoalProgressShouldBe(),
      ThenGoalShouldHaveMilestones(),
      ThenAllMilestonesShouldBeIncomplete(),
      ThenMilestoneShouldBeCompleted(),
      ThenGoalShouldHaveCompletionDate(),
    ]

    // Custom parameter definitions (for parsing custom types)
    ..customStepParameterDefinitions = []

    // Hooks - run before/after scenarios
    ..hooks = [
      // Hook: Take screenshot on test failure
      OnAfterScenarioWorldHook(
        (config, world, hookContext) async {
          if (hookContext.result == StepResult.fail ||
              hookContext.result == StepResult.error) {
            // Take screenshot on failure
            print('Test failed: ${hookContext.scenario}');
            // await takeScreenshot(world);
          }
        },
      ),
    ]

    // Test execution settings
    ..restartAppBetweenScenarios = true // Fresh app state for each scenario
    ..targetAppPath = "test_driver/app.dart" // Path to app entry point
    ..exitAfterTestRun = true // Exit process after tests complete

    // Timeouts
    ..defaultTimeout = const Duration(seconds: 30)
    ..stepMaximumTimeout = const Duration(seconds: 60)

    // Feature file tag filtering
    // Run with: flutter drive --target=test_driver/app.dart --tags="@critical"
    ..tagExpression = '' // Empty = run all, or specify tags like "@critical and not @wip"

    // Build mode
    ..build = BuildMode.debug // or BuildMode.release

    // Verbosity
    ..verboseFlutterProcessLogs = false // Set true for debugging
    ..logFlutterProcessOutput = false; // Set true for debugging

  return GherkinRunner().execute(config);
}

/// Custom hook to take screenshots on test failure
class OnAfterScenarioWorldHook extends Hook {
  final Future<void> Function(
    TestConfiguration config,
    World world,
    HookContext hookContext,
  ) _onAfterScenario;

  OnAfterScenarioWorldHook(this._onAfterScenario) : super(StepDefinitionGenericType.scenario);

  @override
  int get priority => 999;

  @override
  Future<void> onAfterScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags, {
    bool passed = true,
  }) async {
    // Implementation would go here
  }
}
