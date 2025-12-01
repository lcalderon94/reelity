import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> memberIds;
  final String ownerId;
  final List<String> tags; // ✅ NUEVO
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.memberIds,
    required this.ownerId,
    required this.tags, // ✅ NUEVO
    required this.createdAt,
  });

  // Convertir a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'memberIds': memberIds,
      'ownerId': ownerId,
      'tags': tags, // ✅ NUEVO
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Crear desde Firestore
  factory Group.fromFirestore(Map<String, dynamic> data, String id) {
    return Group(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      ownerId: data['ownerId'] as String,
      tags: List<String>.from(data['tags'] ?? []), // ✅ NUEVO
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a JSON (compatibilidad)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'memberIds': memberIds,
      'ownerId': ownerId,
      'tags': tags, // ✅ NUEVO
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Crear desde JSON (compatibilidad)
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
      tags: (json['tags'] as List<dynamic>?) // ✅ NUEVO
          ?.map((e) => e as String)
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? memberIds,
    String? ownerId,
    List<String>? tags, // ✅ NUEVO
    DateTime? createdAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      memberIds: memberIds ?? this.memberIds,
      ownerId: ownerId ?? this.ownerId,
      tags: tags ?? this.tags, // ✅ NUEVO
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 