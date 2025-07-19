import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flipcard/models/flashcard.dart';

class QuizService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const String _quizStateKey = 'quiz_state';

  static Future<void> saveQuizState({
    required String deckId,
    required String deckName,
    required List<FlashCard> shuffledCards,
    required int currentIndex,
    required int correctAnswers,
  }) async {
    try {
      final quizState = {
        'deckId': deckId,
        'deckName': deckName,
        'shuffledCards': shuffledCards
            .map(
              (card) => {
                'id': card.id,
                'deckId': card.deckId,
                'front': card.front,
                'back': card.back,
                'description': card.description,
              },
            )
            .toList(),
        'currentIndex': currentIndex,
        'correctAnswers': correctAnswers,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _storage.write(key: _quizStateKey, value: jsonEncode(quizState));
    } catch (e) {
      // Silently handle storage errors
      log('Error saving quiz state: $e', name: "QuizService");
    }
  }

  static Future<Map<String, dynamic>?> getQuizState() async {
    try {
      final stateString = await _storage.read(key: _quizStateKey);
      if (stateString != null && stateString.isNotEmpty) {
        final decoded = jsonDecode(stateString) as Map<String, dynamic>;

        // Validate that required fields exist
        if (decoded.containsKey('deckId') &&
            decoded.containsKey('shuffledCards') &&
            decoded.containsKey('currentIndex')) {
          return decoded;
        }
      }
    } catch (e) {
      log('Error reading quiz state: $e', name: "QuizService");
      // If there's an error reading the state, clear it
      await clearQuizState();
    }
    return null;
  }

  static Future<void> clearQuizState() async {
    try {
      await _storage.delete(key: _quizStateKey);
    } catch (e) {
      log('Error clearing quiz state: $e', name: "QuizService");
    }
  }

  static Future<bool> hasQuizState() async {
    final state = await getQuizState();
    return state != null &&
        state.containsKey('shuffledCards') &&
        (state['shuffledCards'] as List).isNotEmpty;
  }

  static List<FlashCard> parseFlashCards(List<dynamic> cardsData) {
    return cardsData
        .map((cardData) {
          if (cardData is Map<String, dynamic>) {
            return FlashCard(
              id: cardData['id'] as String? ?? '',
              deckId: cardData['deckId'] as String? ?? '',
              front: cardData['front'] as String? ?? '',
              back: cardData['back'] as String? ?? '',
              description: cardData['description'] as String? ?? '',
            );
          }
          // Fallback for invalid data
          return FlashCard(id: '', deckId: '', front: '', back: '');
        })
        .where((card) => card.front.isNotEmpty || card.back.isNotEmpty)
        .toList();
  }
}
