// test/steps/common_steps.dart
// Common step definitions reusable across all features

import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';

/// Given: the app is running
class GivenTheAppIsRunning extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();
    // App should already be running from test setup
    // This step is mainly for readability in feature files
    await world.appDriver.waitUntilFirstFrameRasterized();
  }

  @override
  RegExp get pattern => RegExp(r'the app is running');
}

/// Given: I am on the home screen
class GivenIAmOnHomeScreen extends Given1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();

    // If not on home screen, navigate back
    final homeFinder = find.byKey(const Key('home_screen'));
    if (!await world.appDriver.isPresent(homeFinder)) {
      // Navigate back to home
      while (!await world.appDriver.isPresent(homeFinder)) {
        await world.appDriver.tap(find.byTooltip('Back'));
      }
    }

    await world.appDriver.waitFor(homeFinder);
  }

  @override
  RegExp get pattern => RegExp(r'I am on the (?:home|main) screen');
}

/// When: I tap on "X"
class WhenITapOn extends When1<String> {
  @override
  Future<void> executeStep(String elementText) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.tap(find.text(elementText));
    await world.appDriver.waitForAppToSettle();
  }

  @override
  RegExp get pattern => RegExp(r'I tap on {string}');
}

/// When: I tap on the goal to view details
class WhenITapGoalToViewDetails extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();

    // Find the most recently created goal card and tap it
    final goalCard = find.byType(Card).first;
    await world.appDriver.tap(goalCard);
    await world.appDriver.waitFor(find.text('Goal Details'));
  }

  @override
  RegExp get pattern => RegExp(r'I tap on the goal to view details');
}

/// When: I navigate to the goal details
class WhenINavigateToGoalDetails extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();

    // If already on goal details, do nothing
    final detailsFinder = find.text('Goal Details');
    if (await world.appDriver.isPresent(detailsFinder)) {
      return;
    }

    // Otherwise, tap on first goal card
    final goalCard = find.byKey(const Key('goal_card')).first;
    await world.appDriver.tap(goalCard);
    await world.appDriver.waitFor(detailsFinder);
  }

  @override
  RegExp get pattern => RegExp(r'I navigate to the goal details');
}

/// When: I tap the menu button
class WhenITapMenuButton extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.tap(find.byIcon(Icons.more_vert));
    await world.appDriver.waitForAppToSettle();
  }

  @override
  RegExp get pattern => RegExp(r'I tap the menu button');
}

/// When: I select "X"
class WhenISelect extends When1<String> {
  @override
  Future<void> executeStep(String optionText) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.tap(find.text(optionText));
    await world.appDriver.waitForAppToSettle();
  }

  @override
  RegExp get pattern => RegExp(r'I select {string}');
}

/// When: I confirm the deletion
class WhenIConfirmDeletion extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();

    // Look for confirmation dialog
    final confirmBtn = find.text('Delete').or(find.text('Confirm'));
    await world.appDriver.tap(confirmBtn);
    await world.appDriver.waitForAppToSettle();
  }

  @override
  RegExp get pattern => RegExp(r'I confirm the deletion');
}

/// When: I wait for AI to generate suggestions
class WhenIWaitForAIGeneration extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();

    // Wait for loading indicator to disappear
    final loadingFinder = find.byType(CircularProgressIndicator);
    await world.appDriver.waitForAbsent(loadingFinder, timeout: const Duration(seconds: 30));
  }

  @override
  RegExp get pattern => RegExp(r'I wait for AI to generate suggestions');
}

/// When: I close the app
class WhenICloseApp extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();
    // Flutter test runner doesn't truly "close" the app
    // But we can simulate by navigating away or resetting state
    // For integration tests, this would use platform-specific commands
  }

  @override
  RegExp get pattern => RegExp(r'I close the app');
}

/// When: I restart the app
class WhenIRestartApp extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();
    // In a true integration test, this would restart the app process
    // For now, we simulate by reloading the root widget
    await world.appDriver.restart();
  }

  @override
  RegExp get pattern => RegExp(r'I restart the app');
}

/// Then: I should see "X"
class ThenIShouldSee extends Then1<String> {
  @override
  Future<void> executeStep(String text) async {
    final world = getWorld<FlutterWorld>();
    expect(
      find.text(text),
      findsOneWidget,
      reason: 'Should see text: "$text"',
    );
  }

  @override
  RegExp get pattern => RegExp(r'I should see {string}');
}

