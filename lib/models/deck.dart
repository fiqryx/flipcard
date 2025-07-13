import 'dart:ui';

import 'package:uuid/uuid.dart';
import 'package:flipcard/models/flashcard.dart';

class Deck {
  String id;
  String name;
  String description;
  List<FlashCard> cards;
  Locale frontLanguage;
  Locale backLanguage;
  bool shuffle;
  DateTime createdAt;
  DateTime updatedAt;

  Deck({
    String? id,
    required this.name,
    this.description = '',
    required this.cards,
    this.frontLanguage = const Locale('en', 'US'),
    this.backLanguage = const Locale('en', 'US'),
    this.shuffle = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'cards': cards.map((card) => card.toJson()).toList(),
    'front_language':
        '${frontLanguage.languageCode}-${frontLanguage.countryCode}',
    'back_language': '${backLanguage.languageCode}-${backLanguage.countryCode}',
    'shuffle': shuffle,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Deck.fromJson(Map<String, dynamic> json) {
    parseLocale(String localeString) {
      final parts = localeString.split('-');
      return Locale(parts[0], parts.length > 1 ? parts[1] : null);
    }

    return Deck(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      cards: (json['cards'] as List)
          .map((card) => FlashCard.fromJson(card as Map<String, dynamic>))
          .toList(),
      frontLanguage: parseLocale(json['front_language'] as String? ?? 'en-US'),
      backLanguage: parseLocale(json['back_language'] as String? ?? 'en-US'),
      shuffle: json['shuffle'] ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    List<FlashCard>? cards,
    Locale? frontLanguage,
    Locale? backLanguage,
    bool? shuffle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cards: cards ?? this.cards,
      frontLanguage: frontLanguage ?? this.frontLanguage,
      backLanguage: backLanguage ?? this.backLanguage,
      shuffle: shuffle ?? this.shuffle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return "Deck(id: $id, name: $name, description: $description, cards: ${cards.length}, frontLanguage: $frontLanguage, backLanguage: $backLanguage, shuffle: $shuffle, createdAt: ${createdAt.toIso8601String()}, updatedAt: ${updatedAt.toIso8601String()})";
  }
}
