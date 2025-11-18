# Testing Strategy for MentorMe

This document outlines the comprehensive testing strategy for MentorMe to prevent regressions and ensure code quality.

## Overview

MentorMe uses a **test pyramid approach** to ensure comprehensive coverage while maintaining fast test execution:

```
        /\
       /  \      Integration Tests (5-10%)
      /    \     - Full user flows
     /------\    - E2E scenarios
    /        \
   /  Widget  \  Widget Tests (20-30%)
  /   Tests    \ - Critical screens
 /-------------\- Custom widgets
/               \
|  Unit Tests   | Unit Tests (60-70%)
|  (Priority!)  | - Providers (state management)
|               | - Services (business logic)
\_______________/ - Utility functions

```

**Testing Approach:**
- **Hybrid Strategy:** Standard Dart tests for unit tests, Gherkin/BDD for integration tests
- **Unit Tests:** Fast, developer-focused, extensive coverage
- **Integration Tests:** BDD-style, stakeholder-readable, critical user flows

**Current Coverage:**
- ✅ Schema validation tests (data models)
- ✅ Legacy migration tests
- ✅ Provider tests (GoalProvider, JournalProvider, HabitProvider)
- ✅ BDD/Gherkin integration tests (goal management flows)
- ⚠️ Service tests (partially implemented)
- ⚠️ Widget tests (not yet implemented)

---

## Test Organization

### Directory Structure

```
test/
├── providers/               # Unit tests for providers (state management)
│   ├── goal_provider_test.dart
│   ├── journal_provider_test.dart
│   ├── habit_provider_test.dart
│   ├── checkin_provider_test.dart
│   ├── pulse_provider_test.dart
│   ├── pulse_type_provider_test.dart
│   └── chat_provider_test.dart
├── services/                # Unit tests for services (business logic)
│   ├── ai_service_test.dart
│   ├── storage_service_test.dart
│   ├── mentor_intelligence_service_test.dart
│   ├── notification_service_test.dart
│   └── context_management_service_test.dart
├── widgets/                 # Widget tests (UI components)
│   ├── mentor_coaching_card_widget_test.dart
│   ├── goal_card_widget_test.dart
│   └── habit_card_widget_test.dart
├── screens/                 # Screen tests (full pages)
│   ├── home_screen_test.dart
│   ├── goals_screen_test.dart
│   └── chat_screen_test.dart
├── models/                  # Model tests (data structures)
│   ├── goal_test.dart
│   └── journal_entry_test.dart
├── features/                # BDD/Gherkin feature files (plain text)
│   ├── goal_management.feature
│   ├── journal_writing.feature
│   └── habit_tracking.feature
├── steps/                   # Step definitions for Gherkin tests
│   ├── common_steps.dart    # Reusable steps across all features
│   ├── goal_steps.dart      # Goal-specific steps
│   ├── journal_steps.dart   # Journal-specific steps
│   └── habit_steps.dart     # Habit-specific steps
├── schema_validation_test.dart    # Schema synchronization tests
└── legacy_migration_test.dart     # Data migration tests

test_driver/                 # Integration test driver (Gherkin)
├── app.dart                 # App entry point for integration tests
└── app_test.dart            # Gherkin test configuration & runner
```

---

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/providers/goal_provider_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### View Coverage Report
```bash
# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### Run Tests in Watch Mode (during development)
```bash
flutter test --watch
```

### Run Gherkin/BDD Integration Tests
```bash
# Run all Gherkin tests
flutter drive --target=test_driver/app.dart

# Run specific feature file
flutter drive --target=test_driver/app.dart --feature=test/features/goal_management.feature

# Run tests with specific tags (e.g., only critical tests)
flutter drive --target=test_driver/app.dart --tags="@critical"

# Run tests excluding certain tags (e.g., skip work-in-progress tests)
flutter drive --target=test_driver/app.dart --tags="not @wip"

