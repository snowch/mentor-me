import '../models/reflection_session.dart';

/// Severity level for detected patterns or crises
enum PatternSeverity {
  /// Manageable with self-help techniques
  mild,

  /// Monitor closely, may benefit from professional support
  moderate,

  /// Recommend professional help strongly
  severe,

  /// Immediate safety intervention required
  crisis,
}

extension PatternSeverityExtension on PatternSeverity {
  String get displayName {
    switch (this) {
      case PatternSeverity.mild:
        return 'Mild';
      case PatternSeverity.moderate:
        return 'Moderate';
      case PatternSeverity.severe:
        return 'Severe';
      case PatternSeverity.crisis:
        return 'Crisis';
    }
  }

  String get description {
    switch (this) {
      case PatternSeverity.mild:
        return 'Manageable with self-help techniques';
      case PatternSeverity.moderate:
        return 'Consider speaking to a professional';
      case PatternSeverity.severe:
        return 'Strongly recommend professional support';
      case PatternSeverity.crisis:
        return 'Immediate help needed';
    }
  }

  String get emoji {
    switch (this) {
      case PatternSeverity.mild:
        return '💭';
      case PatternSeverity.moderate:
        return '⚠️';
      case PatternSeverity.severe:
        return '🚨';
      case PatternSeverity.crisis:
        return '🆘';
    }
  }
}

/// Result of crisis detection analysis
class CrisisDetectionResult {
  final bool isCrisis;
  final PatternSeverity severity;
  final List<String> detectedKeywords;
  final List<String> concerningPhrases;
  final String recommendation;
  final bool requiresImmediateIntervention;

  CrisisDetectionResult({
    required this.isCrisis,
    required this.severity,
    required this.detectedKeywords,
    required this.concerningPhrases,
    required this.recommendation,
    required this.requiresImmediateIntervention,
  });
}

/// Service for detecting crisis situations in user text
///
/// Uses keyword and phrase matching to identify potential crisis situations
/// including suicidal ideation, self-harm, severe distress, and other
/// mental health emergencies.
///
/// Based on evidence-based crisis intervention frameworks and UK mental health guidelines.
class CrisisDetectionService {
  static final CrisisDetectionService _instance = CrisisDetectionService._internal();
  factory CrisisDetectionService() => _instance;
  CrisisDetectionService._internal();

  /// Crisis-level keywords that indicate immediate danger
  static const List<String> _crisisKeywords = [
    // Suicidal ideation
    'kill myself',
    'end my life',
    'want to die',
    'better off dead',
    'suicide',
    'suicidal',
    'end it all',
    'not worth living',
    'no reason to live',
    'goodbye cruel world',

    // Self-harm (active)
    'hurt myself',
    'harm myself',
    'cut myself',
    'cutting myself',
    'burn myself',

    // Immediate danger
    'going to kill',
    'planning to die',
    'have a plan',
    'wrote a note',
    'said goodbye',
    'final message',
  ];

  /// Severe-level keywords indicating high distress
  static const List<String> _severeKeywords = [
    // Hopelessness
    'no hope',
    'hopeless',
    'nothing will help',
    'will never get better',
    'pointless',
    "can't go on",
    'give up',

    // Severe depression indicators
    'worthless',
    'useless',
    'burden to everyone',
    'everyone better off without me',
    'hate myself so much',

    // Severe anxiety/panic
    'having a panic attack',
    'cannot breathe',
    'heart racing uncontrollably',
    'think i am dying',

    // Self-harm (contemplation)
    'thinking about hurting',
    'thoughts of self-harm',
    'urge to hurt',
    'want to cut',
  ];

  /// Moderate-level keywords indicating elevated risk
  static const List<String> _moderateKeywords = [
    // Passive suicidal ideation
    'wish i was dead',
    'wish i could disappear',
    "don't want to be here",
    'tired of living',

    // Severe emotional pain
    'unbearable',
    'cannot take it anymore',
    "can't cope",
    'falling apart',
    'breaking down',

    // Isolation
    'completely alone',
    'nobody cares',
    'no one understands',
    'abandoned',

    // Loss of control
    'losing my mind',
    'going crazy',
    'cannot control',
    'spiraling',
  ];

  /// Analyze text for crisis indicators
  CrisisDetectionResult analyze(String text) {
    final lowerText = text.toLowerCase();

    final crisisMatches = <String>[];
    final severeMatches = <String>[];
    final moderateMatches = <String>[];
    final concerningPhrases = <String>[];

    // Check for crisis keywords
    for (final keyword in _crisisKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        crisisMatches.add(keyword);
        concerningPhrases.add(_extractPhraseContaining(text, keyword));
      }
    }

