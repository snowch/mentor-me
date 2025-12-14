// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'values_and_smart_goals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalValue _$PersonalValueFromJson(Map<String, dynamic> json) =>
    PersonalValue(
      id: json['id'] as String?,
      domain: $enumDecode(_$ValueDomainEnumMap, json['domain']),
      statement: json['statement'] as String,
      description: json['description'] as String?,
      importanceRating: (json['importanceRating'] as num?)?.toInt() ?? 5,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.parse(json['lastReviewedAt'] as String),
    );

Map<String, dynamic> _$PersonalValueToJson(PersonalValue instance) =>
    <String, dynamic>{
      'id': instance.id,
      'domain': _$ValueDomainEnumMap[instance.domain]!,
      'statement': instance.statement,
      'description': instance.description,
      'importanceRating': instance.importanceRating,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
    };

const _$ValueDomainEnumMap = {
  ValueDomain.relationships: 'relationships',
  ValueDomain.work: 'work',
  ValueDomain.health: 'health',
  ValueDomain.personalGrowth: 'personalGrowth',
  ValueDomain.leisure: 'leisure',
  ValueDomain.community: 'community',
  ValueDomain.other: 'other',
};

SMARTCriteria _$SMARTCriteriaFromJson(Map<String, dynamic> json) =>
    SMARTCriteria(
      isSpecific: json['isSpecific'] as bool? ?? false,
      isMeasurable: json['isMeasurable'] as bool? ?? false,
      isAchievable: json['isAchievable'] as bool? ?? false,
      isRelevant: json['isRelevant'] as bool? ?? false,
      isTimeBound: json['isTimeBound'] as bool? ?? false,
      specificDetails: json['specificDetails'] as String?,
      measurementCriteria: json['measurementCriteria'] as String?,
      achievabilityNotes: json['achievabilityNotes'] as String?,
      relevanceReason: json['relevanceReason'] as String?,
      timeframe: json['timeframe'] as String?,
      linkedValueIds: (json['linkedValueIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SMARTCriteriaToJson(SMARTCriteria instance) =>
    <String, dynamic>{
      'isSpecific': instance.isSpecific,
      'isMeasurable': instance.isMeasurable,
      'isAchievable': instance.isAchievable,
      'isRelevant': instance.isRelevant,
      'isTimeBound': instance.isTimeBound,
      'specificDetails': instance.specificDetails,
      'measurementCriteria': instance.measurementCriteria,
      'achievabilityNotes': instance.achievabilityNotes,
      'relevanceReason': instance.relevanceReason,
      'timeframe': instance.timeframe,
      'linkedValueIds': instance.linkedValueIds,
    };
