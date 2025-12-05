// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeightEntry _$WeightEntryFromJson(Map<String, dynamic> json) => WeightEntry(
      id: json['id'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
      weight: (json['weight'] as num).toDouble(),
      unit: $enumDecode(_$WeightUnitEnumMap, json['unit']),
      note: json['note'] as String?,
      stones: (json['stones'] as num?)?.toInt(),
      pounds: (json['pounds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WeightEntryToJson(WeightEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'weight': instance.weight,
      'unit': _$WeightUnitEnumMap[instance.unit]!,
      'note': instance.note,
      'stones': instance.stones,
      'pounds': instance.pounds,
    };

const _$WeightUnitEnumMap = {
  WeightUnit.kg: 'kg',
  WeightUnit.lbs: 'lbs',
  WeightUnit.stone: 'stone',
};

WeightGoal _$WeightGoalFromJson(Map<String, dynamic> json) => WeightGoal(
      id: json['id'] as String?,
      targetWeight: (json['targetWeight'] as num).toDouble(),
      startWeight: (json['startWeight'] as num).toDouble(),
      unit: $enumDecode(_$WeightUnitEnumMap, json['unit']),
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      targetDate: json['targetDate'] == null
          ? null
          : DateTime.parse(json['targetDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$WeightGoalToJson(WeightGoal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'targetWeight': instance.targetWeight,
      'startWeight': instance.startWeight,
      'unit': _$WeightUnitEnumMap[instance.unit]!,
      'startDate': instance.startDate.toIso8601String(),
      'targetDate': instance.targetDate?.toIso8601String(),
      'isActive': instance.isActive,
    };
