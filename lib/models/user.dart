class User {
  String id;
  String userId;
  String name;
  String email;
  String? imageUrl;
  String? gender;
  String? phone;
  DateTime? birthDate;
  int totalDecks;
  int totalCards;
  DateTime? createdAt;
  DateTime? updatedAt;

  User({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.imageUrl,
    this.gender,
    this.phone,
    this.birthDate,
    this.totalDecks = 0,
    this.totalCards = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'image_url': imageUrl,
    'gender': gender,
    'phone': phone,
    'birth_date': birthDate?.toIso8601String(),
    'total_decks': totalDecks,
    'total_cards': totalCards,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    userId: json['user_id'],
    name: json['name'],
    email: json['email'],
    imageUrl: json['image_url']?.toString(),
    gender: json['gender'],
    phone: json['phone'],
    birthDate: json['birth_date'] != null
        ? DateTime.tryParse(json['birth_date'].toString())
        : null,
    totalDecks: json['total_decks'] ?? 0,
    totalCards: json['total_cards'] ?? 0,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null,
  );

  User copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? imageUrl,
    String? gender,
    String? phone,
    DateTime? birthDate,
    int? totalDecks,
    int? totalCards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      totalDecks: totalDecks ?? this.totalDecks,
      totalCards: totalCards ?? this.totalCards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, imageUrl: $imageUrl, gender: $gender, phone: $phone, birthDate: $birthDate, totalDecks: $totalDecks, totalCards: $totalCards)';
  }
}
