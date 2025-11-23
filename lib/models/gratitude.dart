import 'package:uuid/uuid.dart';

/// A gratitude journal entry
///
/// Evidence-based positive psychology intervention.
/// Regular gratitude practice improves wellbeing, reduces depression symptoms.
///
/// JSON Schema: lib/schemas/v3.json#definitions/gratitudeEntry_v1
class GratitudeEntry {
  final String id;
  final DateTime createdAt;
  final List<String> gratitudes;  // 3-5 things user is grateful for
  final String? elaboration;      // Optional detail about one item
  final int? moodRating;          // 1-5, mood after writing
  final String? linkedJournalId;  // If part of journal entry

  GratitudeEntry({
    String? id,
    DateTime? createdAt,
    required this.gratitudes,
    this.elaboration,
    this.moodRating,
    this.linkedJournalId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'gratitudes': gratitudes,
      'elaboration': elaboration,
      'moodRating': moodRating,
      'linkedJournalId': linkedJournalId,
    };
  }

  factory GratitudeEntry.fromJson(Map<String, dynamic> json) {
    return GratitudeEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      gratitudes: (json['gratitudes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      elaboration: json['elaboration'] as String?,
      moodRating: json['moodRating'] as int?,
      linkedJournalId: json['linkedJournalId'] as String?,
    );
  }

  GratitudeEntry copyWith({
    String? id,
    DateTime? createdAt,
    List<String>? gratitudes,
    String? elaboration,
    int? moodRating,
    String? linkedJournalId,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      gratitudes: gratitudes ?? this.gratitudes,
      elaboration: elaboration ?? this.elaboration,
      moodRating: moodRating ?? this.moodRating,
      linkedJournalId: linkedJournalId ?? this.linkedJournalId,
    );
  }

  /// Number of gratitudes listed
  int get count => gratitudes.length;

  /// Whether this entry is complete (3+ gratitudes)
  bool get isComplete => count >= 3;
}

/// Gratitude practice prompts
class GratitudePrompts {
  static const List<String> general = [
    'What made you smile today?',
    'Who showed you kindness recently?',
    'What challenge helped you grow?',
    'What comfort or luxury are you grateful for?',
    'What in nature are you thankful for?',
  ];

  static const List<String> relationships = [
    'Who supported you this week?',
    'What quality in a loved one do you appreciate?',
    'What conversation brought you joy?',
    'Who made your life easier recently?',
  ];

  static const List<String> personal = [
    'What personal strength helped you today?',
    'What ability or skill are you thankful for?',
    'What part of your body worked well for you today?',
    'What did you learn recently?',
  ];

  static const List<String> moments = [
    'What small moment brought you peace today?',
    'What made you feel safe or secure?',
    'What sensory experience did you enjoy? (taste, smell, sound, etc.)',
    'What went better than expected?',
  ];

  static const List<String> difficult = [
    'What difficult situation taught you something valuable?',
    'What challenge are you proud of facing?',
    'What ended up being a blessing in disguise?',
    'What did you handle well despite difficulty?',
  ];

  /// Get a random prompt
  static String getRandom() {
    final allPrompts = [
      ...general,
      ...relationships,
      ...personal,
      ...moments,
      ...difficult,
    ];
    allPrompts.shuffle();
    return allPrompts.first;
  }

  /// Get prompts by category
  static List<String> getByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'relationships':
        return relationships;
      case 'personal':
        return personal;
      case 'moments':
        return moments;
      case 'difficult':
        return difficult;
      default:
        return general;
    }
  }
}

/// Gratitude streak tracking
class GratitudeStreak {
  final int currentStreak;  // Days in a row
  final int longestStreak;
  final DateTime? lastEntryDate;
  final int totalEntries;

  const GratitudeStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastEntryDate,
    required this.totalEntries,
  });

  /// Whether streak is active (entry today or yesterday)
  bool get isActive {
    if (lastEntryDate == null) return false;
    final now = DateTime.now();
    final diff = now.difference(lastEntryDate!).inDays;
    return diff <= 1;
  }

  /// Calculate streak from list of entries
  static GratitudeStreak fromEntries(List<GratitudeEntry> entries) {
    if (entries.isEmpty) {
      return const GratitudeStreak(
        currentStreak: 0,
        longestStreak: 0,
        totalEntries: 0,
      );
    }

    // Sort by date descending
    final sorted = List<GratitudeEntry>.from(entries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;

    for (final entry in sorted) {
      final entryDate = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );

      if (lastDate == null) {
        // First entry
        tempStreak = 1;
        currentStreak = 1;
      } else {
        final diff = lastDate.difference(entryDate).inDays;
        if (diff == 1) {
          // Consecutive day
          tempStreak++;
          if (tempStreak > currentStreak) currentStreak = tempStreak;
        } else {
          // Streak broken
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 1;
        }
      }

      lastDate = entryDate;
    }

    if (tempStreak > longestStreak) longestStreak = tempStreak;

    return GratitudeStreak(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastEntryDate: sorted.first.createdAt,
      totalEntries: entries.length,
    );
  }
}
