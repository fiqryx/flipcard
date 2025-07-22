import 'dart:developer' as dev;
import 'package:flipcard/models/quiz_result.dart';
import 'package:flipcard/models/quiz_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizResultService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'quiz_results';

  /// Save a quiz result to the database
  static Future<QuizResult> save(QuizResult quizResult) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert(quizResult.toJson())
          .select()
          .single();

      dev.log('Quiz result saved successfully', name: 'QUIZ_RESULT_SERVICE');
      return QuizResult.fromJson(response);
    } catch (e) {
      dev.log('Error saving quiz result: $e', name: 'QUIZ_RESULT_SERVICE');
      rethrow;
    }
  }

  /// get all quiz results for a user
  static Future<List<QuizResult>> getByUserId(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      final results = (response as List)
          .map((json) => QuizResult.fromJson(json))
          .toList();

      dev.log(
        'Loaded ${results.length} quiz results for user',
        name: 'QUIZ_RESULT_SERVICE',
      );
      return results;
    } catch (e) {
      dev.log('Error loading quiz results: $e', name: 'QUIZ_RESULT_SERVICE');
      rethrow;
    }
  }

  /// Load quiz results for a specific deck
  static Future<List<QuizResult>> getByDeckId(String deckId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('deck_id', deckId)
          .order('completed_at', ascending: false);

      final results = (response as List)
          .map((json) => QuizResult.fromJson(json))
          .toList();

      dev.log(
        'Loaded ${results.length} quiz results for deck',
        name: 'QUIZ_RESULT_SERVICE',
      );
      return results;
    } catch (e) {
      dev.log(
        'Error loading deck quiz results: $e',
        name: 'QUIZ_RESULT_SERVICE',
      );
      rethrow;
    }
  }

  /// Get last quiz
  static Future<QuizResult?> getLastQuizByUserId(String userId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      return response.isNotEmpty ? QuizResult.fromJson(response[0]) : null;
    } catch (e) {
      dev.log('Error loading quiz results: $e', name: 'QUIZ_RESULT_SERVICE');
      rethrow;
    }
  }

  /// Get quiz statistics for a user
  static Future<QuizStats> getQuizStatByUserId(String userId) async {
    try {
      final results = await getByUserId(userId);

      if (results.isEmpty) {
        return QuizStats.empty();
      }

      final totalQuizzes = results.length;
      final totalCorrect = results.fold(
        0,
        (sum, result) => sum + result.correctAnswers,
      );
      final totalQuestions = results.fold(
        0,
        (sum, result) => sum + result.totalCards,
      );
      final averageAccuracy =
          results.fold(0.0, (sum, result) => sum + result.accuracyPercentage) /
          totalQuizzes;
      final totalTimeSpent = results.fold(
        0,
        (sum, result) => sum + result.timeSpentSeconds,
      );
      final perfectScores = results
          .where((result) => result.isPerfectScore)
          .length;

      return QuizStats(
        total: totalQuizzes,
        correct: totalCorrect,
        questions: totalQuestions,
        average: averageAccuracy,
        timeSpent: totalTimeSpent,
        scores: perfectScores,
        recent: results.take(5).toList(),
      );
    } catch (e) {
      dev.log('Error getting quiz stats: $e', name: 'QUIZ_RESULT_SERVICE');
      rethrow;
    }
  }

  /// Get quiz statistics for a deck
  static Future<DeckQuizStats> getkQuizStatByDeckId(String deckId) async {
    try {
      final results = await getByDeckId(deckId);

      if (results.isEmpty) {
        return DeckQuizStats.empty();
      }

      final totalAttempts = results.length;
      final averageAccuracy =
          results.fold(0.0, (sum, result) => sum + result.accuracyPercentage) /
          totalAttempts;
      final bestScore = results
          .map((r) => r.correctAnswers)
          .reduce((a, b) => a > b ? a : b);
      final worstScore = results
          .map((r) => r.correctAnswers)
          .reduce((a, b) => a < b ? a : b);
      final averageTime =
          results.fold(0, (sum, result) => sum + result.timeSpentSeconds) /
          totalAttempts;

      return DeckQuizStats(
        totalAttempts: totalAttempts,
        averageAccuracy: averageAccuracy,
        bestScore: bestScore,
        worstScore: worstScore,
        averageTime: averageTime.round(),
        recentResults: results.take(5).toList(),
      );
    } catch (e) {
      dev.log('Error getting deck quiz stats: $e', name: 'QUIZ_RESULT_SERVICE');
      rethrow;
    }
  }

  /// Delete a quiz result
  static Future<void> deleteById(String quizResultId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', quizResultId);

      dev.log('Quiz result deleted successfully', name: 'QUIZ_RESULT_SERVICE');
    } catch (e) {
      dev.log('Error deleting quiz result: $e', name: 'QUIZ_RESULT_SERVICE');
      rethrow;
    }
  }

  /// Delete all quiz results for a user
  static Future<void> deleteByUserId(String userId) async {
    try {
      await _supabase.from(_tableName).delete().eq('user_id', userId);

      dev.log('All quiz results deleted for user', name: 'QUIZ_RESULT_SERVICE');
    } catch (e) {
      dev.log(
        'Error deleting user quiz results: $e',
        name: 'QUIZ_RESULT_SERVICE',
      );
      rethrow;
    }
  }
}
