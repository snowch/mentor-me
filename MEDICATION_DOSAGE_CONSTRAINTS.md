# Medication Dosage Constraints

This document explains how to use the flexible dosage constraint system for medication tracking.

## Overview

The dosage constraint system allows you to set various types of safety limits on medications, such as:
- Minimum time between doses (e.g., "wait 3-4 hours between applications")
- Maximum doses per time period (e.g., "no more than 4 times in 24 hours")
- Maximum cumulative amount per period (e.g., "no more than 3000mg per day")
- Time window restrictions (e.g., "not after 8pm")
- Custom constraints (informational notes)

## Creating Medications with Constraints

### Example 1: Topical Pain Cream
*Requirements: Min 3-4 hours between applications, max 4 times in 24 hours*

```dart
final painCream = Medication(
  name: 'Topical Pain Cream',
  dosage: '1 application',
  frequency: MedicationFrequency.asNeeded,
  category: MedicationCategory.overTheCounter,
  dosageConstraints: [
    // Minimum 3 hours between doses
    DosageConstraint.minTimeBetween(hours: 3),

    // Maximum 4 doses per 24-hour period
    DosageConstraint.maxPerPeriod(count: 4, hours: 24),
  ],
);

await medicationProvider.addMedication(painCream);
```

### Example 2: Ibuprofen
*Requirements: Max 3200mg per day, wait 4-6 hours between doses*

```dart
final ibuprofen = Medication(
  name: 'Ibuprofen',
  dosage: '400mg',
  frequency: MedicationFrequency.asNeeded,
  category: MedicationCategory.overTheCounter,
  dosageConstraints: [
    // Wait 4 hours between doses
    DosageConstraint.minTimeBetween(hours: 4),

    // Max 3200mg per day (8 doses of 400mg)
    DosageConstraint.maxCumulativeAmount(
      amount: 3200,
      unit: 'mg',
      hours: 24,
    ),
  ],
);
```

### Example 3: Sleep Medication
*Requirements: Only take between 8pm-10pm, max once per day*

```dart
final sleepMed = Medication(
  name: 'Sleep Aid',
  dosage: '10mg',
  frequency: MedicationFrequency.onceDaily,
  category: MedicationCategory.prescription,
  dosageConstraints: [
    // Can only take between 8pm and 10pm
    DosageConstraint.timeWindow(
      notBefore: '20:00',
      notAfter: '22:00',
    ),

    // Only once per 24 hours
    DosageConstraint.maxPerPeriod(count: 1, hours: 24),
  ],
);
```

### Example 4: Rescue Inhaler
*Requirements: Max 8 puffs per day, wait 4 hours between uses*

```dart
final inhaler = Medication(
  name: 'Albuterol Inhaler',
  dosage: '2 puffs',
  frequency: MedicationFrequency.asNeeded,
  category: MedicationCategory.prescription,
  dosageConstraints: [
    // Wait 4 hours between doses
    DosageConstraint.minTimeBetween(hours: 4),

    // Max 4 uses per day (each use = 2 puffs)
    DosageConstraint.maxPerPeriod(count: 4, hours: 24),

    // Custom warning
    DosageConstraint.custom(
      'If you need more than 4 doses in 24 hours, contact your doctor',
    ),
  ],
);
```

### Example 5: Weekly Medication
*Requirements: Only once per week, wait 7 days*

```dart
final weeklyMed = Medication(
  name: 'Vitamin B12 Injection',
  dosage: '1000mcg',
  frequency: MedicationFrequency.weekly,
  category: MedicationCategory.prescription,
  dosageConstraints: [
    // Must wait 7 days between doses
    DosageConstraint.minTimeBetween(hours: 168), // 7 days * 24 hours

    // Max 1 dose per week
    DosageConstraint.maxPerPeriod(count: 1, hours: 168),
  ],
);
```

## Checking Constraints Before Taking Medication

### Basic Check

```dart
// Check if medication can be taken right now
final canTake = medicationProvider.canTakeNow(medication);

if (canTake) {
  // Safe to take now
  await medicationProvider.logMedicationTaken(medication);
} else {
  // Show warning to user
  print('Cannot take medication yet');
}
```

### Detailed Constraint Checking

```dart
// Get detailed violation information
final violations = medicationProvider.checkConstraints(medication);

if (violations.isEmpty) {
  // All constraints pass, safe to take
  await medicationProvider.logMedicationTaken(medication);
} else {
  // Show specific violations to user
  for (final violation in violations) {
    print(violation.message);

    if (violation.timeUntilAllowed != null) {
      print('Can take ${violation.timeUntilAllowedDisplay}');
    }
  }
}
```

### Get Next Available Time

