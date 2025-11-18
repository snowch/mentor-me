// test/steps/goal_steps.dart
// Step definitions for goal management feature tests

import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';

/// Given: I have an active goal "Launch my website"
class GivenIHaveAnActiveGoal extends Given1<String> {
  @override
  Future<void> executeStep(String goalTitle) async {
    final world = getWorld<FlutterWorld>();

    // Navigate to goals screen
    await world.appDriver.tap(find.byKey(const Key('goals_tab')));
    await world.appDriver.waitFor(find.text('Goals'));

    // Create a goal programmatically via provider
    // This is faster than UI interaction for setup
    // Implementation would use the provider directly

    // For now, we'll use UI to create it
    await world.appDriver.tap(find.byIcon(Icons.add));
    await world.appDriver.waitFor(find.text('Create Goal'));

    await world.appDriver.enterText(
      find.byKey(const Key('goal_title_field')),
      goalTitle,
    );

    await world.appDriver.tap(find.text('Save'));
    await world.appDriver.waitFor(find.text(goalTitle));
  }

  @override
  RegExp get pattern => RegExp(r'I have an active goal {string}');
}

/// Given: I have a goal "X" with the following milestones:
class GivenIHaveAGoalWithMilestones extends Given2<String, Table> {
  @override
  Future<void> executeStep(String goalTitle, Table dataTable) async {
    final world = getWorld<FlutterWorld>();

    // First create the goal
    await world.appDriver.tap(find.byKey(const Key('goals_tab')));
    await world.appDriver.tap(find.byIcon(Icons.add));
    await world.appDriver.enterText(
      find.byKey(const Key('goal_title_field')),
      goalTitle,
    );
    await world.appDriver.tap(find.text('Save'));

    // Navigate to goal details
    await world.appDriver.tap(find.text(goalTitle));

    // Add milestones from data table
    for (final row in dataTable.rows.skip(1)) {  // Skip header
      final milestoneTitle = row.columns[0];
      final isCompleted = row.columns[1].toLowerCase() == 'true';

      await world.appDriver.tap(find.byKey(const Key('add_milestone_btn')));
      await world.appDriver.enterText(
        find.byKey(const Key('milestone_title_field')),
        milestoneTitle,
      );
      await world.appDriver.tap(find.text('Add'));

      if (isCompleted) {
        await world.appDriver.tap(
          find.byKey(Key('milestone_checkbox_$milestoneTitle')),
        );
      }
    }
  }

  @override
  RegExp get pattern => RegExp(r'I have a goal {string} with the following milestones:');
}

/// Given: I have a goal "X" with progress Y%
class GivenIHaveAGoalWithProgress extends Given2<String, String> {
  @override
  Future<void> executeStep(String goalTitle, String progressStr) async {
    final world = getWorld<FlutterWorld>();
    final progress = int.parse(progressStr.replaceAll('%', ''));

    // Create goal with appropriate number of completed milestones
    // to reach the desired progress percentage
    // Implementation would calculate milestone completion

    await world.appDriver.tap(find.byKey(const Key('goals_tab')));
    // ... create goal and milestones to match progress
  }

  @override
  RegExp get pattern => RegExp(r'I have a goal {string} with progress {int}%');
}

/// When: I navigate to the goals screen
class WhenINavigateToGoalsScreen extends When1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.tap(find.byKey(const Key('goals_tab')));
    await world.appDriver.waitFor(find.text('Goals'));
  }

  @override
  RegExp get pattern => RegExp(r'I navigate to the goals screen');
}

/// When: I tap the "X" button
class WhenITapButton extends When1<String> {
  @override
  Future<void> executeStep(String buttonText) async {
    final world = getWorld<FlutterWorld>();

    // Try to find by text first
    final textFinder = find.text(buttonText);
    if (await world.appDriver.isPresent(textFinder)) {
      await world.appDriver.tap(textFinder);
      return;
    }

    // Try common button keys
    final keyMap = {
      'Add Goal': 'add_goal_btn',
      'Save': 'save_btn',
      'Complete Goal': 'complete_goal_btn',
      'Generate Milestones': 'generate_milestones_btn',
      'Add Milestone': 'add_milestone_btn',
    };

    final key = keyMap[buttonText];
    if (key != null) {
      await world.appDriver.tap(find.byKey(Key(key)));
    } else {
      // Fallback: find by icon or text
      await world.appDriver.tap(find.text(buttonText));
    }
  }

  @override
  RegExp get pattern => RegExp(r'I tap the {string} button');
}

/// When: I enter "X" as the goal title
class WhenIEnterGoalTitle extends When1<String> {
  @override
  Future<void> executeStep(String title) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.enterText(
      find.byKey(const Key('goal_title_field')),
      title,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I enter {string} as the goal title');
}

/// When: I enter "X" as the description
class WhenIEnterDescription extends When1<String> {
  @override
  Future<void> executeStep(String description) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.enterText(
      find.byKey(const Key('goal_description_field')),
      description,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I enter {string} as the description');
}

/// When: I select "X" as the category
class WhenISelectCategory extends When1<String> {
  @override
  Future<void> executeStep(String category) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.tap(find.byKey(const Key('category_dropdown')));
    await world.appDriver.tap(find.text(category));
  }