    // Check for severe keywords
    for (final keyword in _severeKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        severeMatches.add(keyword);
        if (concerningPhrases.length < 3) {
          concerningPhrases.add(_extractPhraseContaining(text, keyword));
        }
      }
    }

    // Check for moderate keywords
    for (final keyword in _moderateKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        moderateMatches.add(keyword);
      }
    }

    // Determine severity
    PatternSeverity severity;
    bool isCrisis = false;
    bool requiresImmediateIntervention = false;
    String recommendation;

    if (crisisMatches.isNotEmpty) {
      // CRISIS: Immediate danger
      severity = PatternSeverity.crisis;
      isCrisis = true;
      requiresImmediateIntervention = true;
      recommendation = 'You mentioned thoughts of ending your life. Your safety is the top priority. '
          'Please reach out for immediate help:\n\n'
          '• Samaritans: 116 123 (24/7)\n'
          '• Shout Crisis Text: Text SHOUT to 85258\n'
          '• NHS 111 for mental health crisis\n'
          '• 999 if in immediate danger\n\n'
          'You don\'t have to go through this alone. There are people who want to help.';
    } else if (severeMatches.length >= 3 || (severeMatches.length >= 2 && moderateMatches.length >= 2)) {
      // SEVERE: Multiple severe indicators
      severity = PatternSeverity.severe;
      isCrisis = true;
      requiresImmediateIntervention = true;
      recommendation = 'What you\'re describing sounds very difficult and distressing. '
          'Please consider speaking to a mental health professional urgently:\n\n'
          '• Contact your GP for urgent referral\n'
          '• Call NHS 111 for mental health support\n'
          '• Samaritans: 116 123 (24/7 to talk)\n\n'
          'This app can support you, but professional help is important when you\'re struggling this much.';
    } else if (severeMatches.isNotEmpty || moderateMatches.length >= 3) {
      // SEVERE: Some severe indicators or multiple moderate
      severity = PatternSeverity.severe;
      recommendation = 'It sounds like you\'re going through a really tough time. '
          'Speaking to a mental health professional could be helpful:\n\n'
          '• Book an appointment with your GP\n'
          '• Call Samaritans (116 123) if you need to talk\n'
          '• Mind Infoline: 0300 123 3393\n\n'
          'Remember, asking for help is a sign of strength, not weakness.';
    } else if (moderateMatches.isNotEmpty) {
      // MODERATE: Some concerning language
      severity = PatternSeverity.moderate;
      recommendation = 'I notice you\'re struggling. Consider:\n\n'
          '• Talking to someone you trust\n'
          '• Booking a GP appointment if this continues\n'
          '• Using your safety plan if you have one\n'
          '• Practicing self-care and coping strategies\n\n'
          'Monitor how you\'re feeling. If things get worse, please reach out for professional support.';
    } else {
      // MILD: No concerning keywords
      severity = PatternSeverity.mild;
      recommendation = 'Continue using self-help strategies. If your mood worsens, don\'t hesitate to seek support.';
    }

    return CrisisDetectionResult(
      isCrisis: isCrisis,
      severity: severity,
      detectedKeywords: [...crisisMatches, ...severeMatches],
      concerningPhrases: concerningPhrases,
      recommendation: recommendation,
      requiresImmediateIntervention: requiresImmediateIntervention,
    );
  }

  /// Extract a phrase containing the keyword for context
  String _extractPhraseContaining(String text, String keyword) {
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final index = lowerText.indexOf(lowerKeyword);

    if (index == -1) return '';

    // Get ~50 characters before and after for context
    final start = (index - 50).clamp(0, text.length);
    final end = (index + keyword.length + 50).clamp(0, text.length);

    String phrase = text.substring(start, end).trim();

    // Add ellipses if we cut off text
    if (start > 0) phrase = '...$phrase';
    if (end < text.length) phrase = '$phrase...';

    return phrase;
  }

  /// Assess severity for a pattern type based on frequency and context
  PatternSeverity assessPatternSeverity(PatternType pattern, double confidence, int occurrenceCount) {
    // Crisis-level patterns
    if (pattern == PatternType.impulseControl && confidence >= 0.8 && occurrenceCount >= 5) {
      return PatternSeverity.severe;
    }

    // Severe patterns
    if (pattern == PatternType.negativeThoughtSpirals && confidence >= 0.9) {
      return PatternSeverity.severe;
    }

    if (pattern == PatternType.selfCriticism && confidence >= 0.8 && occurrenceCount >= 4) {
      return PatternSeverity.severe;
    }

    if (pattern == PatternType.avoidance && confidence >= 0.8 && occurrenceCount >= 4) {
      return PatternSeverity.severe;
    }

    // Moderate patterns
    if (confidence >= 0.6 || occurrenceCount >= 3) {
      return PatternSeverity.moderate;
    }

    // Mild patterns
    return PatternSeverity.mild;
  }

  /// Check if immediate intervention is needed based on text
  bool requiresImmediateIntervention(String text) {
    final result = analyze(text);
    return result.requiresImmediateIntervention;
  }

  /// Get quick safety check questions
  List<String> getSafetyCheckQuestions() {
    return [
      'Are you thinking about harming yourself right now?',
      'Are you safe where you are?',
      'Do you have a plan to end your life?',
      'Is there someone with you who can help keep you safe?',
    ];
  }

  /// Get immediate actions for crisis
  List<String> getCrisisActions() {
    return [
      'Call Samaritans: 116 123 (24/7, free)',
      'Text SHOUT to 85258 (crisis text line)',
      'Call NHS 111 for mental health crisis',
      'Call 999 if in immediate danger',
      'Go to A&E if you cannot keep yourself safe',
      'Call someone you trust to stay with you',
      'Use your safety plan if you have one',
      'Remove any means of self-harm from your environment',
    ];
  }
}
