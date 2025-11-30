class User {
  final String id;
  final String name;
  final String email;
  final String password; // Añadido para autenticación
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.username,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'username': username,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Crear desde JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Copiar con cambios
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? username,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}