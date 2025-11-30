class Group {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> memberIds;
  final String ownerId;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.memberIds,
    required this.ownerId,
    required this.createdAt,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'memberIds': memberIds,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Crear desde JSON
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      memberIds: (json['memberIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Copiar con cambios
  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? memberIds,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      memberIds: memberIds ?? this.memberIds,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
