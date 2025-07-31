import 'package:flipcard/helpers/logger.dart';
import 'package:flipcard/models/deck.dart';
import 'package:flipcard/models/quiz_result.dart';
import 'package:flipcard/models/quiz_stats.dart';
import 'package:flipcard/models/user.dart';
import 'package:flipcard/services/deck_service.dart';
import 'package:flipcard/services/quiz_result_service.dart';
import 'package:flipcard/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class UserStore extends ChangeNotifier {
  User? _user;
  List<Deck> _decks = [];
  List<QuizResult> _quiz = [];

  bool _isLogged = false;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  List<Deck> get decks => _decks;
  List<QuizResult> get quiz => _quiz;

  bool get isLogged => _isLogged;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// recent quiz (last 10)
  List<QuizResult> get recent => _quiz.take(10).toList();

  /// quiz statistics
  QuizStats? get stats {
    if (_quiz.isEmpty) return null;

    final total = _quiz.length;
    final correct = _quiz.fold(0, (sum, result) => sum + result.correctAnswers);
    final questions = _quiz.fold(0, (sum, result) => sum + result.totalCards);

    final average = _quiz.fold(0.0, (x, y) => x + y.accuracyPercentage) / total;
    final timeSpent = _quiz.fold(0, (x, y) => x + y.timeSpentSeconds);
    final scores = _quiz.where((result) => result.isPerfectScore).length;

    return QuizStats(
      total: total,
      correct: correct,
      questions: questions,
      average: average,
      timeSpent: timeSpent,
      scores: scores,
      recent: _quiz.take(5).toList(),
    );
  }

  Future<void> getData() async {
    if (!UserService.isAuthenticated) {
      _user = null;
      _decks = [];
      _isLogged = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await UserService.getById();
      final decks = await DeckService.getByUserId();

      Logger.log(user.toString(), name: "UserStore");

      if (user != null) {
        final quiz = await QuizResultService.getByUserId(user.userId);
        _quiz = quiz;
      }

      _user = user;
      _decks = decks;
      _isLogged = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to load data: ${e.toString()}';
      Logger.log('Error loading data: $e', name: "USER_STORE");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      updateWidget();
    }
  }

  updateUser(User? updated) {
    if (updated == null || !UserService.isAuthenticated) {
      _error = 'Invalid user data or not authenticated';
      notifyListeners();
      return;
    }

    _user = updated;
    _isLogged = true;
    _error = null;

    notifyListeners();
  }

  Future<void> updateUserStats() async {
    if (_user == null || !UserService.isAuthenticated) return;

    try {
      final totalDecks = _decks.length;
      final totalCards = _decks.fold(0, (sum, deck) => sum + deck.cards.length);

      // Update local user object
      _user!.totalDecks = totalDecks;
      _user!.totalCards = totalCards;

      // Update in database
      await UserService.updateStats(
        totalDecks: totalDecks,
        totalCards: totalCards,
      );

      _log('decks: $totalDecks, cards: $totalCards');

      _error = null;
    } catch (e) {
      _error = 'Failed to update user stats: ${e.toString()}';
      _log('Error updating user stats: $e');
    }
  }

  Future<void> updateDecks(List<Deck> updated) async {
    if (!UserService.isAuthenticated) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    try {
      _decks = updated;
      await DeckService.saveMany(_decks);
      await updateUserStats();
      _error = null;
    } catch (e) {
      _error = 'Failed to update decks: ${e.toString()}';
      _log('Error updating decks: $e');
    }

    notifyListeners();
  }

  void updateWidget() async {
    try {
      await HomeWidget.saveWidgetData<int>('total_quiz', quiz.length);
      await HomeWidget.saveWidgetData<String>(
        'accuracy',
        "${stats?.average.toStringAsFixed(1) ?? 0}%",
      );
      await HomeWidget.saveWidgetData<int>('current_streak', currentStreak());
      await HomeWidget.updateWidget(
        name: 'StatsWidgetProvider',
        androidName: 'StatsWidgetProvider',
        // iOSName: 'StatsWidget', // coming soon
      );
    } catch (e) {
      _log('Failed update widget');
    }
  }

  Future<void> addDeck(Deck deck) async {
    if (!UserService.isAuthenticated) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    try {
      await DeckService.save(deck);

      final index = _decks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        _decks[index] = deck;
      } else {
        _decks.add(deck);
      }

      await updateUserStats();
      _error = null;
    } catch (e) {
      _error = 'Failed to add deck: ${e.toString()}';
      _log('Error adding deck: $e');
    }

    notifyListeners();
  }

  Future<void> deleteDeck(String deckId) async {
    if (!UserService.isAuthenticated) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    try {
      await DeckService.deleteById(deckId);
      _decks.removeWhere((deck) => deck.id == deckId);
      await updateUserStats();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete deck: ${e.toString()}';
      _log('Error deleting deck: $e');
    }

    notifyListeners();
  }

  void addQuiz(QuizResult value) {
    quiz.insert(0, value);
    notifyListeners();
    updateWidget();
  }

  void reset() {
    _isLoading = false;
    _error = null;
    _user = null;
    _decks = [];
    _isLogged = false;
    _quiz = [];
    notifyListeners();
  }

  int currentStreak() {
    if (quiz.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    // Get unique quiz dates (only date part, not time)
    final quizDates =
        quiz
            .map((quiz) {
              final date = quiz.completedAt;
              return DateTime(date.year, date.month, date.day);
            })
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // Sort in descending order

    if (quizDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = today;

    // Check if there's a quiz today, if not check yesterday
    if (!quizDates.contains(today)) {
      if (!quizDates.contains(yesterday)) {
        return 0;
      }
      checkDate = yesterday;
    }

    // Count consecutive days
    for (final date in quizDates) {
      if (date == checkDate) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }

    return streak;
  }

  int longestStreak() {
    if (quiz.isEmpty) return 0;

    // Get unique quiz dates
    final quizDates =
        quiz
            .map((quiz) {
              final date = quiz.completedAt;
              return DateTime(date.year, date.month, date.day);
            })
            .toSet()
            .toList()
          ..sort();

    if (quizDates.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < quizDates.length; i++) {
      final previousDate = quizDates[i - 1];
      final currentDate = quizDates[i];
      final dayDifference = currentDate.difference(previousDate).inDays;

      if (dayDifference == 1) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak
            ? currentStreak
            : longestStreak;
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  void _log(String message) {
    Logger.log(message, name: "USER_STORE");
  }
}