# Combine tag filters
flutter drive --target=test_driver/app.dart --tags="@integration and @critical"
```

**Gherkin Test Reports:**
- JSON report: `reports/gherkin-report.json`
- Console output: Shows progress and summary

---

## Test Categories

### 1. Unit Tests (Priority: HIGH)

**Purpose:** Test individual functions, methods, and classes in isolation.

**What to Test:**
- Provider methods (add, update, delete, filter)
- Service logic (AI response generation, storage operations)
- Utility functions (streak calculations, date formatting)
- Data model serialization/deserialization

**Example:**
```dart
test('should add a new goal', () async {
  final goal = Goal(title: 'Test Goal', category: GoalCategory.personal);
  await goalProvider.addGoal(goal);

  expect(goalProvider.goals.length, 1);
  expect(goalProvider.goals.first.title, 'Test Goal');
});
```

**Coverage Target:** 70-80%

### 2. Widget Tests (Priority: MEDIUM)

**Purpose:** Test UI components and user interactions.

**What to Test:**
- Widget rendering (does it display correctly?)
- User interactions (tap, swipe, input)
- State changes (does UI update when state changes?)
- Navigation (does tapping button navigate correctly?)

**Example:**
```dart
testWidgets('should display goal title', (WidgetTester tester) async {
  final goal = Goal(title: 'Test Goal', category: GoalCategory.personal);

  await tester.pumpWidget(MaterialApp(
    home: GoalCardWidget(goal: goal),
  ));

  expect(find.text('Test Goal'), findsOneWidget);
});
```

**Coverage Target:** 50-60%

### 3. Integration Tests (Priority: LOW)

**Purpose:** Test complete user flows end-to-end.

**What to Test:**
- Create goal → Add milestone → Complete milestone
- Write journal entry → Link to goal → View in timeline
- Complete habit → Build streak → View stats

**Example:**
```dart
testWidgets('should complete full goal creation flow', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());

  // Tap "Add Goal" button
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();

  // Fill in goal details
  await tester.enterText(find.byType(TextField).first, 'New Goal');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify goal appears in list
  expect(find.text('New Goal'), findsOneWidget);
});
```

**Coverage Target:** 30-40% of critical flows

### 4. BDD/Gherkin Integration Tests (Hybrid Approach)

**Purpose:** Write integration tests in plain English using Gherkin syntax for stakeholder readability.

**When to Use:**
- ✅ Critical user flows (e.g., goal creation → milestone completion)
- ✅ Acceptance criteria from user stories
- ✅ Regression tests for high-value features
- ✅ Tests that non-technical stakeholders should understand

**When NOT to Use:**
- ❌ Unit tests (too verbose, use standard Dart tests)
- ❌ Simple logic tests (overhead not justified)
- ❌ Tests that change frequently (step definitions need updates)

**Plain Text Feature Files:**

```gherkin
# test/features/goal_management.feature
Feature: Goal Management
  As a user
  I want to create and manage goals with milestones
  So that I can track my progress toward meaningful achievements

  @critical @integration
  Scenario: Create a new goal successfully
    Given I am on the home screen
    When I navigate to the goals screen
    And I tap the "Add Goal" button
    And I enter "Launch my website" as the goal title
    And I select "Career" as the category
    And I tap the "Save" button
    Then I should see "Launch my website" in my goals list
    And the goal should be in "Active" status
```

**Step Definitions (Dart Code):**

```dart
// test/steps/goal_steps.dart
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
```

**Running Gherkin Tests:**

```bash
# Run all Gherkin tests
flutter drive --target=test_driver/app.dart

# Run only critical tests
flutter drive --target=test_driver/app.dart --tags="@critical"
```

**Benefits:**
- ✅ **Plain English:** Non-technical stakeholders can read and write tests
- ✅ **Living Documentation:** Feature files serve as up-to-date requirements
- ✅ **Reusable Steps:** Write once, use across many scenarios
- ✅ **Acceptance Criteria:** Maps directly to user stories

**Considerations:**
- ⚠️ **Slower Execution:** Parsing feature files adds overhead
- ⚠️ **Setup Required:** Need test_driver/, step definitions, configuration
- ⚠️ **IDE Support:** Less autocomplete compared to pure Dart tests

---

## Testing Best Practices

### 1. Test Naming Convention

Use descriptive test names that explain **what** is being tested and **what** the expected outcome is:

✅ **GOOD:**
```dart
test('should calculate current streak correctly for consecutive days', () {});
test('should return null when goal not found', () {});
test('should persist completion history to SharedPreferences', () {});
```

❌ **BAD:**
```dart
test('test goal', () {});
test('streak test', () {});
test('it works', () {});
```

### 2. Arrange-Act-Assert Pattern

Structure tests using the AAA pattern:

```dart
test('should add a new goal', () async {
  // Arrange - Set up test data and preconditions
  final goal = Goal(title: 'Test Goal', category: GoalCategory.personal);

  // Act - Perform the action being tested
  await goalProvider.addGoal(goal);

  // Assert - Verify the expected outcome
  expect(goalProvider.goals.length, 1);
  expect(goalProvider.goals.first.title, 'Test Goal');
});
```

### 3. Test Isolation

Each test should be **independent** and not rely on other tests:

✅ **GOOD:**
```dart
setUp(() async {
  SharedPreferences.setMockInitialValues({});
  goalProvider = GoalProvider();
  await goalProvider.loadGoals();
});

