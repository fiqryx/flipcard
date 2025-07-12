import 'dart:developer';

import 'package:flipcard/models/deck.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeckService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Load decks for the current authenticated user with their cards
  static Future<List<Deck>> getByUserId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Load decks with their cards using a join
      final response = await _supabase
          .from('decks')
          .select('''*, cards (*)''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response.map((deck) {
        // Convert cards array to the format expected by Deck.fromJson
        final cards =
            ((deck['cards'] as List?)?.map((card) {
                    return {
                      'id': card['id'] as String,
                      'deck_id': card['deck_id'] as String,
                      'front': card['front'] as String,
                      'back': card['back'] as String,
                      'description': card['description'] as String?,
                      'created_at': card['created_at'] as String,
                      'updated_at': card['updated_at'] as String,
                      '_parsed_created_at': DateTime.parse(
                        card['created_at'] as String, // Parse for sorting
                      ),
                    };
                  }).toList() ??
                  [])
              ..sort(
                (a, b) => (a['_parsed_created_at'] as DateTime).compareTo(
                  b['_parsed_created_at'] as DateTime,
                ),
              );

        // Create deck data with cards
        final deckJson = {
          'id': deck['id'] as String,
          'name': deck['name'] as String,
          'description': deck['description'] as String? ?? '',
          'front_language': deck['front_language'],
          'back_language': deck['back_language'],
          'created_at': deck['created_at'] as String,
          'updated_at': deck['updated_at'] as String,
          'cards': cards,
        };

        return Deck.fromJson(deckJson);
      }).toList();
    } catch (e) {
      log('Error loading decks: $e', name: "DeckService");
      return [];
    }
  }

  // Get a single deck with card by ID
  static Future<Deck?> getWithCardById(String deckId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('decks')
          .select('''*, cards (id,front,back)''')
          .eq('user_id', user.id)
          .eq('id', deckId)
          .single();

      // Convert cards array to the format expected by Deck.fromJson
      final cards =
          (response['cards'] as List?)
              ?.map(
                (card) => {
                  'id': card['id'],
                  'front': card['front'],
                  'back': card['back'],
                  'description': card['description'],
                },
              )
              .toList() ??
          [];

      // Create deck data with cards
      final Map<String, dynamic> deckJson = Map.from(response);
      deckJson.remove('cards'); // Remove the joined cards
      deckJson['cards'] = cards; // Add cards in the expected format

      return Deck.fromJson(deckJson);
    } catch (e) {
      log('Error loading deck: $e', name: "DeckService");
      return null;
    }
  }

  // Save multiple decks
  static Future<void> saveMany(List<Deck> decks) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      for (final deck in decks) {
        save(deck);
      }
    } catch (e) {
      log('Error saving decks: $e', name: "DeckService");
      throw Exception('Failed to save decks');
    }
  }

  // Save a single deck with its cards
  static Future<void> save(Deck deck) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Prepare deck data without cards
      final deckJson = deck.toJson();
      final cards = deckJson.remove('cards') as List<dynamic>? ?? [];

      // Add user_id to deck data
      deckJson['user_id'] = user.id;
      deckJson['updated_at'] = DateTime.now().toIso8601String();

      // Upsert the deck
      await _supabase.from('decks').upsert(deckJson, onConflict: 'id');

      // Delete existing cards for this deck
      await _supabase.from('cards').delete().eq('deck_id', deck.id);

      // Insert new cards if any exist
      if (cards.isNotEmpty) {
        final cardsData = cards
            .map(
              (card) => {
                'id': card['id'],
                'deck_id': deck.id,
                'front': card['front'],
                'back': card['back'],
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
            )
            .toList();

        await _supabase.from('cards').insert(cardsData);
      }
    } catch (e) {
      log('Error saving deck: $e', name: "DeckService");
      throw Exception('Failed to save deck');
    }
  }

  // Create a new deck
  static Future<Deck> create({
    required String name,
    String? description,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final deckData = {
        'name': name,
        'description': description,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('decks')
          .insert(deckData)
          .select()
          .single();

      return Deck.fromJson(response);
    } catch (e) {
      log('Error creating deck: $e', name: "DeckService");
      throw Exception('Failed to create deck');
    }
  }

  // Update deck
  static Future<void> update(Deck deck) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (deck.name.isNotEmpty) updates['title'] = deck.name;
      if (deck.description.isNotEmpty) {
        updates['description'] = deck.description;
      }

      await _supabase
          .from('decks')
          .update(updates)
          .eq('id', deck.id)
          .eq('user_id', user.id);
    } catch (e) {
      log('Error updating deck metadata: $e', name: "DeckService");
      throw Exception('Failed to update deck');
    }
  }

  // Delete a deck and its cards
  static Future<void> deleteById(String deckId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Delete cards first (foreign key constraint)
      await _supabase.from('cards').delete().eq('deck_id', deckId);

      // Then delete the deck
      await _supabase
          .from('decks')
          .delete()
          .eq('id', deckId)
          .eq('user_id', user.id);
    } catch (e) {
      log('Error deleting deck: $e', name: "DeckService");
      throw Exception('Failed to delete deck');
    }
  }

  // Get deck count for current user
  static Future<int> countByUserId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('decks')
          .select('id')
          .eq('user_id', user.id)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      log('Error getting deck count: $e', name: "DeckService");
      return 0;
    }
  }
}
