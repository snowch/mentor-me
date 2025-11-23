import 'package:flutter/foundation.dart';
import '../models/safety_plan.dart';
import '../services/storage_service.dart';
import '../services/debug_service.dart';

/// Provider for managing user's safety plan
///
/// Handles creation, updating, and retrieval of safety plans.
/// Safety plans are critical for crisis intervention and suicide prevention.
class SafetyPlanProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final DebugService _debug = DebugService();

  SafetyPlan? _safetyPlan;
  bool _isLoading = false;
  String? _error;

  SafetyPlan? get safetyPlan => _safetyPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSafetyPlan => _safetyPlan != null;

  SafetyPlanProvider() {
    loadSafetyPlan();
  }

  /// Load safety plan from storage
  Future<void> loadSafetyPlan() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _storage.getSafetyPlan();
      if (data != null) {
        _safetyPlan = SafetyPlan.fromJson(data);
        await _debug.info('SafetyPlanProvider', 'Safety plan loaded', metadata: {
          'isComplete': _safetyPlan!.isComplete,
          'completionPercentage': _safetyPlan!.completionPercentage,
        });
      } else {
        await _debug.info('SafetyPlanProvider', 'No safety plan found - creating default');
        // Create a default safety plan with UK crisis contacts
        _safetyPlan = SafetyPlan();
      }
    } catch (e, stackTrace) {
      _error = 'Failed to load safety plan: $e';
      await _debug.error(
        'SafetyPlanProvider',
        'Failed to load safety plan',stackTrace: stackTrace.toString(),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create or update safety plan
  Future<void> saveSafetyPlan(SafetyPlan plan) async {
    try {
      final updatedPlan = plan.copyWith(lastUpdated: DateTime.now());
      await _storage.saveSafetyPlan(updatedPlan.toJson());
      _safetyPlan = updatedPlan;

      await _debug.info('SafetyPlanProvider', 'Safety plan saved', metadata: {
        'isComplete': updatedPlan.isComplete,
        'completionPercentage': updatedPlan.completionPercentage,
      });

      notifyListeners();
    } catch (e, stackTrace) {
      _error = 'Failed to save safety plan: $e';
      await _debug.error(
        'SafetyPlanProvider',
        'Failed to save safety plan',stackTrace: stackTrace.toString(),
      );
      rethrow;
    }
  }

  /// Add a warning sign
  Future<void> addWarningSign(String warningSign) async {
    if (_safetyPlan == null) return;

    final updated = _safetyPlan!.copyWith(
      warningSignsPersonal: [
        ..._safetyPlan!.warningSignsPersonal,
        warningSign,
      ],
    );

    await saveSafetyPlan(updated);
  }

  /// Remove a warning sign
  Future<void> removeWarningSign(int index) async {
    if (_safetyPlan == null) return;

    final signs = List<String>.from(_safetyPlan!.warningSignsPersonal);
    signs.removeAt(index);

    final updated = _safetyPlan!.copyWith(warningSignsPersonal: signs);
    await saveSafetyPlan(updated);
  }

  /// Add a coping strategy
  Future<void> addCopingStrategy(String strategy) async {
    if (_safetyPlan == null) return;

    final updated = _safetyPlan!.copyWith(
      copingStrategiesInternal: [
        ..._safetyPlan!.copingStrategiesInternal,
        strategy,
      ],
    );

    await saveSafetyPlan(updated);
  }

  /// Remove a coping strategy
  Future<void> removeCopingStrategy(int index) async {
    if (_safetyPlan == null) return;

    final strategies = List<String>.from(_safetyPlan!.copingStrategiesInternal);
    strategies.removeAt(index);

    final updated = _safetyPlan!.copyWith(copingStrategiesInternal: strategies);
    await saveSafetyPlan(updated);
  }

  /// Add a social support contact
  Future<void> addSocialSupport(CrisisContact contact) async {
    if (_safetyPlan == null) return;

    final updated = _safetyPlan!.copyWith(
      socialSupports: [
        ..._safetyPlan!.socialSupports,
        contact,
      ],
    );

    await saveSafetyPlan(updated);
  }

  /// Remove a social support contact
  Future<void> removeSocialSupport(String contactId) async {
    if (_safetyPlan == null) return;

    final supports = _safetyPlan!.socialSupports.where((c) => c.id != contactId).toList();

    final updated = _safetyPlan!.copyWith(socialSupports: supports);
    await saveSafetyPlan(updated);
  }

  /// Add a professional contact
  Future<void> addProfessionalContact(CrisisContact contact) async {
    if (_safetyPlan == null) return;

    final updated = _safetyPlan!.copyWith(
      professionalContacts: [
        ..._safetyPlan!.professionalContacts,
        contact,
      ],
    );

    await saveSafetyPlan(updated);
  }

  /// Remove a professional contact
  Future<void> removeProfessionalContact(String contactId) async {
    if (_safetyPlan == null) return;

    final professionals = _safetyPlan!.professionalContacts.where((c) => c.id != contactId).toList();

    final updated = _safetyPlan!.copyWith(professionalContacts: professionals);
    await saveSafetyPlan(updated);
  }

  /// Add a reason to live
  Future<void> addReasonToLive(String reason) async {
    if (_safetyPlan == null) return;

    final updated = _safetyPlan!.copyWith(
      reasonsToLive: [
        ..._safetyPlan!.reasonsToLive,
        reason,
      ],
    );

    await saveSafetyPlan(updated);
  }

  /// Remove a reason to live
  Future<void> removeReasonToLive(int index) async {
    if (_safetyPlan == null) return;

    final reasons = List<String>.from(_safetyPlan!.reasonsToLive);
    reasons.removeAt(index);

    final updated = _safetyPlan!.copyWith(reasonsToLive: reasons);
    await saveSafetyPlan(updated);
  }

  /// Add an environmental safety action
  Future<void> addEnvironmentalSafety(String action) async {
    if (_safetyPlan == null) return;

    final updated = _safetyPlan!.copyWith(
      environmentalSafety: [
        ..._safetyPlan!.environmentalSafety,
        action,
      ],
    );

    await saveSafetyPlan(updated);
  }

  /// Remove an environmental safety action
  Future<void> removeEnvironmentalSafety(int index) async {
    if (_safetyPlan == null) return;

    final actions = List<String>.from(_safetyPlan!.environmentalSafety);
    actions.removeAt(index);

    final updated = _safetyPlan!.copyWith(environmentalSafety: actions);
    await saveSafetyPlan(updated);
  }

  /// Get UK crisis hotlines (always available even if no safety plan)
  List<CrisisContact> getUKCrisisHotlines() {
    return [
      CrisisContact(
        name: 'Samaritans (24/7)',
        phone: '116 123',
        relationship: 'Free to call, 24 hours a day',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Shout Crisis Text Line',
        phone: '85258',
        relationship: 'Text SHOUT to this number (free, 24/7)',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'NHS 111',
        phone: '111',
        relationship: 'Mental health crisis support',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Emergency Services',
        phone: '999',
        relationship: 'If you or someone else is in immediate danger',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Mind Infoline',
        phone: '0300 123 3393',
        relationship: 'Mon-Fri, 9am-6pm',
        isEmergency: false,
      ),
      CrisisContact(
        name: 'Papyrus (Under 35s)',
        phone: '0800 068 4141',
        relationship: 'Suicide prevention, Mon-Fri 10am-10pm, weekends 2pm-10pm',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'CALM (Men)',
        phone: '0800 58 58 58',
        relationship: 'Campaign Against Living Miserably, daily 5pm-midnight',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'The Mix (Under 25s)',
        phone: '0808 808 4994',
        relationship: 'Free, daily 3pm-midnight',
        isEmergency: false,
      ),
    ];
  }

  /// Reload safety plan from storage
  Future<void> reload() async {
    await loadSafetyPlan();
  }
}