test('test 1', () async {
  // Fresh provider, clean state
});

test('test 2', () async {
  // Fresh provider, clean state
});
```

❌ **BAD:**
```dart
test('test 1', () async {
  await goalProvider.addGoal(goal1);
});

test('test 2', () async {
  // Assumes test 1 ran first - FRAGILE!
  expect(goalProvider.goals.length, 1);
});
```

### 4. Mock External Dependencies

Use mocks for external services (API calls, storage, etc.):

```dart
class MockAIService extends Mock implements AIService {}

test('should generate coaching response', () async {
  final mockAI = MockAIService();
  when(mockAI.generateCoachingResponse(any)).thenAnswer(
    (_) async => 'Great progress!',
  );

  final response = await mockAI.generateCoachingResponse(prompt: 'How am I doing?');
  expect(response, 'Great progress!');
});
```

### 5. Test Edge Cases

Don't just test the happy path - test edge cases:

```dart
group('Edge Cases', () {
  test('should handle null descriptions', () async { /* ... */ });
  test('should handle empty content', () async { /* ... */ });
  test('should handle very long content', () async { /* ... */ });
  test('should prevent duplicate IDs', () async { /* ... */ });
  test('should handle concurrent updates', () async { /* ... */ });
});
```

### 6. Use Descriptive Test Groups

Organize related tests using `group()`:

```dart
group('GoalProvider', () {
  group('CRUD Operations', () {
    test('should add a new goal', () {});
    test('should update an existing goal', () {});
    test('should delete a goal', () {});
  });

  group('Status Management', () {
    test('should complete a goal', () {});
    test('should abandon a goal', () {});
  });
});
```

---

## CI/CD Integration

### GitHub Actions Workflow

Tests run automatically on every push and pull request:

```yaml
# .github/workflows/android-build.yml
- name: Run Flutter tests
  run: flutter test
  continue-on-error: true

- name: Run schema validation test
  run: flutter test test/schema_validation_test.dart
  continue-on-error: false  # FAIL build if schema validation fails
```

### Coverage Reporting (Coming Soon)

Coverage reports will be:
- ✅ Generated on every CI run
- ✅ Uploaded to coverage service (Codecov/Coveralls)
- ✅ Displayed in pull requests
- ✅ Enforced via minimum threshold (70% coverage)

---

## Test Coverage Goals

| Category | Current | Target | Priority |
|----------|---------|--------|----------|
| **Providers** | 80% | 90% | HIGH |
| **Services** | 30% | 70% | HIGH |
| **Models** | 60% | 80% | MEDIUM |
| **Widgets** | 0% | 50% | MEDIUM |
| **Screens** | 0% | 30% | LOW |
| **Integration** | 0% | 20% | LOW |
| **Overall** | 40% | 70% | HIGH |

---

## Regression Prevention Strategy

### 1. Pre-Commit Hooks (Recommended)

Install pre-commit hooks to run tests before committing:

```bash
# .git/hooks/pre-commit
#!/bin/bash
flutter test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed! Commit aborted."
  exit 1
fi
```

### 2. Pull Request Requirements

**Before merging a PR:**
- ✅ All tests must pass
- ✅ No decrease in code coverage
- ✅ New features include tests
- ✅ Bug fixes include regression tests

### 3. Test-Driven Development (TDD)

For new features, consider TDD:
1. **Write test first** (it fails)
2. **Implement feature** (test passes)
3. **Refactor** (test still passes)

**Example:**
```dart
// Step 1: Write failing test
test('should archive a goal', () async {
  final goal = Goal(title: 'Test', category: GoalCategory.personal);
  await goalProvider.addGoal(goal);

  await goalProvider.archiveGoal(goal.id);  // Method doesn't exist yet!

  final archivedGoal = goalProvider.getGoalById(goal.id);
  expect(archivedGoal!.status, GoalStatus.archived);
});

