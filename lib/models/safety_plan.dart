import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'safety_plan.g.dart';

/// Contact for crisis support
///
/// JSON Schema: lib/schemas/v3.json#definitions/crisisContact_v1
@JsonSerializable()
class CrisisContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isEmergency;

  CrisisContact({
    String? id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isEmergency = false,
  }) : id = id ?? const Uuid().v4();

  /// Auto-generated serialization - ensures all fields are included
  factory CrisisContact.fromJson(Map<String, dynamic> json) => _$CrisisContactFromJson(json);
  Map<String, dynamic> toJson() => _$CrisisContactToJson(this);

  CrisisContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isEmergency,
  }) {
    return CrisisContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }
}

/// Personal safety plan for crisis situations
///
/// Based on evidence-based crisis intervention and suicide prevention frameworks.
/// Helps users identify warning signs, coping strategies, and support contacts.
///
/// JSON Schema: lib/schemas/v3.json#definitions/safetyPlan_v1
@JsonSerializable(explicitToJson: true)
class SafetyPlan {
  final String id;
  final DateTime createdAt;
  final DateTime lastUpdated;

  /// Personal warning signs that crisis may be developing
  final List<String> warningSignsPersonal;

  /// Internal coping strategies (things I can do without contacting anyone)
  final List<String> copingStrategiesInternal;

  /// Social contacts who can help distract from crisis
  final List<CrisisContact> socialSupports;

  /// Professional contacts and crisis hotlines
  final List<CrisisContact> professionalContacts;

  /// Reasons for living / things that make life worth living
  final List<String> reasonsToLive;

  /// Environmental safety (remove means of harm)
  final List<String> environmentalSafety;

  SafetyPlan({
    String? id,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<String>? warningSignsPersonal,
    List<String>? copingStrategiesInternal,
    List<CrisisContact>? socialSupports,
    List<CrisisContact>? professionalContacts,
    List<String>? reasonsToLive,
    List<String>? environmentalSafety,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now(),
        warningSignsPersonal = warningSignsPersonal ?? [],
        copingStrategiesInternal = copingStrategiesInternal ?? [],
        socialSupports = socialSupports ?? [],
        professionalContacts = professionalContacts ?? _defaultUKProfessionalContacts(),
        reasonsToLive = reasonsToLive ?? [],
        environmentalSafety = environmentalSafety ?? [];

  /// Default UK crisis contacts (Samaritans, Shout, NHS 111, etc.)
  static List<CrisisContact> _defaultUKProfessionalContacts() {
    return [
      CrisisContact(
        name: 'Samaritans (24/7)',
        phone: '116 123',
        relationship: 'Crisis helpline',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Shout Crisis Text Line',
        phone: '85258',
        relationship: 'Text SHOUT to this number',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'NHS 111 (Mental Health Crisis)',
        phone: '111',
        relationship: 'NHS urgent mental health support',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Emergency Services',
        phone: '999',
        relationship: 'For immediate danger',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'Mind Infoline',
        phone: '0300 123 3393',
        relationship: 'Mental health information',
        isEmergency: false,
      ),
      CrisisContact(
        name: 'Papyrus (Under 35s)',
        phone: '0800 068 4141',
        relationship: 'Suicide prevention for young people',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'CALM (Men)',
        phone: '0800 58 58 58',
        relationship: 'Campaign Against Living Miserably',
        isEmergency: true,
      ),
      CrisisContact(
        name: 'The Mix (Under 25s)',
        phone: '0808 808 4994',
        relationship: 'Support for young people',
        isEmergency: false,
      ),
    ];
  }

  bool get isComplete {
    return warningSignsPersonal.isNotEmpty &&
        copingStrategiesInternal.isNotEmpty &&
        socialSupports.isNotEmpty &&
        reasonsToLive.isNotEmpty;
  }

  int get completionPercentage {
    int complete = 0;
    int total = 5;

    if (warningSignsPersonal.isNotEmpty) complete++;
    if (copingStrategiesInternal.isNotEmpty) complete++;
    if (socialSupports.isNotEmpty) complete++;
    if (reasonsToLive.isNotEmpty) complete++;
    if (environmentalSafety.isNotEmpty) complete++;

    return (complete / total * 100).round();
  }

  /// Auto-generated serialization - ensures all fields are included
  factory SafetyPlan.fromJson(Map<String, dynamic> json) => _$SafetyPlanFromJson(json);
  Map<String, dynamic> toJson() => _$SafetyPlanToJson(this);

  SafetyPlan copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<String>? warningSignsPersonal,
    List<String>? copingStrategiesInternal,
    List<CrisisContact>? socialSupports,
    List<CrisisContact>? professionalContacts,
    List<String>? reasonsToLive,
    List<String>? environmentalSafety,
  }) {
    return SafetyPlan(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      warningSignsPersonal: warningSignsPersonal ?? this.warningSignsPersonal,
      copingStrategiesInternal: copingStrategiesInternal ?? this.copingStrategiesInternal,
      socialSupports: socialSupports ?? this.socialSupports,
      professionalContacts: professionalContacts ?? this.professionalContacts,
      reasonsToLive: reasonsToLive ?? this.reasonsToLive,
      environmentalSafety: environmentalSafety ?? this.environmentalSafety,
    );
  }
}
