Feature: Backup and Restore
  As a MentorMe user
  I want to backup and restore my data
  So that I can migrate between devices, recover from data loss, or create safety backups

  Background:
    Given the app is running
    And I am on the home screen

  @integration @critical
  Scenario: Successfully backup and restore all data types
    Given I have the following test data:
      | Type            | Count |
      | Goals           | 3     |
      | Habits          | 2     |
      | Journal Entries | 5     |
      | Pulse Entries   | 7     |
      | Pulse Types     | 5     |
    When I navigate to backup and restore screen
    And I tap the "Export Backup" button
    And I save the backup file
    And I clear all app data
    And I navigate to backup and restore screen
    And I tap the "Import Backup" button
    And I select the saved backup file
    Then all goals should be restored
    And all habits should be restored
    And all journal entries should be restored
    And all pulse entries should be restored
    And all pulse types should be restored
    And the schema version should match

  @integration @critical @security
  Scenario: Backup strips sensitive data
    Given I have configured a Claude API key "sk-test-key-12345"
    And I have configured a HuggingFace token "hf-test-token-67890"
    And I have 2 active goals
    When I navigate to backup and restore screen
    And I tap the "Export Backup" button
    And I save the backup file
    Then the backup file should not contain "sk-test-key-12345"
    And the backup file should not contain "hf-test-token-67890"
    And the backup file should contain the goals data

  @integration @critical
  Scenario: Import validates backup file structure
    Given I have a backup file with invalid JSON structure
    When I navigate to backup and restore screen
    And I tap the "Import Backup" button
    And I select the invalid backup file
    Then I should see an error message "Invalid backup file format"
    And no data should be modified
    And my existing data should remain intact

  @integration @critical
  Scenario: Import validates schema version
    Given I have a backup file with unsupported schema version
    When I navigate to backup and restore screen
    And I tap the "Import Backup" button
    And I select the backup file
    Then I should see an error message about schema compatibility
    And no data should be imported

  @integration @critical
  Scenario: Restore preserves complex relationships
    Given I have a goal "Launch Website" with the following milestones:
      | Milestone              | Completed | Target Date |
      | Design wireframes      | true      | 2025-02-01  |
      | Build landing page     | true      | 2025-02-15  |
      | Set up hosting         | false     | 2025-02-20  |
      | Deploy to production   | false     | 2025-03-01  |
    And I have 3 journal entries linked to goal "Launch Website"
    And I have 2 habits with completion history
    When I export and restore the data
    Then the goal "Launch Website" should have 4 milestones
    And 2 milestones should be marked as completed
    And the goal progress should be 50%
    And all 3 journal entries should still be linked to the goal
    And all habit completion history should be preserved

  @integration
  Scenario: Backup includes metadata and statistics
    Given I have 5 goals with various statuses:
      | Goal Title        | Status    | Progress |
      | Morning routine   | active    | 60       |
      | Learn Spanish     | backlog   | 0        |
      | Read 10 books     | completed | 100      |
      | Build portfolio   | active    | 30       |
      | Meditation habit  | active    | 80       |
    And I have 10 journal entries
    And I have 3 habits
    When I export a backup
    Then the backup metadata should contain:
      | Field                 | Value |
      | schemaVersion         | 2     |
      | totalGoals            | 5     |
      | totalJournalEntries   | 10    |
      | totalHabits           | 3     |
    And the backup should include export date
    And the backup should include build information

  @integration @regression
  Scenario: Backup preserves all goal attributes
    Given I have a goal with all attributes set:
      | Attribute     | Value                              |
      | title         | Complete marathon training         |
      | description   | Train for NYC marathon in 6 months |
      | category      | Health                             |
      | status        | active                             |
      | progress      | 45                                 |
      | targetDate    | 2025-06-15                         |
    When I export and restore the data
    Then the goal should have all attributes preserved:
      | Attribute     | Value                              |
      | title         | Complete marathon training         |
      | description   | Train for NYC marathon in 6 months |
      | category      | Health                             |
      | status        | active                             |
      | progress      | 45                                 |
      | targetDate    | 2025-06-15                         |

  @integration @regression
  Scenario: Backup preserves habit streaks and completions
    Given I have a habit "Daily meditation" with:
      | Attribute       | Value |
      | currentStreak   | 15    |
      | longestStreak   | 20    |
      | status          | active|
    And the habit has completions for the last 15 days
    When I export and restore the data
    Then the habit "Daily meditation" should have currentStreak 15
    And the habit should have longestStreak 20
    And all 15 completion records should be preserved

  @integration @regression
  Scenario: Backup preserves journal entry types and prompts
    Given I have a guided journal entry with prompts:
      | Prompt                              |
      | What progress did you make today?   |
      | What challenges did you face?       |
      | What will you focus on tomorrow?    |
    And I have 2 quick note journal entries
    When I export and restore the data
    Then the guided journal entry should preserve all prompts
    And the entry type should be "guidedJournal"
    And all quick notes should have type "quickNote"

  @integration @regression
  Scenario: Backup preserves pulse/wellness metrics
    Given I have the following pulse types configured:
      | Name   | Emoji | System Defined |
      | Mood   | 😊    | true           |
      | Energy | ⚡    | true           |
      | Focus  | 🎯    | true           |
      | Custom | 💪    | false          |
    And I have 5 pulse entries with various metric values
    When I export and restore the data
    Then all 4 pulse types should be restored
    And the custom pulse type should be marked as user-defined
    And all pulse entries should preserve metric values

  @integration
  Scenario: Backup handles empty data gracefully
    Given I am a new user with no data
    When I navigate to backup and restore screen
    And I tap the "Export Backup" button
    And I save the backup file
    Then the backup should be created successfully
    And the backup should contain empty arrays for all data types
    And the backup should have valid schema structure

  @integration
  Scenario: Import handles missing optional fields
    Given I have a backup file with minimal required fields only
    When I navigate to backup and restore screen
    And I tap the "Import Backup" button
    And I select the backup file
    Then the import should succeed
    And optional fields should be set to default values
    And no errors should occur

  @integration @regression
  Scenario: Multiple backup and restore cycles preserve data integrity
    Given I have 2 goals, 3 habits, and 5 journal entries
    When I export a backup as "backup1"
    And I add 1 more goal
    And I export a backup as "backup2"
    And I clear all data
    And I import "backup1"
    Then I should see 2 goals, 3 habits, and 5 journal entries
    When I clear all data again
    And I import "backup2"
    Then I should see 3 goals, 3 habits, and 5 journal entries

  @integration @platform
  Scenario: Web platform backup downloads file
    Given I am running on web platform
    And I have 3 goals with milestones
    When I navigate to backup and restore screen
    And I tap the "Export Backup" button
    Then a JSON file should be downloaded to browser
    And the filename should contain "mentorme_backup"
    And the filename should contain the current date

  @integration @platform
  Scenario: Android platform backup saves to file system
    Given I am running on Android platform
    And I have 3 goals with milestones
    When I navigate to backup and restore screen
    And I tap the "Export Backup" button
    Then I should see a file picker to choose save location
    And the backup should be saved to the selected location

  @integration @critical
  Scenario: Import overwrites existing data with confirmation
    Given I have 5 goals with various data
    And I have a backup file containing 3 different goals
    When I navigate to backup and restore screen
    And I tap the "Import Backup" button
    And I select the backup file
    Then I should see a warning "This will replace all current data"
    When I confirm the import
    Then I should have exactly 3 goals
    And the 3 goals should match the backup data
    And my previous 5 goals should be gone

  @integration @regression
  Scenario: Backup preserves conversation history
    Given I have 2 conversations with the AI mentor
    And the first conversation has 10 messages
    And the second conversation has 5 messages
    When I export and restore the data
    Then both conversations should be restored
    And the first conversation should have 10 messages
    And the second conversation should have 5 messages
    And all message content should be preserved

  @integration @regression
  Scenario: Backup handles special characters in data
    Given I have a goal with title "🎯 Launch 'Amazing' Product (v2.0)"
    And I have a journal entry with content:
      """
      Today I learned:
      - How to handle "quotes"
      - Special chars: <>&'"
      - Unicode: 你好, مرحبا, שלום
      """
    When I export and restore the data
    Then the goal title should be exactly "🎯 Launch 'Amazing' Product (v2.0)"
    And the journal entry should preserve all special characters

  @integration @performance
  Scenario: Backup handles large datasets
    Given I have 100 goals
    And I have 500 journal entries
    And I have 50 habits
    When I navigate to backup and restore screen
    And I tap the "Export Backup" button
    Then the backup should complete within 10 seconds
    And the backup file should be created successfully
    When I import the backup
    Then the import should complete within 15 seconds
    And all 100 goals should be restored
    And all 500 journal entries should be restored
    And all 50 habits should be restored

  @integration @critical
  Scenario: Backup file is valid JSON
    Given I have 3 goals and 2 habits
    When I export a backup
    And I open the backup file
    Then the file should be valid JSON
    And the JSON should pass schema validation
    And the JSON should be human-readable

  @integration
  Scenario: User can cancel import operation
    Given I have existing data
    And I have a backup file ready to import
    When I navigate to backup and restore screen
    And I tap the "Import Backup" button
    And I select the backup file
    And I see the confirmation dialog
    And I tap "Cancel"
    Then no data should be imported
    And my existing data should remain unchanged

  @integration @regression
  Scenario: Settings are preserved across backup/restore
    Given I have configured the following settings:
      | Setting                  | Value           |
      | AI Provider              | Cloud           |
      | Selected Model           | Sonnet 4.5      |
      | Theme                    | Dark            |
    And I have configured the following mentor reminders:
      | Label              | Hour | Minute | Enabled |
      | Morning Check-in   | 8    | 0      | true    |
      | Evening Reflection | 20   | 30     | true    |
      | Afternoon Review   | 14   | 0      | false   |
    When I export and restore the data
    Then all settings should be preserved
    And all mentor reminders should be preserved
    But the Claude API key should not be restored
    And the HuggingFace token should not be restored

  @integration @regression
  Scenario: Restore works with legacy schema versions
    Given I have a backup file from schema version 1
    When I navigate to backup and restore screen
    And I tap the "Import Backup" button
    And I select the backup file
    Then the migration service should upgrade the data
    And all data should be imported successfully
    And the data should match current schema version 2

  @integration @error-handling
  Scenario: Import handles corrupted backup file gracefully
    Given I have a backup file with corrupted data
    When I navigate to backup and restore screen
    And I tap the "Import Backup" button
    And I select the corrupted backup file
    Then I should see an error message "Failed to parse backup file"
    And no partial data should be imported
    And my existing data should remain intact
    And I should be able to try importing a different file

  @integration @ui
  Scenario: Backup screen shows helpful statistics
    Given I have various data in the app
    When I navigate to backup and restore screen
    Then I should see the total number of goals
    And I should see the total number of habits
    And I should see the total number of journal entries
    And I should see the last backup date if available
