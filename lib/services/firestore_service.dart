import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/season.dart';
import '../models/user.dart' as models;
import '../models/episode.dart';
import '../models/group.dart';
import '../models/comment.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== ONBOARDING / TAGS ====================

  /// Busca creadores que tengan tags que coincidan con los intereses del usuario
  Future<List<models.User>> getCreatorsByTags(List<String> interestTags) async {
    try {
      print('🔍 Buscando creadores con tags: $interestTags');

      final usersSnapshot = await _firestore
          .collection('users')
          .where('creatorTags', arrayContainsAny: interestTags)
          .limit(20)
          .get();

      final creators = usersSnapshot.docs
          .map((doc) => models.User.fromFirestore(doc.data(), doc.id))
          .toList();

      print('✅ Encontrados ${creators.length} creadores');
      return creators;
    } catch (e) {
      print('❌ Error buscando creadores: $e');
      return [];
    }
  }

  /// Actualiza los interestTags del usuario
  Future<void> updateUserInterests(String userId, List<String> interestTags) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'interestTags': interestTags,
      });
      print('✅ Intereses actualizados para usuario $userId');
    } catch (e) {
      print('❌ Error actualizando intereses: $e');
      rethrow;
    }
  }

  /// Actualiza los creatorTags del usuario
  Future<void> updateCreatorTags(String userId, List<String> creatorTags) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'creatorTags': creatorTags,
      });
      print('✅ Tags de creador actualizados para usuario $userId');
    } catch (e) {
      print('❌ Error actualizando tags de creador: $e');
      rethrow;
    }
  }

  // ==================== FEED / HOME ====================

  /// Obtiene el feed para el usuario: series de creadores a los que está suscrito
  Stream<List<Season>> getFeedForUser(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((subscriptionsSnapshot) async {
      try {
        // Obtener IDs de creadores suscritos
        final creatorIds = subscriptionsSnapshot.docs
            .map((doc) => doc.data()['subscribedToUserId'] as String)
            .toList();

        if (creatorIds.isEmpty) {
          print('⚠️ Usuario $userId no sigue a nadie');
          return <Season>[];
        }

        print('📋 Usuario sigue a ${creatorIds.length} creadores');

        // Obtener grupos (series) donde el owner es uno de los creadores
        final groupsSnapshot = await _firestore
            .collection('groups')
            .where('ownerId', whereIn: creatorIds)
            .get();

        final groupIds = groupsSnapshot.docs.map((doc) => doc.id).toList();

        if (groupIds.isEmpty) {
          return <Season>[];
        }

        // Obtener temporadas activas de esos grupos
        final seasonsSnapshot = await _firestore
            .collection('seasons')
            .where('groupId', whereIn: groupIds)
            .where('isActive', isEqualTo: true)
            .get();

        print('✅ Encontradas ${seasonsSnapshot.docs.length} temporadas en el feed');

        return seasonsSnapshot.docs
            .map((doc) => Season.fromFirestore(doc.data(), doc.id))
            .toList();
      } catch (e) {
        print('❌ Error en getFeedForUser: $e');
        return <Season>[];
      }
    });
  }

  // ==================== SERIES DEL CREADOR ====================

  /// Obtiene series donde el usuario es el DUEÑO (ownerId)
  Future<List<Season>> getSeriesByCreator(String userId) async {
    try {
      // Obtener grupos donde el usuario es owner
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('ownerId', isEqualTo: userId)
          .get();

      final groupIds = groupsSnapshot.docs.map((doc) => doc.id).toList();

      if (groupIds.isEmpty) {
        print('📺 Usuario $userId no tiene series propias');
        return [];
      }

      // Obtener temporadas de esos grupos
      final seasonsSnapshot = await _firestore
          .collection('seasons')
          .where('groupId', whereIn: groupIds)
          .get();

      print('📺 Usuario tiene ${seasonsSnapshot.docs.length} series propias');

      return seasonsSnapshot.docs
          .map((doc) => Season.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error en getSeriesByCreator: $e');
      return [];
    }
  }

  /// Obtiene series donde el usuario es COLABORADOR (en memberIds pero NO owner)
  Future<List<Season>> getCollaborations(String userId) async {
    try {
      // Obtener grupos donde el usuario está en memberIds
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: userId)
          .get();

      // Filtrar solo los que NO sean owner
      final collaborationGroupIds = groupsSnapshot.docs
          .where((doc) => doc.data()['ownerId'] != userId)
          .map((doc) => doc.id)
          .toList();

      if (collaborationGroupIds.isEmpty) {
        print('🤝 Usuario $userId no tiene colaboraciones');
        return [];
      }

      // Obtener temporadas de esos grupos
      final seasonsSnapshot = await _firestore
          .collection('seasons')
          .where('groupId', whereIn: collaborationGroupIds)
          .get();

      print('🤝 Usuario tiene ${seasonsSnapshot.docs.length} colaboraciones');

      return seasonsSnapshot.docs
          .map((doc) => Season.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error en getCollaborations: $e');
      return [];
    }
  }

  // ==================== TEMPORADAS ====================

  Stream<List<Season>> getActiveSeasons(String userId) {
    return getFeedForUser(userId);
  }

  Stream<List<Season>> getPastSeasons(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((subscriptionsSnapshot) async {
      try {
        final creatorIds = subscriptionsSnapshot.docs
            .map((doc) => doc.data()['subscribedToUserId'] as String)
            .toList();

        if (creatorIds.isEmpty) {
          return <Season>[];
        }

        final groupsSnapshot = await _firestore
            .collection('groups')
            .where('ownerId', whereIn: creatorIds)
            .get();

        final groupIds = groupsSnapshot.docs.map((doc) => doc.id).toList();

        if (groupIds.isEmpty) {
          return <Season>[];
        }

        final seasonsSnapshot = await _firestore
            .collection('seasons')
            .where('groupId', whereIn: groupIds)
            .where('isActive', isEqualTo: false)
            .get();

        return seasonsSnapshot.docs
            .map((doc) => Season.fromFirestore(doc.data(), doc.id))
            .toList();
      } catch (e) {
        print('❌ Error en getPastSeasons: $e');
        return <Season>[];
      }
    });
  }

  Future<Season?> getSeasonById(String seasonId) async {
    try {
      final doc = await _firestore.collection('seasons').doc(seasonId).get();
      if (!doc.exists) {
        print('⚠️ Temporada $seasonId no existe');
        return null;
      }
      return Season.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error obteniendo temporada: $e');
      return null;
    }
  }

  // ==================== GRUPOS ====================

  Future<String> getGroupName(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) {
        print('⚠️ Grupo $groupId no existe');
        return 'Serie desconocida';
      }
      return doc.data()?['name'] ?? 'Serie desconocida';
    } catch (e) {
      print('❌ Error obteniendo nombre de grupo: $e');
      return 'Serie desconocida';
    }
  }

  Future<Group?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) {
        print('⚠️ Grupo $groupId no existe');
        return null;
      }
      return Group.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error obteniendo grupo: $e');
      return null;
    }
  }

  // ==================== EPISODIOS ====================

  Future<List<Episode>> getEpisodesBySeason(String seasonId) async {
    try {
      final snapshot = await _firestore
          .collection('episodes')
          .where('seasonId', isEqualTo: seasonId)
          .get();

      final episodes = snapshot.docs
          .map((doc) => Episode.fromFirestore(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      print('📺 Encontrados ${episodes.length} episodios para temporada $seasonId');
      return episodes;
    } catch (e) {
      print('❌ Error obteniendo episodios: $e');
      return [];
    }
  }

  Future<Episode?> getEpisodeById(String episodeId) async {
    try {
      final doc = await _firestore.collection('episodes').doc(episodeId).get();
      if (!doc.exists) {
        print('⚠️ Episodio $episodeId no existe');
        return null;
      }
      return Episode.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error obteniendo episodio: $e');
      return null;
    }
  }

  // ==================== COMENTARIOS ====================

  Stream<List<Comment>> getCommentsByEpisode(String episodeId) {
    return _firestore
        .collection('comments')
        .where('episodeId', isEqualTo: episodeId)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return comments;
    });
  }

  Future<void> addComment({
    required String episodeId,
    required String userId,
    required String username,
    required String userAvatarUrl,
    required String text,
  }) async {
    try {
      await _firestore.collection('comments').add({
        'episodeId': episodeId,
        'userId': userId,
        'username': username,
        'userAvatarUrl': userAvatarUrl,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'isLiked': false,
      });
      print('✅ Comentario añadido exitosamente');
    } catch (e) {
      print('❌ Error añadiendo comentario: $e');
      rethrow;
    }
  }

  // ==================== USUARIOS ====================

  Future<models.User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        print('⚠️ Usuario $userId no existe');
        return null;
      }
      return models.User.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      return null;
    }
  }

  Stream<models.User?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return models.User.fromFirestore(doc.data()!, doc.id);
    });
  }

  // ==================== SUSCRIPCIONES ====================

  /// Suscribirse a un creador
  Future<void> subscribeToCreator({
    required String userId,
    required String creatorId,
  }) async {
    try {
      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'subscribedToUserId': creatorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Usuario $userId suscrito a $creatorId');
    } catch (e) {
      print('❌ Error suscribiendo: $e');
      rethrow;
    }
  }

  /// Desuscribirse de un creador
  Future<void> unsubscribeFromCreator({
    required String userId,
    required String creatorId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('subscribedToUserId', isEqualTo: creatorId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Usuario $userId desuscrito de $creatorId');
    } catch (e) {
      print('❌ Error desuscribiendo: $e');
      rethrow;
    }
  }

  /// Verificar si está suscrito
  Future<bool> isSubscribed({
    required String userId,
    required String creatorId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('subscribedToUserId', isEqualTo: creatorId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando suscripción: $e');
      return false;
    }
  }

  /// Obtener creadores a los que sigue
  Future<List<models.User>> getSubscribedCreators(String userId) async {
    try {
      final subscriptionsSnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      final creatorIds = subscriptionsSnapshot.docs
          .map((doc) => doc.data()['subscribedToUserId'] as String)
          .toList();

      if (creatorIds.isEmpty) {
        return [];
      }

      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: creatorIds)
          .get();

      return usersSnapshot.docs
          .map((doc) => models.User.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo creadores suscritos: $e');
      return [];
    }
  }

  /// Obtener seguidores de un creador
  Future<int> getFollowersCount(String creatorId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('subscribedToUserId', isEqualTo: creatorId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error obteniendo seguidores: $e');
      return 0;
    }
  }

  // ==================== ACCIONES SOCIALES ====================

  Future<void> toggleLike({
    required String episodeId,
    required bool currentlyLiked,
  }) async {
    try {
      final episodeRef = _firestore.collection('episodes').doc(episodeId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(episodeRef);
        if (!snapshot.exists) return;

        final currentLikes = snapshot.data()?['likes'] ?? 0;
        final newLikes = currentlyLiked ? currentLikes - 1 : currentLikes + 1;

        transaction.update(episodeRef, {'likes': newLikes});
      });

      print('✅ Like actualizado para episodio $episodeId');
    } catch (e) {
      print('❌ Error actualizando like: $e');
      rethrow;
    }
  }

  Future<void> incrementViews(String episodeId) async {
    try {
      await _firestore.collection('episodes').doc(episodeId).update({
        'views': FieldValue.increment(1),
      });
      print('✅ Vista incrementada para episodio $episodeId');
    } catch (e) {
      print('❌ Error incrementando vistas: $e');
    }
  }

  // ==================== EXPLORE / DISCOVERY ====================

  /// Obtiene todas las temporadas activas (para descubrir)
  Future<List<Season>> getAllActiveSeasons({int limit = 30}) async {
    try {
      final snapshot = await _firestore
          .collection('seasons')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Season.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error en getAllActiveSeasons: $e');
      return [];
    }
  }

  /// Recomendaciones personalizadas basadas en interestTags del usuario
  Future<List<Season>> getRecommendedSeasons(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null || user.interestTags.isEmpty) {
        return getAllActiveSeasons(limit: 20);
      }

      // Creadores cuyos creatorTags coincidan con los intereses del usuario
      final creators = await getCreatorsByTags(user.interestTags);
      if (creators.isEmpty) {
        return getAllActiveSeasons(limit: 20);
      }

      // Excluir al propio usuario y tomar máx 10 (límite whereIn de Firestore)
      final creatorIds = creators
          .where((c) => c.id != userId)
          .map((c) => c.id)
          .take(10)
          .toList();

      if (creatorIds.isEmpty) return getAllActiveSeasons(limit: 20);

      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('ownerId', whereIn: creatorIds)
          .get();

      final groupIds =
          groupsSnapshot.docs.map((doc) => doc.id).take(10).toList();

      if (groupIds.isEmpty) return getAllActiveSeasons(limit: 20);

      final seasonsSnapshot = await _firestore
          .collection('seasons')
          .where('groupId', whereIn: groupIds)
          .where('isActive', isEqualTo: true)
          .get();

      print(
          '✅ Recomendaciones: ${seasonsSnapshot.docs.length} temporadas encontradas');
      return seasonsSnapshot.docs
          .map((doc) => Season.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error en getRecommendedSeasons: $e');
      return [];
    }
  }

  /// Busca series por nombre (filtrado client-side)
  Future<List<Season>> searchSeasons(String query) async {
    try {
      final snapshot = await _firestore
          .collection('seasons')
          .limit(100)
          .get();

      final queryLower = query.toLowerCase();
      return snapshot.docs
          .map((doc) => Season.fromFirestore(doc.data(), doc.id))
          .where((s) => s.name.toLowerCase().contains(queryLower))
          .take(20)
          .toList();
    } catch (e) {
      print('❌ Error en searchSeasons: $e');
      return [];
    }
  }

  /// Busca creadores por nombre o username (filtrado client-side)
  Future<List<models.User>> searchCreators(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(100)
          .get();

      final queryLower = query.toLowerCase();
      return snapshot.docs
          .map((doc) => models.User.fromFirestore(doc.data(), doc.id))
          .where((u) =>
              u.name.toLowerCase().contains(queryLower) ||
              (u.username?.toLowerCase().contains(queryLower) ?? false))
          .take(20)
          .toList();
    } catch (e) {
      print('❌ Error en searchCreators: $e');
      return [];
    }
  }

  // ==================== SERIES GUARDADAS ====================

  Future<void> saveSeason({
    required String userId,
    required String seasonId,
  }) async {
    await _firestore.collection('savedSeasons').add({
      'userId': userId,
      'seasonId': seasonId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsaveSeason({
    required String userId,
    required String seasonId,
  }) async {
    final snapshot = await _firestore
        .collection('savedSeasons')
        .where('userId', isEqualTo: userId)
        .where('seasonId', isEqualTo: seasonId)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> isSeasonSaved({
    required String userId,
    required String seasonId,
  }) async {
    final snapshot = await _firestore
        .collection('savedSeasons')
        .where('userId', isEqualTo: userId)
        .where('seasonId', isEqualTo: seasonId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<List<Season>> getSavedSeasons(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('savedSeasons')
          .where('userId', isEqualTo: userId)
          .get();

      final seasonIds = snapshot.docs
          .map((doc) => doc.data()['seasonId'] as String)
          .toList();

      if (seasonIds.isEmpty) return [];

      final List<Season> seasons = [];
      for (final id in seasonIds) {
        final season = await getSeasonById(id);
        if (season != null) seasons.add(season);
      }
      return seasons;
    } catch (e) {
      print('❌ Error en getSavedSeasons: $e');
      return [];
    }
  }

  // ==================== EPISODIOS CON LIKE (por usuario) ====================

  Future<void> likeEpisode({
    required String userId,
    required String episodeId,
    required String seasonId,
  }) async {
    final batch = _firestore.batch();

    // Registrar like del usuario
    final likeRef = _firestore.collection('episodeLikes').doc();
    batch.set(likeRef, {
      'userId': userId,
      'episodeId': episodeId,
      'seasonId': seasonId,
      'savedAt': FieldValue.serverTimestamp(),
    });

    // Incrementar contador global del episodio
    final episodeRef = _firestore.collection('episodes').doc(episodeId);
    batch.update(episodeRef, {'likes': FieldValue.increment(1)});

    await batch.commit();
  }

  Future<void> unlikeEpisode({
    required String userId,
    required String episodeId,
  }) async {
    final snapshot = await _firestore
        .collection('episodeLikes')
        .where('userId', isEqualTo: userId)
        .where('episodeId', isEqualTo: episodeId)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    // Decrementar contador global
    final episodeRef = _firestore.collection('episodes').doc(episodeId);
    batch.update(episodeRef, {'likes': FieldValue.increment(-1)});

    await batch.commit();
  }

  Future<bool> isEpisodeLiked({
    required String userId,
    required String episodeId,
  }) async {
    final snapshot = await _firestore
        .collection('episodeLikes')
        .where('userId', isEqualTo: userId)
        .where('episodeId', isEqualTo: episodeId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<List<Episode>> getLikedEpisodes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('episodeLikes')
          .where('userId', isEqualTo: userId)
          .get();

      final episodeIds = snapshot.docs
          .map((doc) => doc.data()['episodeId'] as String)
          .toList();

      if (episodeIds.isEmpty) return [];

      final List<Episode> episodes = [];
      for (final id in episodeIds) {
        final episode = await getEpisodeById(id);
        if (episode != null) episodes.add(episode);
      }
      return episodes;
    } catch (e) {
      print('❌ Error en getLikedEpisodes: $e');
      return [];
    }
  }

  // ==================== PERFIL ====================

  Future<void> updateUserProfile(
    String userId, {
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (updates.isEmpty) return;
    await _firestore.collection('users').doc(userId).update(updates);
  }

  // ==================== GRUPOS (CREAR / LISTAR) ====================

  Future<List<Group>> getGroupsByOwner(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('ownerId', isEqualTo: userId)
          .get();
      final groups = <Group>[];
      for (final doc in snapshot.docs) {
        try {
          groups.add(Group.fromFirestore(doc.data(), doc.id));
        } catch (e) {
          print('⚠️ Error parseando grupo ${doc.id}: $e');
        }
      }
      return groups;
    } catch (e) {
      print('❌ Error obteniendo grupos: $e');
      return [];
    }
  }

  Future<String?> addGroup({
    required String ownerId,
    required String name,
    String description = '',
    String imageUrl = '',
  }) async {
    try {
      final docRef = await _firestore.collection('groups').add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl.isEmpty
            ? 'https://i.pravatar.cc/300?u=$ownerId'
            : imageUrl,
        'ownerId': ownerId,
        'memberIds': [ownerId],
        'tags': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Grupo creado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creando grupo: $e');
      return null;
    }
  }

  // ==================== TEMPORADAS (CREAR) ====================

  Future<String?> addSeason({
    required String groupId,
    required String name,
    String description = '',
    String imageUrl = '',
    required int totalDays,
  }) async {
    try {
      final docRef = await _firestore.collection('seasons').add({
        'groupId': groupId,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'thumbnailUrl': imageUrl,
        'totalDays': totalDays,
        'currentDay': 0,
        'streakDays': 0,
        'isActive': true,
        'hasUploadedToday': false,
        'startDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Temporada creada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creando temporada: $e');
      return null;
    }
  }

  // ==================== SUBIR EPISODIO ====================

  /// Crea un nuevo episodio en Firestore y actualiza el progreso de la temporada.
  Future<String?> addEpisode({
    required String seasonId,
    required String userId,
    required String title,
    String? description,
    required String videoUrl,
    required String thumbnailUrl,
    int durationSeconds = 0,
  }) async {
    try {
      // Contar episodios existentes para determinar el número
      final existing = await _firestore
          .collection('episodes')
          .where('seasonId', isEqualTo: seasonId)
          .get();
      final episodeNumber = existing.docs.length + 1;

      final docRef = await _firestore.collection('episodes').add({
        'seasonId': seasonId,
        'userId': userId,
        'episodeNumber': episodeNumber,
        'title': title,
        'description': description,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'uploadedAt': FieldValue.serverTimestamp(),
        'views': 0,
        'likes': 0,
        'commentsCount': 0,
      });

      // Actualizar temporada solo si no ha subido hoy
      await _firestore.runTransaction((transaction) async {
        final seasonRef = _firestore.collection('seasons').doc(seasonId);
        final seasonSnap = await transaction.get(seasonRef);
        if (!seasonSnap.exists) return;

        final alreadyUploaded = seasonSnap.data()?['hasUploadedToday'] ?? false;
        final updates = <String, dynamic>{'hasUploadedToday': true};
        if (!alreadyUploaded) {
          updates['currentDay'] = FieldValue.increment(1);
          updates['streakDays'] = FieldValue.increment(1);
        }
        transaction.update(seasonRef, updates);
      });

      print('✅ Episodio $episodeNumber creado: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error añadiendo episodio: $e');
      return null;
    }
  }

  /// Cuenta cuántos creadores sigue el usuario
  Future<int> getSubscribedCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error en getSubscribedCount: $e');
      return 0;
    }
  }
}