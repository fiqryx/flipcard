import 'package:flipcard/models/quiz_result.dart';

/// Statistics for user quiz performance
class QuizStats {
  final int total;
  final int correct;
  final int questions;
  final double average;
  final int timeSpent;
  final int scores;
  final List<QuizResult> recent;

  QuizStats({
    required this.total,
    required this.correct,
    required this.questions,
    required this.average,
    required this.timeSpent,
    required this.scores,
    required this.recent,
  });

  factory QuizStats.empty() => QuizStats(
    total: 0,
    correct: 0,
    questions: 0,
    average: 0.0,
    timeSpent: 0,
    scores: 0,
    recent: [],
  );

  double get accuracy => questions > 0 ? (correct / questions) * 100 : 0;
  double get scoreRate => total > 0 ? (scores / total) * 100 : 0;
}

/// Statistics for deck quiz performance
class DeckQuizStats {
  final int totalAttempts;
  final double averageAccuracy;
  final int bestScore;
  final int worstScore;
  final int averageTime;
  final List<QuizResult> recentResults;

  DeckQuizStats({
    required this.totalAttempts,
    required this.averageAccuracy,
    required this.bestScore,
    required this.worstScore,
    required this.averageTime,
    required this.recentResults,
  });

  factory DeckQuizStats.empty() => DeckQuizStats(
    totalAttempts: 0,
    averageAccuracy: 0.0,
    bestScore: 0,
    worstScore: 0,
    averageTime: 0,
    recentResults: [],
  );
}
