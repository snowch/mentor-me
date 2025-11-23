import '../models/clinical_assessment.dart';

/// Service for clinical assessment scoring and interpretation
///
/// Implements evidence-based scoring algorithms for:
/// - PHQ-9 (Patient Health Questionnaire for Depression)
/// - GAD-7 (Generalized Anxiety Disorder scale)
/// - PSS-10 (Perceived Stress Scale)
///
/// Based on validated clinical instruments used in NHS and IAPT services.
class AssessmentService {
  static final AssessmentService _instance = AssessmentService._internal();
  factory AssessmentService() => _instance;
  AssessmentService._internal();

  /// Calculate total score from responses
  int calculateScore(AssessmentType type, Map<int, int> responses) {
    if (type == AssessmentType.pss10) {
      // PSS-10 has reverse-scored items (questions 4, 5, 7, 8)
      return _calculatePSS10Score(responses);
    }

    // PHQ-9 and GAD-7 use simple summation
    return responses.values.fold(0, (sum, score) => sum + score);
  }

  /// Calculate PSS-10 score with reverse scoring
  int _calculatePSS10Score(Map<int, int> responses) {
    final reverseItems = {4, 5, 7, 8};
    int total = 0;

    for (final entry in responses.entries) {
      final questionNum = entry.key;
      final score = entry.value;

      if (reverseItems.contains(questionNum)) {
        // Reverse score: 0→4, 1→3, 2→2, 3→1, 4→0
        total += 4 - score;
      } else {
        total += score;
      }
    }

    return total;
  }

  /// Determine severity level from score
  SeverityLevel determineSeverity(AssessmentType type, int score) {
    switch (type) {
      case AssessmentType.phq9:
        return _determinePHQ9Severity(score);
      case AssessmentType.gad7:
        return _determineGAD7Severity(score);
      case AssessmentType.pss10:
        return _determinePSS10Severity(score);
    }
  }

  SeverityLevel _determinePHQ9Severity(int score) {
    if (score <= 4) return SeverityLevel.none;
    if (score <= 9) return SeverityLevel.mild;
    if (score <= 14) return SeverityLevel.moderate;
    if (score <= 19) return SeverityLevel.moderatelySevere;
    return SeverityLevel.severe;
  }

  SeverityLevel _determineGAD7Severity(int score) {
    if (score <= 4) return SeverityLevel.minimal;
    if (score <= 9) return SeverityLevel.mild;
    if (score <= 14) return SeverityLevel.moderate;
    return SeverityLevel.severe;
  }

  SeverityLevel _determinePSS10Severity(int score) {
    // PSS-10 doesn't have official cutoffs, using research-based ranges
    if (score <= 13) return SeverityLevel.minimal;
    if (score <= 19) return SeverityLevel.mild;
    if (score <= 26) return SeverityLevel.moderate;
    return SeverityLevel.severe;
  }

  /// Generate interpretation text
  String generateInterpretation(AssessmentType type, SeverityLevel severity, int score) {
    final maxScore = type.maxScore;

    switch (type) {
      case AssessmentType.phq9:
        return _generatePHQ9Interpretation(severity, score);
      case AssessmentType.gad7:
        return _generateGAD7Interpretation(severity, score);
      case AssessmentType.pss10:
        return _generatePSS10Interpretation(severity, score, maxScore);
    }
  }

  String _generatePHQ9Interpretation(SeverityLevel severity, int score) {
    switch (severity) {
      case SeverityLevel.none:
        return 'Your score suggests minimal or no depression symptoms. '
            'Continue with your self-care practices.';
      case SeverityLevel.mild:
        return 'Your score suggests mild depression. '
            'Self-help strategies and monitoring your mood can be helpful. '
            'If symptoms persist, consider speaking to your GP.';
      case SeverityLevel.moderate:
        return 'Your score suggests moderate depression. '
            'We recommend speaking to your GP about treatment options, '
            'which may include talking therapy or medication.';
      case SeverityLevel.moderatelySevere:
        return 'Your score suggests moderately severe depression. '
            'Please contact your GP soon to discuss treatment options. '
            'You may benefit from therapy or medication.';
      case SeverityLevel.severe:
        return 'Your score suggests severe depression. '
            'Please contact your GP urgently or call NHS 111 for support. '
            'Effective treatments are available.';
      default:
        return 'Score: $score/27';
    }
  }

  String _generateGAD7Interpretation(SeverityLevel severity, int score) {
    switch (severity) {
      case SeverityLevel.minimal:
        return 'Your score suggests minimal anxiety. '
            'Your anxiety levels appear to be within a normal range.';
      case SeverityLevel.mild:
        return 'Your score suggests mild anxiety. '
            'Self-help strategies like relaxation techniques and regular exercise may help. '
            'Monitor your symptoms.';
      case SeverityLevel.moderate:
        return 'Your score suggests moderate anxiety. '
            'Consider speaking to your GP about support options, '
            'such as talking therapy or self-help groups.';
      case SeverityLevel.severe:
        return 'Your score suggests severe anxiety. '
            'Please contact your GP to discuss treatment options. '
            'Effective therapies like CBT are available.';
      default:
        return 'Score: $score/21';
    }
  }

  String _generatePSS10Interpretation(SeverityLevel severity, int score, int maxScore) {
    switch (severity) {
      case SeverityLevel.minimal:
        return 'Your stress levels appear to be within a manageable range. '
            'Continue with your current coping strategies.';
      case SeverityLevel.mild:
        return 'You\'re experiencing mild stress. '
            'Regular self-care, exercise, and relaxation techniques can help. '
            'Consider what might be contributing to stress.';
      case SeverityLevel.moderate:
        return 'You\'re experiencing moderate stress levels. '
            'Try stress-management techniques like mindfulness, exercise, or talking to someone you trust. '
            'If stress persists, consider professional support.';
      case SeverityLevel.severe:
        return 'You\'re experiencing high stress levels. '
            'This level of stress can affect your health and wellbeing. '
            'Consider speaking to your GP or a counsellor about stress management.';
      default:
        return 'Score: $score/$maxScore';
    }
  }

  /// Check if assessment should trigger crisis protocol
  bool shouldTriggerCrisis(AssessmentType type, Map<int, int> responses, int totalScore) {
    if (type == AssessmentType.phq9) {
      // PHQ-9 Question 9 asks about suicidal thoughts/self-harm
      // Scoring: 0=Not at all, 1=Several days, 2=More than half the days, 3=Nearly every day
      final question9Score = responses[9] ?? 0;

      // Trigger crisis protocol if:
      // - Question 9 score > 0 (any suicidal ideation) AND total score >= 15 (moderately severe+)
      // - OR Question 9 score >= 2 (frequent suicidal thoughts) regardless of total score
      if (question9Score >= 2) return true;
      if (question9Score > 0 && totalScore >= 15) return true;
    }

    if (type == AssessmentType.gad7 && totalScore >= 15) {
      // Severe anxiety warrants safety check
      return true;
    }

    return false;
  }

  /// Get recommendation based on severity
  String getRecommendation(AssessmentType type, SeverityLevel severity) {
    if (severity == SeverityLevel.severe || severity == SeverityLevel.moderatelySevere) {
      return 'Contact your GP or call NHS 111';
    }

    if (severity == SeverityLevel.moderate) {
      return 'Consider speaking to your GP';
    }

    if (severity == SeverityLevel.mild) {
      return 'Monitor symptoms, use self-help strategies';
    }

    return 'Continue current practices';
  }
}
