// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pulse_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PulseType _$PulseTypeFromJson(Map<String, dynamic> json) => PulseType(
      id: json['id'] as String?,
      name: json['name'] as String,
      iconName: json['iconName'] as String,
      colorHex: json['colorHex'] as String,
      isActive: json['isActive'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PulseTypeToJson(PulseType instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconName': instance.iconName,
      'colorHex': instance.colorHex,
      'isActive': instance.isActive,
      'order': instance.order,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
