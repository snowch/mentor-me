import 'package:flutter/foundation.dart';
import '../models/symptom.dart';
import '../services/storage_service.dart';

/// Manages symptom tracking state
///
/// Note: This is for personal tracking only, not medical diagnosis.
class SymptomProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  List<SymptomType> _types = [];
  List<SymptomEntry> _entries = [];
  bool _isLoading = false;
  bool _typesInitialized = false;

  List<SymptomType> get types => _types;
  List<SymptomType> get activeTypes => _types.where((t) => t.isActive).toList();
  List<SymptomEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  SymptomProvider() {
    _loadData();
  }

  /// Reload data from storage (useful after import/restore)
  Future<void> reload() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    _types = await _storage.loadSymptomTypes();
    _entries = await _storage.loadSymptomEntries();

    // Initialize default types if none exist
    if (_types.isEmpty && !_typesInitialized) {
      _types = SymptomType.defaults;
      await _storage.saveSymptomTypes(_types);
      _typesInitialized = true;
    }

    // Sort types by sortOrder
    _types.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Sort entries by timestamp (most recent first)
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners();
  }

  // ============================================================================
  // Symptom Type Management
  // ============================================================================

  /// Add a custom symptom type
  Future<void> addSymptomType(SymptomType type) async {
    // Set sort order to end of list
    final newType = type.copyWith(sortOrder: _types.length);
    _types.add(newType);
    await _storage.saveSymptomTypes(_types);
    notifyListeners();
  }

  /// Update an existing symptom type
  Future<void> updateSymptomType(SymptomType updated) async {
    final index = _types.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _types[index] = updated;
      await _storage.saveSymptomTypes(_types);
      notifyListeners();
    }
  }

  /// Delete a custom symptom type (system types can only be deactivated)
  Future<void> deleteSymptomType(String id) async {
    final type = _types.firstWhere((t) => t.id == id, orElse: () => throw StateError('Type not found'));
    if (type.isSystemDefined) {
      // Can't delete system types - deactivate instead
      await toggleSymptomTypeActive(id);
      return;
    }

    _types.removeWhere((t) => t.id == id);
    await _storage.saveSymptomTypes(_types);
    notifyListeners();
  }

  /// Toggle symptom type active/inactive
  Future<void> toggleSymptomTypeActive(String id) async {
    final index = _types.indexWhere((t) => t.id == id);
    if (index != -1) {
      _types[index] = _types[index].copyWith(isActive: !_types[index].isActive);
      await _storage.saveSymptomTypes(_types);
      notifyListeners();
    }
  }

  /// Reorder symptom types
  Future<void> reorderSymptomTypes(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _types.removeAt(oldIndex);
    _types.insert(newIndex, item);

    // Update sort orders
    for (int i = 0; i < _types.length; i++) {
      _types[i] = _types[i].copyWith(sortOrder: i);
    }

    await _storage.saveSymptomTypes(_types);
    notifyListeners();
  }

  /// Get symptom type by ID
  SymptomType? getTypeById(String id) {
    try {
      return _types.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Reset to default symptom types
  Future<void> resetToDefaults() async {
    _types = SymptomType.defaults;
    await _storage.saveSymptomTypes(_types);
    notifyListeners();
  }

  // ============================================================================
  // Symptom Entry Management
  // ============================================================================

  /// Add a new symptom entry
  Future<void> addEntry(SymptomEntry entry) async {
    _entries.insert(0, entry);
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _storage.saveSymptomEntries(_entries);
    notifyListeners();
  }

  /// Quick log a single symptom with severity
  Future<SymptomEntry> logSymptom({
    required String symptomTypeId,
    required int severity,
    String? notes,
    String? triggers,
    DateTime? timestamp,
  }) async {
    final entry = SymptomEntry(
      timestamp: timestamp,
      symptoms: {symptomTypeId: severity},
      notes: notes,
      triggers: triggers,
    );
    await addEntry(entry);
    return entry;
  }

  /// Log multiple symptoms at once
  Future<SymptomEntry> logMultipleSymptoms({
    required Map<String, int> symptoms,
    String? notes,
    String? triggers,
    DateTime? timestamp,
  }) async {
    final entry = SymptomEntry(
      timestamp: timestamp,
      symptoms: symptoms,
      notes: notes,
      triggers: triggers,
    );
    await addEntry(entry);
    return entry;
  }

  /// Update an existing entry
  Future<void> updateEntry(SymptomEntry updated) async {
    final index = _entries.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _entries[index] = updated;
      _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _storage.saveSymptomEntries(_entries);
      notifyListeners();
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _storage.saveSymptomEntries(_entries);
    notifyListeners();
  }

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get entries for a specific date
  List<SymptomEntry> entriesForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _entries.where((e) {
      final entryDate = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      return entryDate == dateOnly;
    }).toList();
  }

  /// Get entries for today
  List<SymptomEntry> get todayEntries => entriesForDate(DateTime.now());

  /// Get entries for a date range
  List<SymptomEntry> entriesForDateRange(DateTime start, DateTime end) {
    return _entries.where((e) {
      return e.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
          e.timestamp.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get entries containing a specific symptom
  List<SymptomEntry> entriesWithSymptom(String symptomTypeId) {
    return _entries.where((e) => e.symptoms.containsKey(symptomTypeId)).toList();
  }

  /// Get summary for a date range
  SymptomSummary getSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return SymptomSummary.fromEntries(
      entries: _entries,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get weekly summary
  SymptomSummary get weekSummary {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return getSummary(startDate: weekAgo, endDate: now);
  }

  /// Get average severity for a symptom over a date range
  double getAverageSeverity({
    required String symptomTypeId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final relevantEntries = entriesForDateRange(startDate, endDate)
        .where((e) => e.symptoms.containsKey(symptomTypeId));

    if (relevantEntries.isEmpty) return 0;

    final total = relevantEntries.fold<int>(
      0,
      (sum, e) => sum + e.symptoms[symptomTypeId]!,
    );

    return total / relevantEntries.length;
  }

  /// Get symptom frequency (count) over a date range
  int getSymptomFrequency({
    required String symptomTypeId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return entriesForDateRange(startDate, endDate)
        .where((e) => e.symptoms.containsKey(symptomTypeId))
        .length;
  }

  /// Check if any symptoms were logged today
  bool get hasLoggedToday => todayEntries.isNotEmpty;

  /// Get most common symptom in the last week
  String? get mostCommonSymptomThisWeek {
    return weekSummary.mostFrequentSymptom;
  }

  /// Get trending symptoms (increasing severity over time)
  List<String> getTrendingSymptoms() {
    final now = DateTime.now();
    final thisWeek = entriesForDateRange(
      now.subtract(const Duration(days: 7)),
      now,
    );
    final lastWeek = entriesForDateRange(
      now.subtract(const Duration(days: 14)),
      now.subtract(const Duration(days: 7)),
    );

    final trending = <String>[];

    for (final type in activeTypes) {
      final thisWeekAvg = _averageForSymptom(type.id, thisWeek);
      final lastWeekAvg = _averageForSymptom(type.id, lastWeek);

      // If severity increased by more than 0.5 on the 1-5 scale
      if (thisWeekAvg > 0 && thisWeekAvg - lastWeekAvg > 0.5) {
        trending.add(type.id);
      }
    }

    return trending;
  }

  double _averageForSymptom(String typeId, List<SymptomEntry> entries) {
    final relevant = entries.where((e) => e.symptoms.containsKey(typeId));
    if (relevant.isEmpty) return 0;

    final total = relevant.fold<int>(0, (sum, e) => sum + e.symptoms[typeId]!);
    return total / relevant.length;
  }
}
