import 'package:uuid/uuid.dart';

class QuizResult {
  String id;
  String userId;
  String deckId;
  String deckName;
  int totalCards;
  int correctAnswers;
  int incorrectAnswers;
  int skippedAnswers;
  double accuracyPercentage;
  int timeSpentSeconds;
  DateTime completedAt;
  DateTime createdAt;
  DateTime updatedAt;

  QuizResult({
    String? id,
    required this.userId,
    required this.deckId,
    required this.deckName,
    required this.totalCards,
    required this.correctAnswers,
    required this.incorrectAnswers,
    this.skippedAnswers = 0,
    required this.timeSpentSeconds,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       completedAt = completedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       accuracyPercentage = totalCards > 0
           ? (correctAnswers / totalCards) * 100
           : 0;

  // Getters for calculated fields
  int get totalAttempted => correctAnswers + incorrectAnswers;
  double get completionPercentage =>
      totalCards > 0 ? (totalAttempted / totalCards) * 100 : 0;
  bool get isPerfectScore =>
      correctAnswers == totalCards && incorrectAnswers == 0;
  String get formattedDuration => _formatDuration(timeSpentSeconds);

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'deck_id': deckId,
    'deck_name': deckName,
    'total_cards': totalCards,
    'correct_answers': correctAnswers,
    'incorrect_answers': incorrectAnswers,
    'skipped_answers': skippedAnswers,
    'accuracy_percentage': accuracyPercentage,
    'time_spent_seconds': timeSpentSeconds,
    'completed_at': completedAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    deckId: json['deck_id'] as String,
    deckName: json['deck_name'] as String,
    totalCards: json['total_cards'] as int,
    correctAnswers: json['correct_answers'] as int,
    incorrectAnswers: json['incorrect_answers'] as int,
    skippedAnswers: json['skipped_answers'] as int? ?? 0,
    timeSpentSeconds: json['time_spent_seconds'] as int,
    completedAt: DateTime.parse(json['completed_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  QuizResult copyWith({
    String? id,
    String? userId,
    String? deckId,
    String? deckName,
    int? totalCards,
    int? correctAnswers,
    int? incorrectAnswers,
    int? skippedAnswers,
    int? timeSpentSeconds,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deckId: deckId ?? this.deckId,
      deckName: deckName ?? this.deckName,
      totalCards: totalCards ?? this.totalCards,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      skippedAnswers: skippedAnswers ?? this.skippedAnswers,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  @override
  String toString() {
    return 'QuizResult(id: $id, deckName: $deckName, score: $correctAnswers/$totalCards, accuracy: ${accuracyPercentage.toStringAsFixed(1)}%)';
  }
}
