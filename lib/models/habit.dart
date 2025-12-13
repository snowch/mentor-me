import 'package:uuid/uuid.dart';

enum HabitStatus {
  active,     // Currently working on (max 2)
  backlog,    // Planning to do later
  completed,  // Established as routine
  abandoned,  // Decided not to pursue
}

/// Habit maturity lifecycle - tracks progression from new habit to ingrained behavior
/// Based on research that habits take ~66 days to form on average
enum HabitMaturity {
  forming,      // 0-21 days: Active tracking, needs reminders
  established,  // 22-65 days: Consistent but still tracking
  ingrained,    // 66+ days: Graduated - automatic behavior
}

/// Data model for habits and habit tracking.
///
/// **JSON Schema:** lib/schemas/v2.json (habits field)
/// **Schema Version:** 2 (current)
/// **Export Format:** lib/services/backup_service.dart (habits field)
///
/// When modifying this model, ensure you update:
/// 1. JSON Schema (lib/schemas/vX.json)
/// 2. Migration (lib/migrations/) if needed
/// 3. Schema validator (lib/services/schema_validator.dart)
/// See CLAUDE.md "Data Schema Management" section for full checklist.
class Habit {
  final String id;
  final String title;
  final String description;
  final String? linkedGoalId; // Optional - can be independent
  final HabitFrequency frequency;
  final int targetCount; // e.g., 3 times per week
  final List<DateTime> completionDates;
  final int currentStreak;
  final int longestStreak;
  final bool isActive;  // Deprecated: Use status instead
  final HabitStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;  // Last modification timestamp
  final bool isSystemCreated; // True if created by system (onboarding, suggestions)
  final String? systemType; // e.g., 'daily_reflection', 'suggested', null for user-created
  final int sortOrder; // For drag-and-drop reordering

  // Habit maturity lifecycle
  final HabitMaturity maturity; // Current maturity stage
  final int daysToFormation; // Target days to form habit (default 66)
  final DateTime? graduatedAt; // When marked as ingrained

  Habit({
    String? id,
    required this.title,
    required this.description,
    this.linkedGoalId,
    this.frequency = HabitFrequency.daily,
    this.targetCount = 1,
    List<DateTime>? completionDates,
    this.currentStreak = 0,
    this.longestStreak = 0,
    bool? isActive,  // Deprecated - auto-syncs with status if not provided
    this.status = HabitStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSystemCreated = false,
    this.systemType,
    this.sortOrder = 0,
    this.maturity = HabitMaturity.forming,
    this.daysToFormation = 66,
    this.graduatedAt,
  })  : id = id ?? const Uuid().v4(),
        completionDates = completionDates ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now(),
        isActive = isActive ?? (status == HabitStatus.active);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'linkedGoalId': linkedGoalId,
      'frequency': frequency.toString(),
      'targetCount': targetCount,
      'completionDates': completionDates.map((d) => d.toIso8601String()).toList(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'isActive': isActive,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSystemCreated': isSystemCreated,
      'systemType': systemType,
      'sortOrder': sortOrder,
      'maturity': maturity.toString(),
      'daysToFormation': daysToFormation,
      'graduatedAt': graduatedAt?.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    // Parse status, defaulting to active for backwards compatibility
    HabitStatus parsedStatus = HabitStatus.active;
    if (json['status'] != null) {
      parsedStatus = HabitStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => HabitStatus.active,
      );
    }

    // Parse maturity, defaulting to forming for backwards compatibility
    HabitMaturity parsedMaturity = HabitMaturity.forming;
    if (json['maturity'] != null) {
      parsedMaturity = HabitMaturity.values.firstWhere(
        (e) => e.toString() == json['maturity'],
        orElse: () => HabitMaturity.forming,
      );
    }

    final createdAt = DateTime.parse(json['createdAt']);