```dart
final nextTime = medicationProvider.getNextAvailableTime(medication);

if (nextTime == null) {
  print('Medication has time window restrictions that cannot be calculated');
} else if (nextTime.isBefore(DateTime.now().add(Duration(minutes: 1)))) {
  print('Medication can be taken now');
} else {
  print('Next available time: ${DateFormat('h:mm a').format(nextTime)}');
}
```

## UI Integration Examples

### Show Constraint Violations in UI

```dart
Widget buildMedicationCard(Medication medication) {
  final violations = medicationProvider.checkConstraints(medication);
  final canTake = violations.isEmpty;

  return Card(
    child: Column(
      children: [
        ListTile(
          title: Text(medication.displayString),
          subtitle: Text(medication.summary),
        ),

        // Show constraints
        if (medication.dosageConstraints != null)
          ...medication.dosageConstraints!.map((constraint) =>
            Chip(label: Text(constraint.description)),
          ),

        // Show violations if any
        if (!canTake)
          ...violations.map((v) => ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text(v.message),
            subtitle: v.timeUntilAllowedDisplay != null
                ? Text('Available ${v.timeUntilAllowedDisplay}')
                : null,
          )),

        // Action button
        ElevatedButton(
          onPressed: canTake
              ? () => medicationProvider.logMedicationTaken(medication)
              : null,
          child: Text(canTake ? 'Mark as Taken' : 'Not Available'),
        ),
      ],
    ),
  );
}
```

### Show Next Available Time

```dart
Widget buildNextDoseInfo(Medication medication) {
  final nextTime = medicationProvider.getNextAvailableTime(medication);

  if (nextTime == null) return SizedBox.shrink();

  final now = DateTime.now();
  final canTakeNow = nextTime.isBefore(now.add(Duration(minutes: 1)));

  return Card(
    color: canTakeNow ? Colors.green.shade50 : Colors.orange.shade50,
    child: ListTile(
      leading: Icon(
        canTakeNow ? Icons.check_circle : Icons.schedule,
        color: canTakeNow ? Colors.green : Colors.orange,
      ),
      title: Text(canTakeNow
          ? 'Can take now'
          : 'Next dose available'),
      subtitle: canTakeNow
          ? null
          : Text(DateFormat('EEEE, h:mm a').format(nextTime)),
    ),
  );
}
```

## Constraint Types Reference

### `minTimeBetween`
Enforces minimum time between doses.

```dart
// Wait 3 hours
DosageConstraint.minTimeBetween(hours: 3)

// Wait 4 hours 30 minutes
DosageConstraint.minTimeBetween(hours: 4, minutes: 30)

// Wait 45 minutes
DosageConstraint.minTimeBetween(hours: 0, minutes: 45)
```

### `maxPerPeriod`
Limits number of doses in a time period.

```dart
// Max 4 doses per day
DosageConstraint.maxPerPeriod(count: 4, hours: 24)

// Max 7 doses per week
DosageConstraint.maxPerPeriod(count: 7, hours: 168)

// Max 2 doses per 6 hours
DosageConstraint.maxPerPeriod(count: 2, hours: 6)
```

### `maxCumulativeAmount`
Limits total medication amount in a period.

```dart
// Max 3000mg per day
DosageConstraint.maxCumulativeAmount(
  amount: 3000,
  unit: 'mg',
  hours: 24,
)

// Max 120ml per week
DosageConstraint.maxCumulativeAmount(
  amount: 120,
  unit: 'ml',
  hours: 168,
)
```

### `timeWindow`
Restricts when medication can be taken.

```dart
// Only between 8am and 10pm
DosageConstraint.timeWindow(
  notBefore: '08:00',
  notAfter: '22:00',
)

// Only after 6am
DosageConstraint.timeWindow(notBefore: '06:00')

// Only before 8pm
DosageConstraint.timeWindow(notAfter: '20:00')
```

### `custom`
Informational constraint with no automatic validation.

```dart
// Simple note
DosageConstraint.custom('Take with food')

// With metadata
DosageConstraint.custom(
  'Contact doctor if needed more than 4 times per day',
  params: {'severity': 'warning'},
)
```

## Testing

You can test constraints at a specific time:

```dart
// Check if medication could be taken at 2pm tomorrow
final futureTime = DateTime.now().add(Duration(days: 1, hours: 2));
final violations = medicationProvider.checkConstraints(
  medication,
  proposedTime: futureTime,
);
```

## Notes

- Multiple constraints can be applied to a single medication
- All constraints must pass for the medication to be available
- Custom constraints are informational only (no automatic validation)
- Constraint descriptions are automatically generated for display
- Time window constraints use 24-hour format (e.g., "20:00" for 8pm)
- The system tracks "taken" logs only (skipped logs don't count toward limits)
