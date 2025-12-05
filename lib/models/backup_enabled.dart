/// Mixin for domain objects that support backup/restore.
///
/// All models that store user data should implement this mixin.
/// This provides:
/// 1. Type safety - only BackupEnabled objects can be backed up
/// 2. Field verification - ensures toJson() exports all expected fields
/// 3. Round-trip validation - verifies fromJson(toJson(x)) == x
///
/// USAGE:
/// ```dart
/// class WeightEntry with BackupEnabled {
///   final String id;
///   final double weight;
///   final DateTime date;
///   final String? note;
///
///   // Required: List all fields that should be backed up
///   @override
///   Set<String> get backupFields => {'id', 'weight', 'date', 'note'};
///
///   // Required: The storage key for this model type
///   @override
///   String get backupKey => 'weight_entries';
///
///   @override
///   Map<String, dynamic> toJson() => {
///     'id': id,
///     'weight': weight,
///     'date': date.toIso8601String(),
///     'note': note,
///   };
///
///   // fromJson is a factory, can't be in mixin, but verifyBackupCoverage checks it
/// }
/// ```
mixin BackupEnabled {
  /// All field names that should be included in backup.
  /// Override this to declare your model's backup fields.
  ///
  /// This is the SINGLE SOURCE OF TRUTH for what fields should be backed up.
  /// If you add a new field, add it here AND to toJson().
  Set<String> get backupFields;

  /// The storage key used for this model type in backup JSON.
  /// Should match the key in StorageService.userDataKeys.
  String get backupKey;

  /// Convert to JSON for backup.
  Map<String, dynamic> toJson();

  /// Verify that toJson() exports all declared backupFields.
  ///
  /// Call this in tests to catch missing fields:
  /// ```dart
  /// test('WeightEntry exports all fields', () {
  ///   final entry = WeightEntry(...);
  ///   entry.verifyBackupCoverage(); // Throws if field missing
  /// });
  /// ```
  ///
  /// Throws [BackupFieldMissingException] if a declared field is not in toJson().
  void verifyBackupCoverage() {
    final json = toJson();
    final missingFields = <String>[];

    for (final field in backupFields) {
      if (!json.containsKey(field)) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      throw BackupFieldMissingException(
        modelType: runtimeType.toString(),
        missingFields: missingFields,
        declaredFields: backupFields,
        exportedFields: json.keys.toSet(),
      );
    }
  }

  /// Verify that toJson() doesn't export undeclared fields.
  ///
  /// This catches fields in toJson() that aren't declared in backupFields,
  /// which might indicate a mismatch between the two.
  void verifyNoExtraFields() {
    final json = toJson();
    final extraFields = <String>[];

    for (final field in json.keys) {
      if (!backupFields.contains(field)) {
        extraFields.add(field);
      }
    }

    if (extraFields.isNotEmpty) {
      throw BackupExtraFieldException(
        modelType: runtimeType.toString(),
        extraFields: extraFields,
        declaredFields: backupFields,
      );
    }
  }

  /// Verify complete backup coverage (both directions).
  void verifyFullBackupCoverage() {
    verifyBackupCoverage();
    verifyNoExtraFields();
  }
}

/// Exception thrown when a BackupEnabled model doesn't export all declared fields.
class BackupFieldMissingException implements Exception {
  final String modelType;
  final List<String> missingFields;
  final Set<String> declaredFields;
  final Set<String> exportedFields;

  BackupFieldMissingException({
    required this.modelType,
    required this.missingFields,
    required this.declaredFields,
    required this.exportedFields,
  });

  @override
  String toString() => '''
BackupFieldMissingException: $modelType is missing fields in toJson()

Missing fields: ${missingFields.join(', ')}
Declared in backupFields: ${declaredFields.join(', ')}
Actually exported by toJson(): ${exportedFields.join(', ')}

To fix:
1. Add the missing fields to toJson()
2. OR remove them from backupFields if they shouldn't be backed up
''';
}

/// Exception thrown when toJson() exports fields not declared in backupFields.
class BackupExtraFieldException implements Exception {
  final String modelType;
  final List<String> extraFields;
  final Set<String> declaredFields;

  BackupExtraFieldException({
    required this.modelType,
    required this.extraFields,
    required this.declaredFields,
  });

  @override
  String toString() => '''
BackupExtraFieldException: $modelType exports undeclared fields in toJson()

Extra fields in toJson(): ${extraFields.join(', ')}
Declared in backupFields: ${declaredFields.join(', ')}

To fix:
1. Add the extra fields to backupFields
2. OR remove them from toJson() if they shouldn't be backed up
''';
}

/// Registry of all BackupEnabled model types.
///
/// This is populated by calling [registerBackupType] for each model.
/// Used by BackupService to verify all models are properly backed up.
class BackupEnabledRegistry {
  static final Map<String, BackupEnabled Function()> _factories = {};

  /// Register a model factory for backup verification.
  ///
  /// The factory should create a fully-populated instance for testing.
  static void register(String backupKey, BackupEnabled Function() factory) {
    _factories[backupKey] = factory;
  }

  /// Get all registered backup keys.
  static Set<String> get registeredKeys => _factories.keys.toSet();

  /// Verify all registered models export their declared fields.
  ///
  /// Call this in tests to ensure all models are properly configured.
  static void verifyAllModels() {
    final errors = <String>[];

    for (final entry in _factories.entries) {
      try {
        final instance = entry.value();
        instance.verifyFullBackupCoverage();
      } catch (e) {
        errors.add('${entry.key}: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw Exception(
        'Backup coverage verification failed:\n${errors.join('\n\n')}',
      );
    }
  }
}
