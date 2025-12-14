// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mentor_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MentorAction _$MentorActionFromJson(Map<String, dynamic> json) => MentorAction(
      label: json['label'] as String,
      type: $enumDecode(_$MentorActionTypeEnumMap, json['type']),
      destination: json['destination'] as String?,
      context: json['context'] as Map<String, dynamic>?,
      chatPreFill: json['chatPreFill'] as String?,
    );

Map<String, dynamic> _$MentorActionToJson(MentorAction instance) =>
    <String, dynamic>{
      'label': instance.label,
      'type': _$MentorActionTypeEnumMap[instance.type]!,
      'destination': instance.destination,
      'context': instance.context,
      'chatPreFill': instance.chatPreFill,
    };

const _$MentorActionTypeEnumMap = {
  MentorActionType.navigate: 'navigate',
  MentorActionType.chat: 'chat',
  MentorActionType.quickAction: 'quickAction',
};

MentorCoachingCard _$MentorCoachingCardFromJson(Map<String, dynamic> json) =>
    MentorCoachingCard(
      message: json['message'] as String,
      primaryAction:
          MentorAction.fromJson(json['primaryAction'] as Map<String, dynamic>),
      secondaryAction: MentorAction.fromJson(
          json['secondaryAction'] as Map<String, dynamic>),
      urgency: $enumDecodeNullable(_$CardUrgencyEnumMap, json['urgency']) ??
          CardUrgency.info,
    );

Map<String, dynamic> _$MentorCoachingCardToJson(MentorCoachingCard instance) =>
    <String, dynamic>{
      'message': instance.message,
      'primaryAction': instance.primaryAction,
      'secondaryAction': instance.secondaryAction,
      'urgency': _$CardUrgencyEnumMap[instance.urgency]!,
    };

const _$CardUrgencyEnumMap = {
  CardUrgency.urgent: 'urgent',
  CardUrgency.attention: 'attention',
  CardUrgency.celebration: 'celebration',
  CardUrgency.info: 'info',
};

UserState _$UserStateFromJson(Map<String, dynamic> json) => UserState(
      type: $enumDecode(_$UserStateTypeEnumMap, json['type']),
      context: json['context'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserStateToJson(UserState instance) => <String, dynamic>{
      'type': _$UserStateTypeEnumMap[instance.type]!,
      'context': instance.context,
    };

const _$UserStateTypeEnumMap = {
  UserStateType.newUser: 'newUser',
  UserStateType.urgentDeadline: 'urgentDeadline',
  UserStateType.unstartedGoal: 'unstartedGoal',
  UserStateType.stalledGoal: 'stalledGoal',
  UserStateType.streakAtRisk: 'streakAtRisk',
  UserStateType.miniWin: 'miniWin',
  UserStateType.onlyJournals: 'onlyJournals',
  UserStateType.onlyHabits: 'onlyHabits',
  UserStateType.onlyGoals: 'onlyGoals',
  UserStateType.journalsAndHabits: 'journalsAndHabits',
  UserStateType.journalsAndGoals: 'journalsAndGoals',
  UserStateType.habitsAndGoals: 'habitsAndGoals',
  UserStateType.comeback: 'comeback',
  UserStateType.struggling: 'struggling',
  UserStateType.cognitiveDistortion: 'cognitiveDistortion',
  UserStateType.overcommitted: 'overcommitted',
  UserStateType.winning: 'winning',
  UserStateType.dataQuality: 'dataQuality',
  UserStateType.balanced: 'balanced',
  UserStateType.needsHaltCheck: 'needsHaltCheck',
  UserStateType.needsSafetyPlan: 'needsSafetyPlan',
  UserStateType.valuesDrift: 'valuesDrift',
  UserStateType.discoverChat: 'discoverChat',
  UserStateType.discoverHabitChecking: 'discoverHabitChecking',
  UserStateType.discoverMilestones: 'discoverMilestones',
  UserStateType.goalQuarterway: 'goalQuarterway',
  UserStateType.goalHalfway: 'goalHalfway',
  UserStateType.goalFinishLine: 'goalFinishLine',
};
