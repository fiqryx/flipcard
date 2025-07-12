import 'dart:developer';
import 'package:flipcard/models/flashcard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CardService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // get a single card by ID
  static Future<FlashCard?> getById(String cardId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('cards')
          .select('*')
          .eq('id', cardId)
          .single();

      return FlashCard.fromJson(response);
    } catch (e) {
      log('Error loading card: $e', name: "CardService");
      return null;
    }
  }

  // Load all cards for a specific deck
  static Future<List<FlashCard>> getByDeckId(String deckId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('cards')
          .select('*')
          .eq('deck_id', deckId)
          .order('created_at', ascending: true);

      return response.map((cardData) => FlashCard.fromJson(cardData)).toList();
    } catch (e) {
      log('Error loading cards for deck: $e', name: "CardService");
      return [];
    }
  }

  // Create a new card and add it to a deck
  static Future<FlashCard> create(FlashCard card) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = {
        // 'id': card.id,
        'deck_id': card.deckId,
        'front': card.front,
        'back': card.back,
        'description': card.description,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('cards')
          .insert(data)
          .select()
          .single();

      return FlashCard.fromJson(response);
    } catch (e) {
      log('Error creating card: $e', name: "CardService");
      throw Exception('Failed to create card');
    }
  }

  // Bulk create cards to a deck
  static Future<List<FlashCard>> createMany(
    String deckId,
    List<FlashCard> cards,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (cards.isEmpty) return [];

      final cardsData = cards
          .map(
            (card) => {
              // 'id': card.id,
              'deck_id': deckId,
              'front': card.front,
              'back': card.back,
              'description': card.description,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      final response = await _supabase.from('cards').insert(cardsData).select();

      return response.map((cardData) => FlashCard.fromJson(cardData)).toList();
    } catch (e) {
      log('Error bulk adding cards: $e', name: "CardService");
      throw Exception('Failed to add cards to deck');
    }
  }

  // Update a card
  static Future<void> update(FlashCard card) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('cards')
          .update({
            'front': card.front,
            'back': card.back,
            'description': card.description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', card.id);
    } catch (e) {
      log('Error updating card: $e', name: "CardService");
      throw Exception('Failed to update card');
    }
  }

  // Delete a card
  static Future<void> deleteById(String cardId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('cards').delete().eq('id', cardId);
    } catch (e) {
      log('Error deleting card: $e', name: "CardService");
      throw Exception('Failed to delete card');
    }
  }

  // Delete all cards for a deck
  static Future<void> deleyeByDeckId(String deckId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('cards').delete().eq('deck_id', deckId);
    } catch (e) {
      log('Error deleting cards for deck: $e', name: "CardService");
      throw Exception('Failed to delete cards');
    }
  }

  // Get card count for a specific deck
  static Future<int> countByDeckId(String deckId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('cards')
          .select('id')
          .eq('deck_id', deckId)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      log('Error getting card count: $e', name: "CardService");
      return 0;
    }
  }

  // Get total card count for current user
  static Future<int> countByUserId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get all deck IDs for the user first
      final deckResponse = await _supabase
          .from('decks')
          .select('id')
          .eq('user_id', user.id);

      if (deckResponse.isEmpty) return 0;

      final deckIds = deckResponse.map((deck) => deck['id']).toList();

      final cardResponse = await _supabase
          .from('cards')
          .select('id')
          .inFilter('deck_id', deckIds)
          .count(CountOption.exact);

      return cardResponse.count;
    } catch (e) {
      log('Error getting total card count: $e', name: "CardService");
      return 0;
    }
  }
}