  @override
  RegExp get pattern => RegExp(r'I select {string} as the category');
}

/// When: I add the following milestones:
class WhenIAddMilestones extends When1WithWorld<Table, FlutterWorld> {
  @override
  Future<void> executeStep(Table dataTable) async {
    for (final row in dataTable.rows.skip(1)) {  // Skip header
      final milestoneTitle = row.columns[0];
      final targetDate = row.columns[1];

      await world.appDriver.tap(find.byKey(const Key('add_milestone_btn')));
      await world.appDriver.waitFor(find.text('Add Milestone'));

      await world.appDriver.enterText(
        find.byKey(const Key('milestone_title_field')),
        milestoneTitle,
      );

      // Set target date if provided
      if (targetDate.isNotEmpty && targetDate != '-') {
        await world.appDriver.tap(find.byKey(const Key('target_date_field')));
        // Date picker interaction would go here
      }

      await world.appDriver.tap(find.text('Add'));
      await world.appDriver.waitFor(find.text(milestoneTitle));
    }
  }

  @override
  RegExp get pattern => RegExp(r'I add the following milestones:');
}

/// When: I mark "X" as complete
class WhenIMarkMilestoneComplete extends When1<String> {
  @override
  Future<void> executeStep(String milestoneTitle) async {
    final world = getWorld<FlutterWorld>();
    await world.appDriver.tap(
      find.byKey(Key('milestone_checkbox_$milestoneTitle')),
    );
  }

  @override
  RegExp get pattern => RegExp(r'I mark {string} as complete');
}

/// When: I create a goal "X" in category "Y"
class WhenICreateGoalInCategory extends When2<String, String> {
  @override
  Future<void> executeStep(String title, String category) async {
    final world = getWorld<FlutterWorld>();

    await world.appDriver.tap(find.byIcon(Icons.add));
    await world.appDriver.waitFor(find.text('Create Goal'));

    await world.appDriver.enterText(
      find.byKey(const Key('goal_title_field')),
      title,
    );

    await world.appDriver.tap(find.byKey(const Key('category_dropdown')));
    await world.appDriver.tap(find.text(category));

    await world.appDriver.tap(find.text('Save'));
  }

  @override
  RegExp get pattern => RegExp(r'I create a goal {string} in category {string}');
}

/// Then: I should see "X" in my goals list
class ThenIShouldSeeGoalInList extends Then1<String> {
  @override
  Future<void> executeStep(String goalTitle) async {
    final world = getWorld<FlutterWorld>();
    expect(
      find.text(goalTitle),
      findsOneWidget,
      reason: 'Goal "$goalTitle" should appear in list',
    );
  }

  @override
  RegExp get pattern => RegExp(r'I should see {string} in my goals list');
}

/// Then: the goal should be in "X" status
class ThenGoalStatusShouldBe extends Then1<String> {
  @override
  Future<void> executeStep(String status) async {
    final world = getWorld<FlutterWorld>();
    // Check for status badge or indicator
    expect(
      find.text(status),
      findsWidgets,
      reason: 'Goal status should be "$status"',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the goal (?:status )?should be (?:in )?"([^"]+)"(?: status)?');
}

/// Then: the goal should have X% progress
class ThenGoalProgressShouldBe extends Then1<String> {
  @override
  Future<void> executeStep(String progressStr) async {
    final world = getWorld<FlutterWorld>();
    final expectedProgress = int.parse(progressStr.replaceAll('%', ''));

    // Find progress indicator widget
    // This would need to be implemented based on actual UI
    // For now, we'll check for text containing the percentage
    expect(
      find.textContaining('$expectedProgress%'),
      findsOneWidget,
      reason: 'Goal progress should be $expectedProgress%',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the goal (?:progress )?should (?:be|have) (?:approximately )?{int}%');
}

/// Then: the goal should have X milestones
class ThenGoalShouldHaveMilestones extends Then1<int> {
  @override
  Future<void> executeStep(int count) async {
    final world = getWorld<FlutterWorld>();

    // Find milestone widgets or list items
    final milestoneFinder = find.byKey(const Key('milestone_list_item'));
    expect(
      milestoneFinder,
      findsNWidgets(count),
      reason: 'Goal should have $count milestones',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the goal should have {int} milestones?');
}

/// Then: all milestones should be incomplete
class ThenAllMilestonesShouldBeIncomplete extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();

    // Check that no milestone checkboxes are checked
    // Implementation depends on actual UI structure
    final completedMilestones = find.byKey(const Key('milestone_completed_icon'));
    expect(
      completedMilestones,
      findsNothing,
      reason: 'All milestones should be incomplete',
    );
  }

  @override
  RegExp get pattern => RegExp(r'all milestones should be incomplete');
}

/// Then: the milestone "X" should be marked as completed
class ThenMilestoneShouldBeCompleted extends Then1<String> {
  @override
  Future<void> executeStep(String milestoneTitle) async {
    final world = getWorld<FlutterWorld>();

    // Check for completed state indicator for this milestone
    expect(
      find.byKey(Key('milestone_completed_$milestoneTitle')),
      findsOneWidget,
      reason: 'Milestone "$milestoneTitle" should be marked as completed',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the milestone {string} should be marked as completed');
}

/// Then: the goal should have a completion date
class ThenGoalShouldHaveCompletionDate extends Then1<String> {
  @override
  Future<void> executeStep(String input1) async {
    final world = getWorld<FlutterWorld>();

    // Check for completion date display
    expect(
      find.byKey(const Key('goal_completion_date')),
      findsOneWidget,
      reason: 'Goal should have a completion date',
    );
  }

  @override
  RegExp get pattern => RegExp(r'the goal should have a completion date');
}
