import 'package:flutter/foundation.dart';
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

  /// Get medications that haven't been logged today
  List<Medication> get pendingMedications {
    final today = DateTime.now();
    final todayLogs = logsForDate(today);
    final loggedMedicationIds = todayLogs.map((l) => l.medicationId).toSet();

    return activeMedications.where((m) {
      // Skip "as needed" medications - they're not expected daily
      if (m.frequency == MedicationFrequency.asNeeded) return false;

      return !loggedMedicationIds.contains(m.id);
    }).toList();
  }

  /// Get count of medications taken today
  int get takenTodayCount {
    return todayLogs
        .where((l) => l.status == MedicationLogStatus.taken)
        .map((l) => l.medicationId)
        .toSet()
        .length;
  }
}
