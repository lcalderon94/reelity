class Season {
  final String id;
  final String groupId;
  final String name;
  final String? description;
  final String imageUrl;
  final int currentDay;
  final int totalDays;
  final bool hasUploadedToday;
  final int streakDays;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  Season({
    required this.id,
    required this.groupId,
    required this.name,
    this.description,
    required this.imageUrl,
    required this.currentDay,
    required this.totalDays,
    this.hasUploadedToday = false,
    this.streakDays = 0,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'currentDay': currentDay,
      'totalDays': totalDays,
      'hasUploadedToday': hasUploadedToday,
      'streakDays': streakDays,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Crear desde JSON
  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String,
      currentDay: json['currentDay'] as int,
      totalDays: json['totalDays'] as int,
      hasUploadedToday: json['hasUploadedToday'] as bool? ?? false,
      streakDays: json['streakDays'] as int? ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // Copiar con cambios
  Season copyWith({
    String? id,
    String? groupId,
    String? name,
    String? description,
    String? imageUrl,
    int? currentDay,
    int? totalDays,
    bool? hasUploadedToday,
    int? streakDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Season(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      currentDay: currentDay ?? this.currentDay,
      totalDays: totalDays ?? this.totalDays,
      hasUploadedToday: hasUploadedToday ?? this.hasUploadedToday,
      streakDays: streakDays ?? this.streakDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
