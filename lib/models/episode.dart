class Episode {
  final String id;
  final String seasonId;
  final String userId; // NUEVO: ID del usuario que subió el video
  final int episodeNumber;
  final String title;
  final String? description;
  final String thumbnailUrl;
  final String videoUrl; // URL del video o ID de YouTube
  final int durationSeconds;
  final DateTime uploadedAt;
  final int views;
  final int likes;
  final int commentsCount;

  Episode({
    required this.id,
    required this.seasonId,
    required this.userId, // NUEVO
    required this.episodeNumber,
    required this.title,
    this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.durationSeconds,
    required this.uploadedAt,
    this.views = 0,
    this.likes = 0,
    this.commentsCount = 0,
  });

  // Duración formateada (ej: "0:28")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Fecha formateada (ej: "21 Ene")
  String get formattedDate {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${uploadedAt.day} ${months[uploadedAt.month - 1]}';
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonId': seasonId,
      'userId': userId, // NUEVO
      'episodeNumber': episodeNumber,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'durationSeconds': durationSeconds,
      'uploadedAt': uploadedAt.toIso8601String(),
      'views': views,
      'likes': likes,
      'commentsCount': commentsCount,
    };
  }

  // Crear desde JSON
  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as String,
      seasonId: json['seasonId'] as String,
      userId: json['userId'] as String? ?? 'user_1', // NUEVO con fallback
      episodeNumber: json['episodeNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String,
      videoUrl: json['videoUrl'] as String,
      durationSeconds: json['durationSeconds'] as int,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
    );
  }

  // Copiar con cambios
  Episode copyWith({
    String? id,
    String? seasonId,
    String? userId, // NUEVO
    int? episodeNumber,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? videoUrl,
    int? durationSeconds,
    DateTime? uploadedAt,
    int? views,
    int? likes,
    int? commentsCount,
  }) {
    return Episode(
      id: id ?? this.id,
      seasonId: seasonId ?? this.seasonId,
      userId: userId ?? this.userId, // NUEVO
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}