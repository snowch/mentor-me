import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'pulse_type.g.dart';

/// Represents a configurable pulse check type that users can create and manage
/// JSON Schema: lib/schemas/v2.json#definitions/pulseType_v2
@JsonSerializable()
class PulseType {
  final String id;
  final String name;
  final String iconName; // Store icon name (e.g., 'mood', 'bolt')
  final String colorHex; // Store color as hex string (e.g., "FF5252")
  @JsonKey(defaultValue: true)
  final bool isActive;
  @JsonKey(defaultValue: 0)
  final int order; // For sorting in UI
  final DateTime createdAt;
  final DateTime? updatedAt;

  PulseType({
    String? id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.isActive = true,
    this.order = 0,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$PulseTypeToJson(this);

  /// Auto-generated deserialization with backward compatibility support
  factory PulseType.fromJson(Map<String, dynamic> json) {
    // Support backward compatibility with old 'iconCodePoint' field
    if (json['iconCodePoint'] != null && json['iconName'] == null) {
      // Old format - migrate to new iconName format
      json = {...json, 'iconName': json['iconName'] ?? 'mood'};
    }
    return _$PulseTypeFromJson(json);
  }

  PulseType copyWith({
    String? name,
    String? iconName,
    String? colorHex,
    bool? isActive,
    int? order,
    DateTime? updatedAt,
  }) {
    return PulseType(
      id: id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Returns default pulse types for new users
  static List<PulseType> getDefaults() {
    return [
      PulseType(
        name: 'Mood',
        iconName: 'mood',
        colorHex: 'FFE91E63', // Pink
        order: 1,
      ),
      PulseType(
        name: 'Energy',
        iconName: 'bolt',
        colorHex: 'FFFFB300', // Amber
        order: 2,
      ),
      PulseType(
        name: 'Wellness',
        iconName: 'favorite',
        colorHex: 'FF2196F3', // Blue
        order: 3,
      ),
    ];
  }
}
