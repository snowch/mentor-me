import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'checkin.g.dart';

/// Data model for check-in tracking and scheduling.
///
/// **JSON Schema:** lib/schemas/v2.json (checkins field)
/// **Schema Version:** 2 (current)
/// **Export Format:** lib/services/backup_service.dart (checkins field)
///
/// When modifying this model, ensure you update:
/// 1. JSON Schema (lib/schemas/vX.json)
/// 2. Migration (lib/migrations/) if needed
/// 3. Schema validator (lib/services/schema_validator.dart)
/// See CLAUDE.md "Data Schema Management" section for full checklist.

/// Converter for DateTime stored as milliseconds since epoch
class _MillisecondsDateTimeConverter implements JsonConverter<DateTime?, int?> {
  const _MillisecondsDateTimeConverter();

  @override
  DateTime? fromJson(int? json) {
    if (json == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(json);
  }

  @override
  int? toJson(DateTime? object) {
    return object?.millisecondsSinceEpoch;
  }
}

@JsonSerializable()
class Checkin {
  @JsonKey(defaultValue: '')
  final String id;

  @_MillisecondsDateTimeConverter()
  final DateTime? nextCheckinTime;

  @_MillisecondsDateTimeConverter()
  final DateTime? lastCompletedAt;

  final Map<String, dynamic>? responses;

  Checkin({
    String? id,
    this.nextCheckinTime,
    this.lastCompletedAt,
    this.responses,
  }) : id = id ?? const Uuid().v4();

  /// Auto-generated serialization - ensures all fields are included
  factory Checkin.fromJson(Map<String, dynamic> json) => _$CheckinFromJson(json);

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$CheckinToJson(this);

  Checkin copyWith({
    DateTime? nextCheckinTime,
    DateTime? lastCompletedAt,
    Map<String, dynamic>? responses,
  }) {
    return Checkin(
      id: id,
      nextCheckinTime: nextCheckinTime ?? this.nextCheckinTime,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      responses: responses ?? this.responses,
    );
  }
}
