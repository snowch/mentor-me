import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'milestone.g.dart';

/// Data model for goal milestones.
///
/// JSON Schema: lib/schemas/v2.json#definitions/milestone_v2
@JsonSerializable()
class Milestone {
  final String id;
  final String goalId;
  final String title;
  final String description;
  final DateTime? targetDate;
  final DateTime? completedDate;
  final int order;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;  // Last modification timestamp

  Milestone({
    String? id,
    required this.goalId,
    required this.title,
    required this.description,
    this.targetDate,
    this.completedDate,
    required this.order,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  /// Auto-generated serialization - ensures all fields are included
  factory Milestone.fromJson(Map<String, dynamic> json) => _$MilestoneFromJson(json);

  /// Auto-generated serialization - ensures all fields are included
  Map<String, dynamic> toJson() => _$MilestoneToJson(this);

  Milestone markComplete() {
    return copyWith(
      isCompleted: true,
      completedDate: DateTime.now(),
    );
  }

  Milestone copyWith({
    String? title,
    String? description,
    DateTime? targetDate,
    DateTime? completedDate,
    int? order,
    bool? isCompleted,
  }) {
    return Milestone(
      id: id,
      goalId: goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),  // Always update timestamp on modification
    );
  }
}