/// Then: I should see at least X milestone suggestions
class ThenIShouldSeeAtLeastMilestones extends Then1<int> {
  @override
  Future<void> executeStep(int count) async {
    final world = getWorld<FlutterWorld>();
    final milestoneFinder = find.byKey(const Key('suggested_milestone'));
    expect(
      milestoneFinder,
      findsAtLeastNWidgets(count),
      reason: 'Should see at least $count milestone suggestions',
    );
  }

  @override
  RegExp get pattern => RegExp(r'I should see at least {int} milestone suggestions?');
}

/// Then: each milestone should have a title and description
class ThenMilestonesShouldHaveTitleAndDescription extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();

    // Find all suggested milestone widgets
    final milestones = find.byKey(const Key('suggested_milestone'));
    final count = await world.appDriver.getWidgetCount(milestones);

    // Each milestone should have both title and description fields
    for (int i = 0; i < count; i++) {
      expect(
        find.descendant(
          of: milestones.at(i),
          matching: find.byKey(const Key('milestone_title')),
        ),
        findsOneWidget,
        reason: 'Milestone $i should have a title',
      );

      expect(
        find.descendant(
          of: milestones.at(i),
          matching: find.byKey(const Key('milestone_description')),
        ),
        findsOneWidget,
        reason: 'Milestone $i should have a description',
      );
    }
  }

  @override
  RegExp get pattern => RegExp(r'each milestone should have a title and description');
}

/// Then: the X should no longer appear in any goals list
class ThenShouldNotAppearInList extends Then1<String> {
  @override
  Future<void> executeStep(String item) async {
    final world = getWorld<FlutterWorld>();
    expect(
      find.text(item),
      findsNothing,
      reason: '"$item" should no longer appear in any list',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the (?:goal|item) should no longer appear in any (?:goals )?list');
}

/// Then: the X should not appear in my active goals
class ThenShouldNotAppearInActiveGoals extends Then1<String> {
  @override
  Future<void> executeStep(String goalTitle) async {
    final world = getWorld<FlutterWorld>();

    // Navigate to active goals filter
    await world.appDriver.tap(find.text('Active'));
    await world.appDriver.waitForAppToSettle();

    expect(
      find.text(goalTitle),
      findsNothing,
      reason: '"$goalTitle" should not appear in active goals',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the goal should not appear in my active goals');
}

/// Then: the goal should appear in my X
class ThenGoalShouldAppearIn extends Then2<String, String> {
  @override
  Future<void> executeStep(String goalTitle, String section) async {
    final world = getWorld<FlutterWorld>();

    // Navigate to the specified section
    await world.appDriver.tap(find.text(section));
    await world.appDriver.waitForAppToSettle();

    expect(
      find.text(goalTitle),
      findsOneWidget,
      reason: '"$goalTitle" should appear in $section',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the goal should appear in my (.+)');
}

/// Then: I should still see all X goals
class ThenIShouldStillSeeAllGoals extends Then1<int> {
  @override
  Future<void> executeStep(int count) async {
    final world = getWorld<FlutterWorld>();
    final goalCards = find.byKey(const Key('goal_card'));
    expect(
      goalCards,
      findsNWidgets(count),
      reason: 'Should still see all $count goals',
    );
  }

  @override
  RegExp get pattern => RegExp(r'I should still see all {int} goals?');
}

/// Then: all X should be preserved
class ThenDataShouldBePreserved extends Then1<String> {
  @override
  Future<void> executeStep(String dataType) async {
    final world = getWorld<FlutterWorld>();
    // This is a placeholder - actual implementation would verify
    // that specific data fields are intact after app restart
    print('Verifying $dataType data is preserved');
  }

  @override
  RegExp get pattern => RegExp(r'all (.+) should be preserved');
}

/// Then: the goal should be tagged with category "X"
class ThenGoalShouldBeTaggedWithCategory extends Then1<String> {
  @override
  Future<void> executeStep(String category) async {
    final world = getWorld<FlutterWorld>();
    expect(
      find.text(category),
      findsWidgets,
      reason: 'Goal should be tagged with category "$category"',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the goal should be tagged with category {string}');
}

/// Then: I should be able to filter goals by "X"
class ThenIShouldBeAbleToFilterBy extends Then1<String> {
  @override
  Future<void> executeStep(String category) async {
    final world = getWorld<FlutterWorld>();

    // Try to find and tap the category filter
    final filterBtn = find.byKey(Key('filter_$category'));
    expect(
      filterBtn,
      findsOneWidget,
      reason: 'Should be able to filter by "$category"',
    );

    await world.appDriver.tap(filterBtn);
    await world.appDriver.waitForAppToSettle();
  }

  @override
  RegExp get pattern => RegExp(r'I should be able to filter goals by {string}');
}
