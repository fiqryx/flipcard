import 'package:uuid/uuid.dart';

class FlashCard {
  String id;
  String deckId;
  String front;
  String back;
  String? description;
  bool isFlipped;
  DateTime createdAt;
  DateTime updatedAt;

  FlashCard({
    String? id,
    required this.deckId,
    required this.front,
    required this.back,
    this.description,
    this.isFlipped = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'deck_id': deckId,
    'front': front,
    'back': back,
    'description': description,
    'is_flipped': isFlipped,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory FlashCard.fromJson(Map<String, dynamic> json) => FlashCard(
    id: json['id'] as String,
    deckId: json['deck_id'] as String,
    front: json['front'] as String,
    back: json['back'] as String,
    description: json['description'],
    isFlipped: json['is_flipped'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  FlashCard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    String? description,
    bool? isFlipped,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashCard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      description: description ?? this.description,
      isFlipped: isFlipped ?? this.isFlipped,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return "FlashCard(id: $id, deckId: $deckId, front: $front, back: $back, description: $description, isFlipped: ${isFlipped.toString()}, createdAt: ${createdAt.toIso8601String()}, updatedAt: ${updatedAt.toIso8601String()})";
  }
}