// Step 2: Implement archiveGoal() method
// Step 3: Test passes, refactor if needed
```

### 4. Continuous Monitoring

Track regression metrics:
- **Test pass rate:** Should be 100%
- **Code coverage:** Should not decrease
- **Test execution time:** Should remain fast (<5 minutes)
- **Flaky tests:** Should be fixed immediately

---

## Testing Roadmap

### Phase 1: Critical Unit Tests (COMPLETED ✅)
- [x] GoalProvider tests
- [x] JournalProvider tests
- [x] HabitProvider tests
- [x] Schema validation tests
- [x] Legacy migration tests

### Phase 2: Service Tests (IN PROGRESS 🚧)
- [ ] AIService tests (mock API calls)
- [ ] StorageService tests
- [ ] MentorIntelligenceService tests
- [ ] NotificationService tests
- [ ] ContextManagementService tests

### Phase 3: Widget Tests (PLANNED 📝)
- [ ] MentorCoachingCardWidget tests
- [ ] GoalCardWidget tests
- [ ] HabitCardWidget tests
- [ ] Custom form widgets tests

### Phase 4: Screen Tests (PLANNED 📝)
- [ ] HomeScreen tests
- [ ] GoalsScreen tests
- [ ] ChatScreen tests
- [ ] JournalScreen tests

### Phase 5: Integration Tests (PLANNED 📝)
- [ ] Create goal → Complete milestone flow
- [ ] Journal entry → Link to goal flow
- [ ] Complete habit → Build streak flow
- [ ] Backup → Restore flow

### Phase 6: Test Infrastructure (PLANNED 📝)
- [ ] Add test coverage reporting to CI/CD
- [ ] Set up coverage badges
- [ ] Implement pre-commit hooks
- [ ] Add performance tests for large datasets

---

## Common Testing Patterns

### Testing Providers with SharedPreferences

```dart
setUp(() async {
  SharedPreferences.setMockInitialValues({});
  provider = MyProvider();
  await provider.loadData();
});

test('should persist data', () async {
  await provider.addItem(item);

  // Create new instance to test loading
  final newProvider = MyProvider();
  await newProvider.loadData();

  expect(newProvider.items.length, 1);
});
```

### Testing Async Operations

```dart
test('should handle async operations', () async {
  final future = provider.fetchData();

  // Can test loading state here
  expect(provider.isLoading, true);

  await future;

  expect(provider.isLoading, false);
  expect(provider.data, isNotNull);
});
```

### Testing Error Handling

```dart
test('should handle errors gracefully', () async {
  // Simulate error condition
  when(mockService.getData()).thenThrow(Exception('Network error'));

  await provider.loadData();

  expect(provider.hasError, true);
  expect(provider.errorMessage, contains('Network error'));
});
```

### Testing Stream-Based Data

```dart
test('should update stream when data changes', () async {
  final stream = provider.dataStream;

  provider.addItem(item1);
  await expectLater(stream, emits(containsAll([item1])));

  provider.addItem(item2);
  await expectLater(stream, emits(containsAll([item1, item2])));
});
```

---

## Troubleshooting Tests

### "SharedPreferences not initialized"

**Solution:** Mock SharedPreferences in setUp:
```dart
setUp(() async {
  SharedPreferences.setMockInitialValues({});
});
```

### "Test timeout"

**Solution:** Increase timeout or use `pumpAndSettle()`:
```dart
testWidgets('my test', (tester) async {
  await tester.pumpWidget(myWidget);
  await tester.pumpAndSettle();  // Wait for all animations
});
```

### "Provider not found"

**Solution:** Wrap widget with providers:
```dart
await tester.pumpWidget(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => GoalProvider()),
    ],
    child: MaterialApp(home: MyScreen()),
  ),
);
```

### "Flaky tests"

**Solution:** Avoid time-dependent tests, use `await`, ensure test isolation:
```dart
// ❌ BAD - time-dependent
test('test', () {
  Future.delayed(Duration(seconds: 1), () => doSomething());
  expect(result, isTrue);  // May fail due to timing
});

// ✅ GOOD - await completion
test('test', () async {
  await doSomething();
  expect(result, isTrue);  // Waits for completion
});
```

---

## Resources

### Flutter Testing Documentation
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/cookbook/testing/integration/introduction)

### Testing Packages
- `flutter_test` - Built-in testing framework
- `mockito` - Mocking library
- `integration_test` - Integration testing
- `golden_toolkit` - Golden file testing (screenshot comparison)

### Best Practices
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Test-Driven Development with Flutter](https://resocoder.com/flutter-tdd-clean-architecture-course/)

---

## Contributing

When adding new features or fixing bugs:

1. **Write tests first** (TDD approach preferred)
2. **Ensure all tests pass** before submitting PR
3. **Maintain or improve coverage** (no decrease allowed)
4. **Add tests for bug fixes** to prevent regressions
5. **Update this document** if introducing new testing patterns

---

## Questions?

If you have questions about testing or need help writing tests:
- Check existing test files for examples
- Consult this document for patterns
- Ask in PR reviews for guidance
- Refer to Flutter testing documentation

**Remember:** Tests are not just about coverage - they're about **confidence** that your code works correctly and **preventing regressions** as the codebase evolves.
