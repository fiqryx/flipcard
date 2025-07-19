import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui';
import 'package:flipcard/models/deck.dart';
import 'package:flipcard/models/flashcard.dart';
import 'package:flipcard/models/user.dart' as model;
import 'package:flipcard/services/deck_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static bool get isAuthenticated => _supabase.auth.currentUser != null;

  static String? get currentUserId => _supabase.auth.currentUser?.id;

  static String? get currentUserEmail => _supabase.auth.currentUser?.email;

  static String? get provider =>
      _supabase.auth.currentUser?.appMetadata['provider'];

  static Future<model.User?> getById() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return null;

      try {
        final response = await _supabase
            .from('user_profiles')
            .select('*')
            .eq('user_id', authUser.id)
            .single();

        return model.User.fromJson(response);
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST116') {
          dev.log(
            'User profile not found, creating new one',
            name: "UserService",
          );
          return await _createWithRetry(authUser);
        }
        throw Exception(
          "We couldn't load your profile. Please try again later.",
        );
      }
    } on SocketException catch (e) {
      dev.log('Network error loading user: $e', name: "UserService");
      throw Exception(
        "Connection failed. Please check your internet connection and try again.",
      );
    } on TimeoutException catch (e) {
      dev.log('Timeout creating profile: $e', name: "UserService");
      throw Exception("Connection timed out. Please try again.");
    } catch (e) {
      dev.log(
        'Unexpected error loading user: ${e.toString()}',
        name: "UserService",
      );
      throw Exception(
        "An unexpected error occurred. Our team has been notified. Please try again later.",
      );
    }
  }

  static Future<void> save(model.User profile) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) throw Exception('User not authenticated');

      // Convert camelCase to snake_case for database
      final data = {
        'user_id': authUser.id,
        'name': profile.name,
        'email': authUser.email,
        'image_url': profile.imageUrl,
        'gender': profile.gender,
        'phone': profile.phone,
        'birth_date': profile.birthDate?.toIso8601String(),
        'total_decks': profile.totalDecks,
        'total_cards': profile.totalCards,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Use upsert with onConflict to specify which column to use for conflict resolution
      await _supabase.from('user_profiles').upsert(data, onConflict: 'user_id');
    } catch (e) {
      dev.log('Error saving user: $e', name: "UserService");
      throw Exception('Failed to save user profile');
    }
  }

  /// return public URL uploaded file
  static Future<String?> uploadImage(
    File imageFile, {
    String? currentImageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bucketId = 'user-profiles';
      final name = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profile_images/$name';

      if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
        final oldFileName = currentImageUrl.split('/').last;
        _supabase.storage.from(bucketId).remove(['profile_images/$oldFileName'])
        // ignore: body_might_complete_normally_catch_error
        .catchError((err, stackTrace) {
          dev.log(
            'Error remove previous profile image',
            name: "UserService",
            error: err,
            stackTrace: stackTrace,
          );
        });
      }

      await _supabase.storage.from(bucketId).upload(path, imageFile);

      return _supabase.storage.from(bucketId).getPublicUrl(path);
    } catch (e) {
      dev.log('Error uploading profile image: $e', name: "UserService");
      throw Exception('Failed to upload profile image');
    }
  }

  static Future<void> updateStats({
    int? totalDecks,
    int? totalCards,
    int? quizzesCompleted,
  }) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (totalDecks != null) updates['total_decks'] = totalDecks;
      if (totalCards != null) updates['total_cards'] = totalCards;

      await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('user_id', authUser.id);
    } catch (e) {
      dev.log('Error updating user stats: $e', name: "UserService");
      throw Exception('Failed to update user statistics');
    }
  }

  static Future<void> clearData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Delete all cards for user's decks first
      await _supabase.rpc('delete_user_cards', params: {'user_uuid': user.id});

      // Delete all user's decks
      await _supabase.from('decks').delete().eq('user_id', user.id);

      // Delete user profile
      await _supabase.from('user_profiles').delete().eq('user_id', user.id);

      // Sign out the user
      await _supabase.auth.signOut();
    } catch (e) {
      dev.log('Error clearing user data: $e', name: "UserService");
      throw Exception('Failed to clear user data');
    }
  }

  static Future<void> signInWithEmail(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on SocketException catch (e) {
      dev.log('Network error: $e', name: "UserService");
      throw Exception(
        "Connection failed. Please check your internet connection and try again.",
      );
    } on AuthApiException catch (e) {
      dev.log('Sign in error: $e', name: "UserService");
      throw Exception(e.message);
    } on AuthException catch (e) {
      dev.log('Sign in error: $e', name: "UserService");
      throw Exception(e.message);
    } on TimeoutException catch (e) {
      dev.log('Sign in timeout: $e', name: "UserService");
      throw Exception("Connection timed out. Please try again.");
    } catch (e) {
      dev.log('Error signing in: $e', name: "UserService");
      throw Exception("An unexpected error occurred. Please try again later");
    }
  }

  static Future<void> signUpWithEmail({
    String? name,
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': name},
        emailRedirectTo: 'com.example.flipcard://email-verify',
      );
    } on SocketException catch (e) {
      dev.log('Network error loading user: $e', name: "UserService");
      throw Exception(
        "Connection failed. Please check your internet connection and try again.",
      );
    } on AuthApiException catch (e) {
      dev.log('Sign in error: $e', name: "UserService");
      throw Exception(e.message);
    } on AuthException catch (e) {
      dev.log('Sign in error: $e', name: "UserService");
      throw Exception(e.message);
    } on TimeoutException catch (e) {
      dev.log('Timeout creating profile: $e', name: "UserService");
      throw Exception("Connection timed out. Please try again.");
    } catch (e) {
      dev.log('Error signing in: $e', name: "UserService");
      throw Exception("An unexpected error occurred. Please try again later");
    }
  }

  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      dev.log('Error signing out: $e', name: "UserService");
      throw Exception('Failed to sign out');
    }
  }

  static Future<model.User?> _create(User authUser) async {
    try {
      final metadata = authUser.userMetadata ?? {};
      final emailPrefix = authUser.email?.split('@').first;

      dev.log(metadata.toString());

      final userData = {
        'user_id': authUser.id,
        'name': metadata['name'] ?? emailPrefix ?? 'User',
        'email': authUser.email,
        'image_url': metadata['avatar_url'],
        'gender': metadata['gender'],
        'phone': metadata['phone'] ?? authUser.phone,
        'birth_date': metadata['birth_date'],
        'total_decks': 0,
        'total_cards': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_profiles')
          .insert(userData)
          .select()
          .single();

      await _initalizeUserDeck();

      return model.User.fromJson(response);
    } catch (e) {
      dev.log('Error creating user profile: $e', name: "UserService");
      rethrow;
    }
  }

  static Future<void> _initalizeUserDeck() async {
    final deck = Deck(
      id: const Uuid().v4(),
      name: 'Getting Started',
      description: 'Your first flashcard deck',
      cards: [],
      frontLanguage: const Locale('en', 'US'),
      backLanguage: const Locale('en', 'US'),
    );

    final cards = [
      FlashCard(
        deckId: deck.id,
        front: 'Welcome to FlipCard!',
        back: 'Start learning by editing these cards',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Tap card to flip',
        back: 'Reveals the back side',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Swipe right if you know it',
        back: 'Marks card as known',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Swipe left to review later',
        back: 'Keeps card in rotation',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Edit cards',
        back: 'Tap the edit button to modify',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Add new decks',
        back: 'Create specialized decks for different topics',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Track progress',
        back: 'See your learning statistics',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Spaced repetition',
        back: 'Cards you struggle with appear more often',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Dark mode',
        back: 'Toggle in settings for night studying',
      ),
      FlashCard(
        deckId: deck.id,
        front: 'Sync across devices',
        back: 'Your progress is saved in the cloud',
      ),
    ];

    deck.cards.addAll(cards);

    await DeckService.saveMany([deck]);
    await UserService.updateStats(totalDecks: 1, totalCards: deck.cards.length);
  }

  static Future<model.User?> _createWithRetry(
    User user, {
    int retry = 3,
  }) async {
    for (int i = 0; i < retry; i++) {
      try {
        return await _create(user);
      } on PostgrestException catch (e) {
        if (e.code == '23503') {
          // Foreign key violation (user not yet in database)
          if (i < retry - 1) {
            await Future.delayed(Duration(seconds: 1 * (i + 1)));
            continue;
          }
        }
        rethrow;
      }
    }
    return null;
  }
}
