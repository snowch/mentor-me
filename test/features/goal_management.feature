Feature: Goal Management
  As a user
  I want to create and manage goals with milestones
  So that I can track my progress toward meaningful achievements

  Background:
    Given the app is running
    And I am on the home screen

  @integration @critical
  Scenario: Create a new goal successfully
    When I navigate to the goals screen
    And I tap the "Add Goal" button
    And I enter "Launch my website" as the goal title
    And I enter "Build and deploy my personal portfolio site" as the description
    And I select "Career" as the category
    And I tap the "Save" button
    Then I should see "Launch my website" in my goals list
    And the goal should be in "Active" status
    And the goal should have 0% progress

  @integration
  Scenario: Add milestones to a goal
    Given I have an active goal "Launch my website"
    When I tap on the goal to view details
    And I tap the "Add Milestone" button
    And I add the following milestones:
      | Milestone                  | Target Date |
      | Design wireframes          | 2025-02-01  |
      | Build landing page         | 2025-02-15  |
      | Deploy to production       | 2025-03-01  |
    Then the goal should have 3 milestones
    And all milestones should be incomplete
    And the goal progress should still be 0%

  @integration @critical
  Scenario: Complete a milestone and update goal progress
    Given I have a goal "Launch my website" with the following milestones:
      | Milestone                  | Completed |
      | Design wireframes          | false     |
      | Build landing page         | false     |
      | Deploy to production       | false     |
    When I navigate to the goal details
    And I mark "Design wireframes" as complete
    Then the milestone "Design wireframes" should be marked as completed
    And the goal progress should be approximately 33%

  @integration
  Scenario: Complete a goal
    Given I have a goal "Read 5 books" with progress 80%
    When I navigate to the goal details
    And I tap the "Complete Goal" button
    Then the goal status should be "Completed"
    And the goal should have a completion date
    And the goal should no longer appear in my active goals
    And the goal should appear in my completed goals list

  @integration
  Scenario: Move goal to backlog
    Given I have an active goal "Learn Spanish"
    When I navigate to the goal details
    And I tap the menu button
    And I select "Move to Backlog"
    Then the goal status should be "Backlog"
    And the goal should not appear in my active goals
    And the goal should appear in my backlog

  @integration @critical
  Scenario: AI-powered milestone generation
    Given I have a goal "Write a novel" with no milestones
    When I navigate to the goal details
    And I tap the "Generate Milestones" button
    And I wait for AI to generate suggestions
    Then I should see at least 3 milestone suggestions
    And each milestone should have a title and description
    And I should be able to accept or edit the suggestions

  @integration
  Scenario: Link journal entry to goal
    Given I have an active goal "Morning meditation habit"
    When I navigate to the journal screen
    And I create a quick note "Meditated for 10 minutes today"
    And I link the entry to "Morning meditation habit"
    Then the journal entry should be linked to the goal
    And I should see the entry when viewing the goal details

  @integration @critical
  Scenario Outline: Create goals in different categories
    When I navigate to the goals screen
    And I create a goal "<title>" in category "<category>"
    Then the goal should appear in my goals list
    And the goal should be tagged with category "<category>"
    And I should be able to filter goals by "<category>"

    Examples:
      | title                      | category  |
      | Morning meditation         | Personal  |
      | Launch startup             | Career    |
      | Run 5k race                | Health    |
      | Learn guitar               | Learning  |

  @integration @regression
  Scenario: Delete a goal
    Given I have a goal "Old goal to remove"
    When I navigate to the goal details
    And I tap the menu button
    And I select "Delete Goal"
    And I confirm the deletion
    Then the goal should no longer appear in any goals list
    And the goal should be permanently removed

  @integration @regression
  Scenario: Persist goals across app restarts
    Given I have created 3 goals today
    When I close the app
    And I restart the app
    Then I should still see all 3 goals
    And all goal data should be preserved
    And all milestones should be preserved
