import 'package:cloud_firestore/cloud_firestore.dart';

class Season {
  final String id;
  final String name;
  final String groupId;
  final int currentDay;
  final int totalDays;
  final int streakDays;
  final bool isActive;
  final bool hasUploadedToday;
  final String? thumbnailUrl;
  final String? imageUrl;
  final String? description;

  /// Para el mock / stats
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;

  Season({
    required this.id,
    required this.name,
    required this.groupId,
    required this.currentDay,
    required this.totalDays,
    required this.streakDays,
    required this.isActive,
    this.hasUploadedToday = false,
    this.thumbnailUrl,
    this.imageUrl,
    this.description,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  // ========= JSON (para SharedPreferences / mock) =========

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as String,
      name: json['name'] as String,
      groupId: json['groupId'] as String,
      currentDay: (json['currentDay'] ?? 0) as int,
      totalDays: (json['totalDays'] ?? 0) as int,
      streakDays: (json['streakDays'] ?? 0) as int,
      isActive: (json['isActive'] ?? true) as bool,
      hasUploadedToday: (json['hasUploadedToday'] ?? false) as bool,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'groupId': groupId,
      'currentDay': currentDay,
      'totalDays': totalDays,
      'streakDays': streakDays,
      'isActive': isActive,
      'hasUploadedToday': hasUploadedToday,
      'thumbnailUrl': thumbnailUrl,
      'imageUrl': imageUrl,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // ========= Firestore =========

  factory Season.fromFirestore(Map<String, dynamic> data, String id) {
    return Season(
      id: id,
      name: data['name'] ?? 'Sin nombre',
      groupId: data['groupId'] ?? '',
      currentDay: data['currentDay'] ?? 1,
      totalDays: data['totalDays'] ?? 30,
      streakDays: data['streakDays'] ?? 0,
      isActive: data['isActive'] ?? true,
      hasUploadedToday: data['hasUploadedToday'] ?? false,
      thumbnailUrl: data['thumbnailUrl'],
      imageUrl: data['imageUrl'],
      description: data['description'],
      startDate: _timestampOrStringToDate(data['startDate']),
      endDate: _timestampOrStringToDate(data['endDate']),
      createdAt: _timestampOrStringToDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'groupId': groupId,
      'currentDay': currentDay,
      'totalDays': totalDays,
      'streakDays': streakDays,
      'isActive': isActive,
      'hasUploadedToday': hasUploadedToday,
      'thumbnailUrl': thumbnailUrl,
      'imageUrl': imageUrl,
      'description': description,
      'startDate':
      startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt':
      createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  // ========= Helper =========

  static DateTime? _timestampOrStringToDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
