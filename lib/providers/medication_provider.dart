import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../models/medication.dart';
import '../services/storage_service.dart';

/// Manages medication tracking state
///
/// Note: This is for personal tracking only, not medical advice.
class MedicationProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<Medication> _medications = [];
  List<MedicationLog> _logs = [];
  bool _isLoading = false;

  List<Medication> get medications => _medications;
  List<Medication> get activeMedications =>
      _medications.where((m) => m.isActive).toList();
  List<MedicationLog> get logs => _logs;
  bool get isLoading => _isLoading;

  MedicationProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _medications = await _storage.loadMedications();
    _logs = await _storage.loadMedicationLogs();

    // Sort medications by name
    _medications.sort((a, b) => a.name.compareTo(b.name));

    // Sort logs by timestamp (most recent first)
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners();
  }

  // ============================================================================
  // Medication Management
  // ============================================================================

  /// Add a new medication
  Future<void> addMedication(Medication medication) async {
    _medications.add(medication);
    _medications.sort((a, b) => a.name.compareTo(b.name));
    await _storage.saveMedications(_medications);
    notifyListeners();
  }

  /// Update an existing medication
  Future<void> updateMedication(Medication updated) async {
    final index = _medications.indexWhere((m) => m.id == updated.id);
    if (index != -1) {
      _medications[index] = updated;
      _medications.sort((a, b) => a.name.compareTo(b.name));
      await _storage.saveMedications(_medications);
      notifyListeners();
    }
  }

  /// Delete a medication and all its logs
  Future<void> deleteMedication(String id) async {
    _medications.removeWhere((m) => m.id == id);
    _logs.removeWhere((l) => l.medicationId == id);
    await _storage.saveMedications(_medications);
    await _storage.saveMedicationLogs(_logs);
    notifyListeners();
  }

  /// Deactivate a medication (soft delete)
  Future<void> deactivateMedication(String id) async {
    final index = _medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      _medications[index] = _medications[index].copyWith(isActive: false);
      await _storage.saveMedications(_medications);
      notifyListeners();
    }
  }

  /// Reactivate a medication
  Future<void> reactivateMedication(String id) async {
    final index = _medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      _medications[index] = _medications[index].copyWith(isActive: true);
      await _storage.saveMedications(_medications);
      notifyListeners();
    }
  }

  /// Get medication by ID
  Medication? getMedicationById(String id) {
    try {
      return _medications.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============================================================================
  // Log Management
  // ============================================================================

  /// Log a medication as taken
  Future<void> logMedicationTaken(
    Medication medication, {
    String? notes,
    DateTime? timestamp,
  }) async {
    final log = MedicationLog(
      medicationId: medication.id,
      medicationName: medication.displayString,
      timestamp: timestamp,
      status: MedicationLogStatus.taken,
      notes: notes,
    );
    _logs.insert(0, log);
    await _storage.saveMedicationLogs(_logs);
    notifyListeners();
  }

  /// Log a medication as skipped
  Future<void> logMedicationSkipped(
    Medication medication, {
    String? skipReason,
    String? notes,
    DateTime? timestamp,
  }) async {
    final log = MedicationLog(
      medicationId: medication.id,
      medicationName: medication.displayString,
      timestamp: timestamp,
      status: MedicationLogStatus.skipped,
      notes: notes,
      skipReason: skipReason,
    );
    _logs.insert(0, log);
    await _storage.saveMedicationLogs(_logs);
    notifyListeners();
  }

  /// Add a custom log entry
  Future<void> addLog(MedicationLog log) async {
    _logs.insert(0, log);
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _storage.saveMedicationLogs(_logs);
    notifyListeners();
  }

  /// Update an existing log
  Future<void> updateLog(MedicationLog updated) async {
    final index = _logs.indexWhere((l) => l.id == updated.id);
    if (index != -1) {
      _logs[index] = updated;
      _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.saveMedicationLogs(_logs);
      notifyListeners();
    }
  }

  /// Delete a log entry
  Future<void> deleteLog(String id) async {
    _logs.removeWhere((l) => l.id == id);
    await _storage.saveMedicationLogs(_logs);
    notifyListeners();
  }

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get logs for a specific date
  List<MedicationLog> logsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _logs.where((l) {
      final logDate = DateTime(l.timestamp.year, l.timestamp.month, l.timestamp.day);
      return logDate == dateOnly;
    }).toList();
  }

  /// Get logs for today
  List<MedicationLog> get todayLogs => logsForDate(DateTime.now());

  /// Get logs for a specific medication
  List<MedicationLog> logsForMedication(String medicationId) {
    return _logs.where((l) => l.medicationId == medicationId).toList();
  }

  /// Get logs for a date range
  List<MedicationLog> logsForDateRange(DateTime start, DateTime end) {
    return _logs.where((l) {
      return l.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          l.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Check if medication was taken today
  bool wasTakenToday(String medicationId) {
    return todayLogs.any(
      (l) => l.medicationId == medicationId && l.status == MedicationLogStatus.taken,
    );
  }

  /// Get adherence rate for a medication over a date range
  MedicationAdherenceSummary getAdherenceSummary({
    required String medicationId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final medication = getMedicationById(medicationId);
    if (medication == null) {
      return MedicationAdherenceSummary(
        startDate: startDate,
        endDate: endDate,
        totalExpected: 0,
        totalTaken: 0,
        totalSkipped: 0,
        totalMissed: 0,
      );
    }

    // Determine expected doses per day based on frequency
    int expectedPerDay;
    switch (medication.frequency) {
      case MedicationFrequency.onceDaily:
        expectedPerDay = 1;
        break;
      case MedicationFrequency.twiceDaily:
        expectedPerDay = 2;
        break;
      case MedicationFrequency.threeTimesDaily:
        expectedPerDay = 3;
        break;
      case MedicationFrequency.fourTimesDaily:
        expectedPerDay = 4;
        break;
      case MedicationFrequency.everyOtherDay:
        expectedPerDay = 1; // Will be adjusted in summary
        break;
      case MedicationFrequency.weekly:
        expectedPerDay = 1; // Per week, not per day
        break;
      case MedicationFrequency.monthly:
        expectedPerDay = 1; // Per month
        break;
      case MedicationFrequency.asNeeded:
      case MedicationFrequency.other:
        expectedPerDay = 0; // No expected amount
        break;
    }

    final logs = logsForMedication(medicationId);
    return MedicationAdherenceSummary.fromLogs(
      logs: logs,
      startDate: startDate,
      endDate: endDate,
      expectedPerDay: expectedPerDay,
    );
  }

  /// Get medications that are due based on their frequency
  List<Medication> get pendingMedications {
    final now = DateTime.now();

    return activeMedications.where((m) {
      // Skip "as needed" medications - they're not expected on a schedule
      if (m.frequency == MedicationFrequency.asNeeded) return false;

      // Skip "other" frequency - we don't know when it's due
      if (m.frequency == MedicationFrequency.other) return false;

      // Check if medication is due based on frequency
      return _isMedicationDue(m, now);
    }).toList();
  }

  /// Get active as-needed medications (not on a schedule)
  List<Medication> get asNeededMedications {
    return activeMedications
        .where((m) => m.frequency == MedicationFrequency.asNeeded)
        .toList();
  }

  /// Check if a medication is due based on its frequency and last log
  bool _isMedicationDue(Medication medication, DateTime now) {
    final logs = logsForMedication(medication.id)
        .where((l) => l.status == MedicationLogStatus.taken)
        .toList();

    // If never taken, it's due
    if (logs.isEmpty) return true;

    // Get the most recent "taken" log
    final lastTaken = logs.first; // logs are already sorted by timestamp desc
    final daysSinceLastTaken = now.difference(lastTaken.timestamp).inDays;
    final hoursSinceLastTaken = now.difference(lastTaken.timestamp).inHours;

    switch (medication.frequency) {
      // Daily medications - due if not taken today
      case MedicationFrequency.onceDaily:
      case MedicationFrequency.twiceDaily:
      case MedicationFrequency.threeTimesDaily:
      case MedicationFrequency.fourTimesDaily:
        // Check if last taken was today
        final lastTakenDate = DateTime(
          lastTaken.timestamp.year,
          lastTaken.timestamp.month,
          lastTaken.timestamp.day,
        );
        final todayDate = DateTime(now.year, now.month, now.day);
        return lastTakenDate.isBefore(todayDate);

      // Every other day - due if taken 2+ days ago or yesterday and it's been 24+ hours
      case MedicationFrequency.everyOtherDay:
        return daysSinceLastTaken >= 1 && hoursSinceLastTaken >= 24;

      // Weekly - due if taken 7+ days ago
      case MedicationFrequency.weekly:
        return daysSinceLastTaken >= 7;

      // Monthly - due if taken 30+ days ago
      case MedicationFrequency.monthly:
        return daysSinceLastTaken >= 30;

      // Should not reach here due to filter above
      case MedicationFrequency.asNeeded:
      case MedicationFrequency.other:
        return false;
    }
  }

  /// Get count of medications taken today
  int get takenTodayCount {
    return todayLogs
        .where((l) => l.status == MedicationLogStatus.taken)
        .map((l) => l.medicationId)
        .toSet()
        .length;
  }

  // ============================================================================
  // Overdue Medication Detection
  // ============================================================================

  /// Get medications that are overdue (past their reminder time and not yet taken today)
  ///
  /// A medication is considered overdue if:
  /// - It has reminder times set
  /// - At least one reminder time has passed today
  /// - The medication hasn't been logged as taken today after that time
  List<OverdueMedication> get overdueMedications {
    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
    final todayLogsSet = todayLogs
        .where((l) => l.status == MedicationLogStatus.taken)
        .toList();

    final overdueList = <OverdueMedication>[];

    for (final medication in activeMedications) {
      // Skip medications without reminder times
      if (medication.reminderTimes == null || medication.reminderTimes!.isEmpty) {
        continue;
      }

      // Skip "as needed" medications
      if (medication.frequency == MedicationFrequency.asNeeded) {
        continue;
      }

      // Get the medication's logs for today
      final medTodayLogs = todayLogsSet
          .where((l) => l.medicationId == medication.id)
          .toList();

      // Check each reminder time
      for (final timeStr in medication.reminderTimes!) {
        final reminderTime = _parseTimeString(timeStr);
        if (reminderTime == null) continue;

        // Check if this reminder time has passed
        if (_isTimeBefore(reminderTime, currentTime)) {
          // Check if medication was taken after this reminder time today
          final wasTakenAfterReminder = medTodayLogs.any((log) {
            final logTime = TimeOfDay(
              hour: log.timestamp.hour,
              minute: log.timestamp.minute,
            );
            // Log is valid if it was after the reminder time (or within 30 min before)
            return _minutesSinceMidnight(logTime) >=
                   _minutesSinceMidnight(reminderTime) - 30;
          });

          if (!wasTakenAfterReminder) {
            // Calculate how overdue
            final overdueMinutes = _minutesSinceMidnight(currentTime) -
                                   _minutesSinceMidnight(reminderTime);

            overdueList.add(OverdueMedication(
              medication: medication,
              scheduledTime: timeStr,
              overdueMinutes: overdueMinutes,
            ));
            break; // Only report once per medication
          }
        }
      }
    }

    // Sort by how overdue (most overdue first)
    overdueList.sort((a, b) => b.overdueMinutes.compareTo(a.overdueMinutes));

    return overdueList;
  }

  /// Check if there are any overdue medications
  bool get hasOverdueMedications => overdueMedications.isNotEmpty;

  /// Parse a time string like "08:00" or "8:00 AM" into TimeOfDay
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // Handle 24-hour format: "08:00", "14:30"
      if (timeStr.contains(':') && !timeStr.toLowerCase().contains('am') &&
          !timeStr.toLowerCase().contains('pm')) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      // Handle 12-hour format: "8:00 AM", "2:30 PM"
      final lowerTime = timeStr.toLowerCase().trim();
      final isPM = lowerTime.contains('pm');
      final cleanTime = lowerTime.replaceAll('am', '').replaceAll('pm', '').trim();
      final parts = cleanTime.split(':');

      int hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? int.parse(parts[1]) : 0;

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  /// Check if time1 is before time2
  bool _isTimeBefore(TimeOfDay time1, TimeOfDay time2) {
    return _minutesSinceMidnight(time1) < _minutesSinceMidnight(time2);
  }

  /// Convert TimeOfDay to minutes since midnight for comparison
  int _minutesSinceMidnight(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // ============================================================================
  // Dosage Constraint Validation
  // ============================================================================

  /// Check if a medication can be taken now based on its constraints
  /// Returns a list of violated constraints (empty if all constraints pass)
  List<ConstraintViolation> checkConstraints(
    Medication medication, {
    DateTime? proposedTime,
  }) {
    final violations = <ConstraintViolation>[];
    final checkTime = proposedTime ?? DateTime.now();

    if (medication.dosageConstraints == null || medication.dosageConstraints!.isEmpty) {
      return violations; // No constraints, all good
    }

    final medLogs = logsForMedication(medication.id)
        .where((l) => l.status == MedicationLogStatus.taken)
        .toList();

    for (final constraint in medication.dosageConstraints!) {
      final violation = _validateConstraint(constraint, medLogs, checkTime, medication);
      if (violation != null) {
        violations.add(violation);
      }
    }

    return violations;
  }

  /// Validate a single constraint
  ConstraintViolation? _validateConstraint(
    DosageConstraint constraint,
    List<MedicationLog> logs,
    DateTime checkTime,
    Medication medication,
  ) {
    switch (constraint.type) {
      case DosageConstraintType.minTimeBetween:
        return _validateMinTimeBetween(constraint, logs, checkTime);

      case DosageConstraintType.maxPerPeriod:
        return _validateMaxPerPeriod(constraint, logs, checkTime);

      case DosageConstraintType.maxCumulativeAmount:
        return _validateMaxCumulativeAmount(constraint, logs, checkTime, medication);

      case DosageConstraintType.timeWindow:
        return _validateTimeWindow(constraint, checkTime);

      case DosageConstraintType.custom:
        // Custom constraints are informational only, no automatic validation
        return null;
    }
  }

  /// Validate minimum time between doses
  ConstraintViolation? _validateMinTimeBetween(
    DosageConstraint constraint,
    List<MedicationLog> logs,
    DateTime checkTime,
  ) {
    if (constraint.durationMinutes == null) return null;
    if (logs.isEmpty) return null; // First dose, no constraint

    // Get most recent log
    final lastLog = logs.first; // Logs are sorted by timestamp desc
    final minutesSinceLast = checkTime.difference(lastLog.timestamp).inMinutes;

    if (minutesSinceLast < constraint.durationMinutes!) {
      final remainingMinutes = constraint.durationMinutes! - minutesSinceLast;
      return ConstraintViolation(
        constraint: constraint,
        message: 'Please wait ${_formatDuration(remainingMinutes)} before next dose',
        timeUntilAllowed: Duration(minutes: remainingMinutes),
      );
    }

    return null;
  }

  /// Validate maximum doses per period
  ConstraintViolation? _validateMaxPerPeriod(
    DosageConstraint constraint,
    List<MedicationLog> logs,
    DateTime checkTime,
  ) {
    if (constraint.maxCount == null || constraint.periodHours == null) return null;

    final periodStart = checkTime.subtract(Duration(hours: constraint.periodHours!));
    final logsInPeriod = logs.where((l) => l.timestamp.isAfter(periodStart)).length;

    if (logsInPeriod >= constraint.maxCount!) {
      // Find when the oldest log in the period will expire
      final oldestInPeriod = logs
          .where((l) => l.timestamp.isAfter(periodStart))
          .reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b);

      final periodEnd = oldestInPeriod.timestamp.add(Duration(hours: constraint.periodHours!));
      final waitDuration = periodEnd.difference(checkTime);

      return ConstraintViolation(
        constraint: constraint,
        message: 'Maximum ${constraint.maxCount} dose${constraint.maxCount! > 1 ? 's' : ''} '
            'per ${_formatPeriod(constraint.periodHours!)} reached',
        timeUntilAllowed: waitDuration.isNegative ? Duration.zero : waitDuration,
      );
    }

    return null;
  }

  /// Validate maximum cumulative amount per period
  ConstraintViolation? _validateMaxCumulativeAmount(
    DosageConstraint constraint,
    List<MedicationLog> logs,
    DateTime checkTime,
    Medication medication,
  ) {
    if (constraint.maxAmount == null || constraint.periodHours == null) return null;

    // Note: This is a simplified check - assumes each log represents one dose
    // In reality, you might need to track actual amounts per log
    final periodStart = checkTime.subtract(Duration(hours: constraint.periodHours!));
    final dosesInPeriod = logs.where((l) => l.timestamp.isAfter(periodStart)).length;

    // Try to parse the amount from medication dosage
    final doseAmount = _parseDosageAmount(medication.dosage ?? '');
    if (doseAmount == null) return null; // Can't validate without knowing amount

    final totalAmount = dosesInPeriod * doseAmount;

    if (totalAmount >= constraint.maxAmount!) {
      return ConstraintViolation(
        constraint: constraint,
        message: 'Maximum ${constraint.maxAmount}${constraint.unit} '
            'per ${_formatPeriod(constraint.periodHours!)} reached',
      );
    }

    return null;
  }

  /// Validate time window restriction
  ConstraintViolation? _validateTimeWindow(
    DosageConstraint constraint,
    DateTime checkTime,
  ) {
    if (constraint.params == null) return null;

    final currentTime = TimeOfDay.fromDateTime(checkTime);
    final notBefore = constraint.params!['notBefore'] as String?;
    final notAfter = constraint.params!['notAfter'] as String?;

    if (notBefore != null) {
      final beforeTime = _parseTimeString(notBefore);
      if (beforeTime != null && _isTimeBefore(currentTime, beforeTime)) {
        return ConstraintViolation(
          constraint: constraint,
          message: 'Cannot take before $notBefore',
        );
      }
    }

    if (notAfter != null) {
      final afterTime = _parseTimeString(notAfter);
      if (afterTime != null && !_isTimeBefore(currentTime, afterTime)) {
        return ConstraintViolation(
          constraint: constraint,
          message: 'Cannot take after $notAfter',
        );
      }
    }

    return null;
  }

  /// Parse dosage amount from string like "500mg", "10ml", "2 tablets"
  double? _parseDosageAmount(String dosage) {
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(dosage);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Format duration in human-readable form
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minute${minutes != 1 ? 's' : ''}';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours hour${hours != 1 ? 's' : ''}';
    }
    return '${hours}h ${mins}m';
  }

  /// Format period in human-readable form
  String _formatPeriod(int hours) {
    if (hours == 24) return 'day';
    if (hours == 168) return 'week';
    if (hours == 720) return 'month';
    if (hours < 24) return '$hours hour${hours != 1 ? 's' : ''}';
    final days = hours ~/ 24;
    return '$days day${days != 1 ? 's' : ''}';
  }

  /// Check if medication can be taken now (convenience method)
  bool canTakeNow(Medication medication) {
    return checkConstraints(medication).isEmpty;
  }

  /// Get next available time to take medication
  DateTime? getNextAvailableTime(Medication medication) {
    final violations = checkConstraints(medication);
    if (violations.isEmpty) return DateTime.now(); // Can take now

    // Find the longest wait time
    Duration maxWait = Duration.zero;
    for (final violation in violations) {
      if (violation.timeUntilAllowed != null &&
          violation.timeUntilAllowed! > maxWait) {
        maxWait = violation.timeUntilAllowed!;
      }
    }

    return maxWait > Duration.zero
        ? DateTime.now().add(maxWait)
        : null;
  }
}

/// Represents a medication that is overdue
class OverdueMedication {
  final Medication medication;
  final String scheduledTime;
  final int overdueMinutes;

  const OverdueMedication({
    required this.medication,
    required this.scheduledTime,
    required this.overdueMinutes,
  });

  /// Get human-readable overdue duration
  String get overdueDisplay {
    if (overdueMinutes < 60) {
      return '$overdueMinutes min overdue';
    }
    final hours = overdueMinutes ~/ 60;
    final mins = overdueMinutes % 60;
    if (mins == 0) {
      return '$hours hr overdue';
    }
    return '${hours}h ${mins}m overdue';
  }
}

/// Represents a violated dosage constraint
class ConstraintViolation {
  final DosageConstraint constraint;
  final String message;
  final Duration? timeUntilAllowed;

  const ConstraintViolation({
    required this.constraint,
    required this.message,
    this.timeUntilAllowed,
  });

  /// Whether this is a blocking violation (prevents taking medication now)
  bool get isBlocking => timeUntilAllowed != null && timeUntilAllowed! > Duration.zero;

  /// Get human-readable time until allowed
  String? get timeUntilAllowedDisplay {
    if (timeUntilAllowed == null) return null;

    final minutes = timeUntilAllowed!.inMinutes;
    if (minutes < 60) {
      return 'in $minutes minute${minutes != 1 ? 's' : ''}';
    }

    final hours = timeUntilAllowed!.inHours;
    final mins = minutes % 60;
    if (mins == 0) {
      return 'in $hours hour${hours != 1 ? 's' : ''}';
    }
    return 'in ${hours}h ${mins}m';
  }
}
