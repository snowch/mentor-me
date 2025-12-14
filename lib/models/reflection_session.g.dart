// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reflection_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReflectionExchange _$ReflectionExchangeFromJson(Map<String, dynamic> json) =>
    ReflectionExchange(
      mentorQuestion: json['mentorQuestion'] as String,
      userResponse: json['userResponse'] as String,
      sequenceOrder: (json['sequenceOrder'] as num).toInt(),
      followUpContext: json['followUpContext'] as String?,
    );

Map<String, dynamic> _$ReflectionExchangeToJson(ReflectionExchange instance) =>
    <String, dynamic>{
      'mentorQuestion': instance.mentorQuestion,
      'userResponse': instance.userResponse,
      'sequenceOrder': instance.sequenceOrder,
      'followUpContext': instance.followUpContext,
    };

DetectedPattern _$DetectedPatternFromJson(Map<String, dynamic> json) =>
    DetectedPattern(
      type: $enumDecode(_$PatternTypeEnumMap, json['type']),
      confidence: (json['confidence'] as num).toDouble(),
      evidence: json['evidence'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$DetectedPatternToJson(DetectedPattern instance) =>
    <String, dynamic>{
      'type': _$PatternTypeEnumMap[instance.type]!,
      'confidence': instance.confidence,
      'evidence': instance.evidence,
      'description': instance.description,
    };

const _$PatternTypeEnumMap = {
  PatternType.general: 'general',
  PatternType.impulseControl: 'impulseControl',
  PatternType.negativeThoughtSpirals: 'negativeThoughtSpirals',
  PatternType.perfectionism: 'perfectionism',
  PatternType.avoidance: 'avoidance',
  PatternType.overwhelm: 'overwhelm',
  PatternType.lowMotivation: 'lowMotivation',
  PatternType.selfCriticism: 'selfCriticism',
  PatternType.procrastination: 'procrastination',
  PatternType.anxiousThinking: 'anxiousThinking',
  PatternType.blackAndWhiteThinking: 'blackAndWhiteThinking',
};

Intervention _$InterventionFromJson(Map<String, dynamic> json) => Intervention(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      howToApply: json['howToApply'] as String,
      targetPattern: $enumDecode(_$PatternTypeEnumMap, json['targetPattern']),
      category: $enumDecode(_$InterventionCategoryEnumMap, json['category']),
      habitSuggestion: json['habitSuggestion'] as String?,
    );

Map<String, dynamic> _$InterventionToJson(Intervention instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'howToApply': instance.howToApply,
      'targetPattern': _$PatternTypeEnumMap[instance.targetPattern]!,
      'category': _$InterventionCategoryEnumMap[instance.category]!,
      'habitSuggestion': instance.habitSuggestion,
    };

const _$InterventionCategoryEnumMap = {
  InterventionCategory.mindfulness: 'mindfulness',
  InterventionCategory.cognitive: 'cognitive',
  InterventionCategory.behavioral: 'behavioral',
  InterventionCategory.selfCompassion: 'selfCompassion',
  InterventionCategory.acceptance: 'acceptance',
};

ProposedAction _$ProposedActionFromJson(Map<String, dynamic> json) =>
    ProposedAction(
      id: json['id'] as String,
      type: $enumDecode(_$ActionTypeEnumMap, json['type']),
      description: json['description'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      proposedAt: DateTime.parse(json['proposedAt'] as String),
    );

Map<String, dynamic> _$ProposedActionToJson(ProposedAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ActionTypeEnumMap[instance.type]!,
      'description': instance.description,
      'parameters': instance.parameters,
      'proposedAt': instance.proposedAt.toIso8601String(),
    };

const _$ActionTypeEnumMap = {
  ActionType.createGoal: 'createGoal',
  ActionType.updateGoal: 'updateGoal',
  ActionType.deleteGoal: 'deleteGoal',
  ActionType.moveGoalToActive: 'moveGoalToActive',
  ActionType.moveGoalToBacklog: 'moveGoalToBacklog',
  ActionType.completeGoal: 'completeGoal',
  ActionType.abandonGoal: 'abandonGoal',
  ActionType.createMilestone: 'createMilestone',
  ActionType.updateMilestone: 'updateMilestone',
  ActionType.deleteMilestone: 'deleteMilestone',
  ActionType.completeMilestone: 'completeMilestone',
  ActionType.uncompleteMilestone: 'uncompleteMilestone',
  ActionType.createHabit: 'createHabit',
  ActionType.updateHabit: 'updateHabit',
  ActionType.deleteHabit: 'deleteHabit',
  ActionType.pauseHabit: 'pauseHabit',
  ActionType.activateHabit: 'activateHabit',
  ActionType.archiveHabit: 'archiveHabit',
  ActionType.markHabitComplete: 'markHabitComplete',
  ActionType.unmarkHabitComplete: 'unmarkHabitComplete',
  ActionType.createCheckInTemplate: 'createCheckInTemplate',
  ActionType.scheduleCheckInReminder: 'scheduleCheckInReminder',
  ActionType.saveSessionAsJournal: 'saveSessionAsJournal',
  ActionType.scheduleFollowUp: 'scheduleFollowUp',
  ActionType.recordWin: 'recordWin',
};

ExecutedAction _$ExecutedActionFromJson(Map<String, dynamic> json) =>
    ExecutedAction(
      proposedActionId: json['proposedActionId'] as String,
      type: $enumDecode(_$ActionTypeEnumMap, json['type']),
      description: json['description'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      confirmed: json['confirmed'] as bool,
      executedAt: DateTime.parse(json['executedAt'] as String),
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
      resultId: json['resultId'] as String?,
    );

Map<String, dynamic> _$ExecutedActionToJson(ExecutedAction instance) =>
    <String, dynamic>{
      'proposedActionId': instance.proposedActionId,
      'type': _$ActionTypeEnumMap[instance.type]!,
      'description': instance.description,
      'parameters': instance.parameters,
      'confirmed': instance.confirmed,
      'executedAt': instance.executedAt.toIso8601String(),
      'success': instance.success,
      'errorMessage': instance.errorMessage,
      'resultId': instance.resultId,
    };

SessionOutcome _$SessionOutcomeFromJson(Map<String, dynamic> json) =>
    SessionOutcome(
      actionsProposed: (json['actionsProposed'] as List<dynamic>?)
              ?.map((e) => ProposedAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      actionsExecuted: (json['actionsExecuted'] as List<dynamic>?)
              ?.map((e) => ExecutedAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      checkInTemplatesCreated:
          (json['checkInTemplatesCreated'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
      sessionSummary: json['sessionSummary'] as String?,
    );

Map<String, dynamic> _$SessionOutcomeToJson(SessionOutcome instance) =>
    <String, dynamic>{
      'actionsProposed': instance.actionsProposed,
      'actionsExecuted': instance.actionsExecuted,
      'checkInTemplatesCreated': instance.checkInTemplatesCreated,
      'sessionSummary': instance.sessionSummary,
    };

ReflectionSession _$ReflectionSessionFromJson(Map<String, dynamic> json) =>
    ReflectionSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      type: $enumDecode(_$ReflectionSessionTypeEnumMap, json['type']),
      exchanges: (json['exchanges'] as List<dynamic>?)
              ?.map(
                  (e) => ReflectionExchange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      patterns: (json['patterns'] as List<dynamic>?)
              ?.map((e) => DetectedPattern.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => Intervention.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      summary: json['summary'] as String?,
      linkedJournalId: json['linkedJournalId'] as String?,
      linkedGoalId: json['linkedGoalId'] as String?,
      initialMoodRating: (json['initialMoodRating'] as num?)?.toInt(),
      outcome: json['outcome'] == null
          ? null
          : SessionOutcome.fromJson(json['outcome'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReflectionSessionToJson(ReflectionSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startedAt': instance.startedAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'type': _$ReflectionSessionTypeEnumMap[instance.type]!,
      'exchanges': instance.exchanges,
      'patterns': instance.patterns,
      'recommendations': instance.recommendations,
      'summary': instance.summary,
      'linkedJournalId': instance.linkedJournalId,
      'linkedGoalId': instance.linkedGoalId,
      'initialMoodRating': instance.initialMoodRating,
      'outcome': instance.outcome,
    };

const _$ReflectionSessionTypeEnumMap = {
  ReflectionSessionType.general: 'general',
  ReflectionSessionType.goalFocused: 'goalFocused',
  ReflectionSessionType.emotionalCheckin: 'emotionalCheckin',
  ReflectionSessionType.challengeAnalysis: 'challengeAnalysis',
};
