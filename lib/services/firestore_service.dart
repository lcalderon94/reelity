import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/season.dart';
import '../models/user.dart' as models;
import '../models/episode.dart';
import '../models/group.dart';
import '../models/comment.dart';
import '../models/subscription.dart';

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
          .orderBy('episodeNumber')
          .get();

      print('📺 Encontrados ${snapshot.docs.length} episodios para temporada $seasonId');

      return snapshot.docs
          .map((doc) => Episode.fromFirestore(doc.data(), doc.id))
          .toList();
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
          .toList();
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
}