    return Habit(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      linkedGoalId: json['linkedGoalId'],
      frequency: HabitFrequency.values.firstWhere(
        (e) => e.toString() == json['frequency'],
      ),
      targetCount: json['targetCount'],
      completionDates: (json['completionDates'] as List)
          .map((d) => DateTime.parse(d))
          .toList(),
      currentStreak: json['currentStreak'],
      longestStreak: json['longestStreak'],
      isActive: json['isActive'],
      status: parsedStatus,
      createdAt: createdAt,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : createdAt, // Backward compatibility: use createdAt if updatedAt missing
      isSystemCreated: json['isSystemCreated'] ?? false, // Default false for backwards compatibility
      systemType: json['systemType'],
      sortOrder: json['sortOrder'] ?? 0, // Default 0 for backwards compatibility
      maturity: parsedMaturity,
      daysToFormation: json['daysToFormation'] ?? 66, // Default 66 days for habit formation
      graduatedAt: json['graduatedAt'] != null
          ? DateTime.parse(json['graduatedAt'])
          : null,
    );
  }

  Habit copyWith({
    String? title,
    String? description,
    String? linkedGoalId,
    HabitFrequency? frequency,
    int? targetCount,
    List<DateTime>? completionDates,
    int? currentStreak,
    int? longestStreak,
    bool? isActive,
    HabitStatus? status,
    bool? isSystemCreated,
    String? systemType,
    int? sortOrder,
    HabitMaturity? maturity,
    int? daysToFormation,
    DateTime? graduatedAt,
  }) {
    // Auto-sync isActive with status if status is provided but isActive is not
    final newStatus = status ?? this.status;
    final newIsActive = isActive ??
      (status != null ? (newStatus == HabitStatus.active) : this.isActive);

    return Habit(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      completionDates: completionDates ?? this.completionDates,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isActive: newIsActive,
      status: newStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),  // Always update timestamp on modification
      isSystemCreated: isSystemCreated ?? this.isSystemCreated,
      systemType: systemType ?? this.systemType,
      sortOrder: sortOrder ?? this.sortOrder,
      maturity: maturity ?? this.maturity,
      daysToFormation: daysToFormation ?? this.daysToFormation,
      graduatedAt: graduatedAt ?? this.graduatedAt,
    );
  }

  /// Graduate habit to ingrained status
  Habit graduate() {
    return copyWith(
      maturity: HabitMaturity.ingrained,
      graduatedAt: DateTime.now(),
    );
  }

  /// Check if habit is ready to graduate (streak >= daysToFormation)
  bool get canGraduate =>
      currentStreak >= daysToFormation && maturity != HabitMaturity.ingrained;

  /// Progress toward graduation (0.0 to 1.0)
  double get formationProgress =>
      (currentStreak / daysToFormation).clamp(0.0, 1.0);

  /// Days remaining until graduation
  int get daysUntilGraduation =>
      (daysToFormation - currentStreak).clamp(0, daysToFormation);

  // Check if completed today
  bool get isCompletedToday {
    final today = DateTime.now();
    return completionDates.any((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);
  }

  // Get this week's completion count
  int getWeeklyProgress() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return completionDates.where((date) =>
        date.isAfter(weekStart) && date.isBefore(weekEnd)).length;
  }

  // Get completion status for last 7 days (for visualization)
  List<bool> getLast7Days() {
    final today = DateTime.now();
    final result = <bool>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final completed = completionDates.any((d) =>
          d.year == date.year &&
          d.month == date.month &&
          d.day == date.day);
      result.add(completed);
    }
    
    return result;
  }
}

enum HabitFrequency {
  daily,
  threeTimes, // 3x per week
  fiveTimes, // 5x per week
  custom,
}

extension HabitFrequencyExtension on HabitFrequency {
  String get displayName {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.threeTimes:
        return '3x per week';
      case HabitFrequency.fiveTimes:
        return '5x per week';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }

  int get weeklyTarget {
    switch (this) {
      case HabitFrequency.daily:
        return 7;
      case HabitFrequency.threeTimes:
        return 3;
      case HabitFrequency.fiveTimes:
        return 5;
      case HabitFrequency.custom:
        return 1;
    }
  }
}

extension HabitMaturityExtension on HabitMaturity {
  String get displayName {
    switch (this) {
      case HabitMaturity.forming:
        return 'Forming';
      case HabitMaturity.established:
        return 'Established';
      case HabitMaturity.ingrained:
        return 'Ingrained';
    }
  }

  String get description {
    switch (this) {
      case HabitMaturity.forming:
        return 'Building this habit - keep tracking!';
      case HabitMaturity.established:
        return 'Getting consistent - almost there!';
      case HabitMaturity.ingrained:
        return 'This habit is now automatic';
    }
  }
}