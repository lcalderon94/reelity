class Comment {
  final String id;
  final String episodeId;
  final String userId;
  final String username;
  final String userAvatarUrl;
  final String text;
  final DateTime createdAt;
  final int likes;
  final bool isLiked;

  Comment({
    required this.id,
    required this.episodeId,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
  });

  // Tiempo formateado (ej: "Hace 1h", "Hace 30min")
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}min';
    } else {
      return 'Ahora';
    }
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'episodeId': episodeId,
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
      'isLiked': isLiked,
    };
  }

  // Crear desde JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      episodeId: json['episodeId'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: json['likes'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }

  // Copiar con cambios
  Comment copyWith({
    String? id,
    String? episodeId,
    String? userId,
    String? username,
    String? userAvatarUrl,
    String? text,
    DateTime? createdAt,
    int? likes,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
