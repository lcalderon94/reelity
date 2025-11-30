import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/season.dart';
import '../models/group.dart';
import '../models/episode.dart';
import '../models/comment.dart';

class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  SharedPreferences? _prefs;

  // Datos en memoria
  List<User> _users = [];
  User? _currentUser;
  List<Season> _seasons = [];
  List<Group> _groups = [];
  List<Episode> _episodes = [];
  List<Comment> _comments = [];

  // Keys para SharedPreferences
  static const String _keyUsers = 'users';
  static const String _keyCurrentUserId = 'current_user_id';
  static const String _keySeasons = 'seasons';
  static const String _keyGroups = 'groups';
  static const String _keyEpisodes = 'episodes';
  static const String _keyComments = 'comments';
  static const String _keyIsInitialized = 'is_initialized';

  /// Inicializar el servicio
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final isInitialized = _prefs?.getBool(_keyIsInitialized) ?? false;

    if (isInitialized) {
      await _loadFromStorage();
    } else {
      await _loadInitialData();
      await _saveToStorage();
      await _prefs?.setBool(_keyIsInitialized, true);
    }
  }

  /// Cargar datos iniciales
  Future<void> _loadInitialData() async {
    // Usuarios iniciales
    _users = [
      User(
        id: 'user_1',
        name: 'Luis García',
        email: 'luis@reelity.com',
        password: '123456',
        username: '@luisgarcia',
        avatarUrl: 'https://i.pravatar.cc/300?img=12',
        bio: 'Creador de REELITY 🎬',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user_2',
        name: 'Sara Safari',
        email: 'sara@example.com',
        password: '123456',
        username: '@sarasafari',
        avatarUrl: 'https://i.pravatar.cc/300?img=45',
        bio: 'Adventure seeker 🌍✈️',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      User(
        id: 'user_3',
        name: 'Alex Drift',
        email: 'alex@example.com',
        password: '123456',
        username: '@alexdrift',
        avatarUrl: 'https://i.pravatar.cc/300?img=33',
        bio: 'Car enthusiast 🏎️ JDM lover',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      User(
        id: 'user_4',
        name: 'Nico Comedy',
        email: 'nico@example.com',
        password: '123456',
        username: '@nicocomedy',
        avatarUrl: 'https://i.pravatar.cc/300?img=68',
        bio: 'Epic fails compilation 😂',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      User(
        id: 'user_5',
        name: 'Marina Beach',
        email: 'marina@example.com',
        password: '123456',
        username: '@marinabeach',
        avatarUrl: 'https://i.pravatar.cc/300?img=25',
        bio: 'Beach vibes only 🌊☀️',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
    ];

    _currentUser = _users[0];

    // Grupos
    _groups = [
      Group(
        id: 'group_0',
        name: 'Luis García',
        description: 'Creador de REELITY',
        imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800',
        memberIds: ['user_1'],
        ownerId: 'user_1',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
      Group(
        id: 'group_1',
        name: 'Sara Safari',
        description: 'Adventures and daily life',
        imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        memberIds: ['user_1', 'user_2'],
        ownerId: 'user_2',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Group(
        id: 'group_2',
        name: 'Drift Kings',
        description: 'Japanese car culture',
        imageUrl: 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800',
        memberIds: ['user_1', 'user_3'],
        ownerId: 'user_3',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      Group(
        id: 'group_3',
        name: 'Nissaxter',
        description: 'Epic fails compilation',
        imageUrl: 'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800',
        memberIds: ['user_1', 'user_4'],
        ownerId: 'user_4',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
      Group(
        id: 'group_4',
        name: 'Beach Crew',
        description: 'Verano para siempre',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        memberIds: ['user_1', 'user_5'],
        ownerId: 'user_5',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
    ];

    // Temporadas
    _seasons = [
      Season(
        id: 'season_0',
        groupId: 'group_0',
        name: 'Building REELITY',
        description: 'Creating the next big social platform',
        imageUrl: 'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800',
        currentDay: 10,
        totalDays: 30,
        hasUploadedToday: true,
        streakDays: 10,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        isActive: true,
      ),
      Season(
        id: 'season_1',
        groupId: 'group_1',
        name: 'Sara Safari Adventures',
        description: 'Daily adventures and lifestyle content',
        imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        currentDay: 5,
        totalDays: 30,
        hasUploadedToday: true,
        streakDays: 5,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
      ),
      Season(
        id: 'season_2',
        groupId: 'group_2',
        name: 'Tunning Japan',
        description: 'Japanese car culture and drift lifestyle',
        imageUrl: 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=800',
        currentDay: 5,
        totalDays: 7,
        hasUploadedToday: false,
        streakDays: 5,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
      ),
      Season(
        id: 'season_3',
        groupId: 'group_3',
        name: 'Nissaxter Epic Fails',
        description: 'The funniest fails and bloopers',
        imageUrl: 'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800',
        currentDay: 5,
        totalDays: 90,
        hasUploadedToday: true,
        streakDays: 5,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
      ),
      Season(
        id: 'season_4',
        groupId: 'group_4',
        name: 'Verano 2024',
        description: 'Los mejores días en la playa',
        imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        currentDay: 30,
        totalDays: 30,
        hasUploadedToday: false,
        streakDays: 0,
        startDate: DateTime.now().subtract(const Duration(days: 150)),
        endDate: DateTime.now().subtract(const Duration(days: 120)),
        isActive: false,
      ),
      Season(
        id: 'season_5',
        groupId: 'group_2',
        name: 'Navidad en Familia',
        description: 'Celebraciones navideñas',
        imageUrl: 'https://images.unsplash.com/photo-1512389142860-9c449e58a543?w=800',
        currentDay: 14,
        totalDays: 14,
        hasUploadedToday: false,
        streakDays: 0,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now().subtract(const Duration(days: 76)),
        isActive: false,
      ),
    ];

    // Episodios para Sara Safari Adventures (con userId)
    _episodes = [
      // Building REELITY - Luis García
      Episode(
        id: 'ep_0_1',
        seasonId: 'season_0',
        userId: 'user_1', // Luis García
        episodeNumber: 1,
        title: 'Day 1: The Vision',
        description: 'Starting REELITY - the future of social media',
        thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
        videoUrl: 'dQw4w9WgXcQ',
        durationSeconds: 30,
        uploadedAt: DateTime.now().subtract(const Duration(days: 10)),
        views: 5420,
        likes: 892,
        commentsCount: 156,
      ),
      Episode(
        id: 'ep_0_2',
        seasonId: 'season_0',
        userId: 'user_1', // Luis García
        episodeNumber: 2,
        title: 'First Prototype',
        description: 'Building the first version of the app',
        thumbnailUrl: 'https://img.youtube.com/vi/jNQXAC9IVRw/maxresdefault.jpg',
        videoUrl: 'jNQXAC9IVRw',
        durationSeconds: 25,
        uploadedAt: DateTime.now().subtract(const Duration(days: 9)),
        views: 4230,
        likes: 678,
        commentsCount: 89,
      ),
      Episode(
        id: 'ep_0_3',
        seasonId: 'season_0',
        userId: 'user_1', // Luis García
        episodeNumber: 3,
        title: 'Team Meeting',
        description: 'Discussing features with the team',
        thumbnailUrl: 'https://img.youtube.com/vi/9bZkp7q19f0/maxresdefault.jpg',
        videoUrl: '9bZkp7q19f0',
        durationSeconds: 28,
        uploadedAt: DateTime.now().subtract(const Duration(days: 8)),
        views: 3890,
        likes: 543,
        commentsCount: 67,
      ),

      // Sara Safari Adventures
      Episode(
        id: 'ep_1',
        seasonId: 'season_1',
        userId: 'user_2', // Sara Safari
        episodeNumber: 1,
        title: 'Adventure Begins',
        description: 'Starting my journey with an epic moment!',
        thumbnailUrl: 'https://img.youtube.com/vi/Ok8RnLjge8M/maxresdefault.jpg',
        videoUrl: 'Ok8RnLjge8M',
        durationSeconds: 28,
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        views: 1245,
        likes: 456,
        commentsCount: 34,
      ),
      Episode(
        id: 'ep_2',
        seasonId: 'season_1',
        userId: 'user_2', // Sara Safari
        episodeNumber: 2,
        title: 'Daily Vibes',
        description: 'Just another day in the life',
        thumbnailUrl: 'https://img.youtube.com/vi/0DxmRF9x_jM/maxresdefault.jpg',
        videoUrl: '0DxmRF9x_jM',
        durationSeconds: 24,
        uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
        views: 982,
        likes: 321,
        commentsCount: 28,
      ),
      Episode(
        id: 'ep_3',
        seasonId: 'season_1',
        userId: 'user_2', // Sara Safari
        episodeNumber: 3,
        title: 'New Discovery',
        description: 'Found something amazing today',
        thumbnailUrl: 'https://img.youtube.com/vi/JDXTLm3IiLs/maxresdefault.jpg',
        videoUrl: 'JDXTLm3IiLs',
        durationSeconds: 31,
        uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
        views: 1567,
        likes: 523,
        commentsCount: 45,
      ),
      Episode(
        id: 'ep_4',
        seasonId: 'season_1',
        userId: 'user_2', // Sara Safari
        episodeNumber: 4,
        title: 'Epic Moment',
        description: 'This is what I live for!',
        thumbnailUrl: 'https://img.youtube.com/vi/2bbS7NIto_8/maxresdefault.jpg',
        videoUrl: '2bbS7NIto_8',
        durationSeconds: 27,
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        views: 2034,
        likes: 678,
        commentsCount: 56,
      ),
      Episode(
        id: 'ep_5',
        seasonId: 'season_1',
        userId: 'user_2', // Sara Safari
        episodeNumber: 5,
        title: 'Latest Adventure',
        description: 'Today was absolutely insane',
        thumbnailUrl: 'https://img.youtube.com/vi/IsMK-xyuces/maxresdefault.jpg',
        videoUrl: 'IsMK-xyuces',
        durationSeconds: 29,
        uploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
        views: 892,
        likes: 234,
        commentsCount: 19,
      ),

      // Tunning Japan
      Episode(
        id: 'ep_6',
        seasonId: 'season_2',
        userId: 'user_3', // Alex Drift
        episodeNumber: 1,
        title: 'Tokyo Drift',
        description: 'First day in Japan, checking out the car scene',
        thumbnailUrl: 'https://img.youtube.com/vi/YyWdxhYpk3Q/maxresdefault.jpg',
        videoUrl: 'YyWdxhYpk3Q',
        durationSeconds: 25,
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        views: 1567,
        likes: 589,
        commentsCount: 42,
      ),
      Episode(
        id: 'ep_7',
        seasonId: 'season_2',
        userId: 'user_3', // Alex Drift
        episodeNumber: 2,
        title: 'Tuning Shop',
        description: 'Found this amazing tuning shop in Shibuya',
        thumbnailUrl: 'https://img.youtube.com/vi/jDNhWXN_EW8/maxresdefault.jpg',
        videoUrl: 'jDNhWXN_EW8',
        durationSeconds: 22,
        uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
        views: 1234,
        likes: 456,
        commentsCount: 31,
      ),
      Episode(
        id: 'ep_8',
        seasonId: 'season_2',
        userId: 'user_3', // Alex Drift
        episodeNumber: 3,
        title: 'Street Racing',
        description: 'Late night racing on the highway',
        thumbnailUrl: 'https://img.youtube.com/vi/sGNK-cOtxSs/maxresdefault.jpg',
        videoUrl: 'sGNK-cOtxSs',
        durationSeconds: 30,
        uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
        views: 2134,
        likes: 723,
        commentsCount: 67,
      ),
      Episode(
        id: 'ep_9',
        seasonId: 'season_2',
        userId: 'user_3', // Alex Drift
        episodeNumber: 4,
        title: 'Car Meet',
        description: 'Biggest JDM car meet I have ever seen!',
        thumbnailUrl: 'https://img.youtube.com/vi/NVpH1w_aSUk/maxresdefault.jpg',
        videoUrl: 'NVpH1w_aSUk',
        durationSeconds: 26,
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        views: 1789,
        likes: 634,
        commentsCount: 45,
      ),
      Episode(
        id: 'ep_10',
        seasonId: 'season_2',
        userId: 'user_3', // Alex Drift
        episodeNumber: 5,
        title: 'My New Car',
        description: 'Finally bought my dream car in Japan!',
        thumbnailUrl: 'https://img.youtube.com/vi/o1tj2zJ2Wvg/maxresdefault.jpg',
        videoUrl: 'o1tj2zJ2Wvg',
        durationSeconds: 28,
        uploadedAt: DateTime.now().subtract(const Duration(hours: 3)),
        views: 945,
        likes: 387,
        commentsCount: 28,
      ),

      // Nissaxter Epic Fails
      Episode(
        id: 'ep_11',
        seasonId: 'season_3',
        userId: 'user_4', // Nico Comedy
        episodeNumber: 1,
        title: 'First Fail',
        description: 'This is how it all started...',
        thumbnailUrl: 'https://img.youtube.com/vi/PEikGKDVsCc/maxresdefault.jpg',
        videoUrl: 'PEikGKDVsCc',
        durationSeconds: 15,
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        views: 3456,
        likes: 1234,
        commentsCount: 89,
      ),
      Episode(
        id: 'ep_12',
        seasonId: 'season_3',
        userId: 'user_4', // Nico Comedy
        episodeNumber: 2,
        title: 'Kitchen Disaster',
        description: 'Tried to cook... you can imagine what happened',
        thumbnailUrl: 'https://img.youtube.com/vi/W45DRy7M1no/maxresdefault.jpg',
        videoUrl: 'W45DRy7M1no',
        durationSeconds: 18,
        uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
        views: 2789,
        likes: 987,
        commentsCount: 67,
      ),
      Episode(
        id: 'ep_13',
        seasonId: 'season_3',
        userId: 'user_4', // Nico Comedy
        episodeNumber: 3,
        title: 'Gym Fail',
        description: 'Never doing that exercise again',
        thumbnailUrl: 'https://img.youtube.com/vi/0la5DBtOVNI/maxresdefault.jpg',
        videoUrl: '0la5DBtOVNI',
        durationSeconds: 12,
        uploadedAt: DateTime.now().subtract(const Duration(days: 3)),
        views: 4123,
        likes: 1567,
        commentsCount: 102,
      ),
      Episode(
        id: 'ep_14',
        seasonId: 'season_3',
        userId: 'user_4', // Nico Comedy
        episodeNumber: 4,
        title: 'Parking Lot Chronicles',
        description: 'How NOT to park a car',
        thumbnailUrl: 'https://img.youtube.com/vi/X1wJAcgU8Ww/maxresdefault.jpg',
        videoUrl: 'X1wJAcgU8Ww',
        durationSeconds: 20,
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        views: 3567,
        likes: 1234,
        commentsCount: 78,
      ),
      Episode(
        id: 'ep_15',
        seasonId: 'season_3',
        userId: 'user_4', // Nico Comedy
        episodeNumber: 5,
        title: 'Technology Struggles',
        description: 'Me vs. my laptop... laptop won',
        thumbnailUrl: 'https://img.youtube.com/vi/5pidokakU4I/maxresdefault.jpg',
        videoUrl: '5pidokakU4I',
        durationSeconds: 16,
        uploadedAt: DateTime.now().subtract(const Duration(hours: 4)),
        views: 2345,
        likes: 876,
        commentsCount: 54,
      ),
    ];

    // Comentarios
    _comments = [
      Comment(
        id: 'comment_1',
        episodeId: 'ep_1',
        userId: 'user_1',
        username: '@luisgarcia',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=12',
        text: '¡Increíble aventura Sara! 🔥',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 12,
      ),
      Comment(
        id: 'comment_2',
        episodeId: 'ep_1',
        userId: 'user_3',
        username: '@alexdrift',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=33',
        text: 'Qué envidia, quiero ir ahí también',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likes: 8,
      ),
      Comment(
        id: 'comment_3',
        episodeId: 'ep_1',
        userId: 'user_4',
        username: '@nicocomedy',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=68',
        text: '¿Qué lugar es este? Se ve espectacular',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        likes: 5,
      ),
      Comment(
        id: 'comment_4',
        episodeId: 'ep_1',
        userId: 'user_5',
        username: '@marinabeach',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=25',
        text: 'Eres una crack Sara! 👏👏 A seguir así',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        likes: 15,
      ),
    ];
  }

  /// Guardar datos en SharedPreferences
  Future<void> _saveToStorage() async {
    if (_prefs == null) return;

    await _prefs!.setString(_keyUsers, jsonEncode(_users.map((u) => u.toJson()).toList()));

    if (_currentUser != null) {
      await _prefs!.setString(_keyCurrentUserId, _currentUser!.id);
    }

    await _prefs!.setString(_keySeasons, jsonEncode(_seasons.map((s) => s.toJson()).toList()));
    await _prefs!.setString(_keyGroups, jsonEncode(_groups.map((g) => g.toJson()).toList()));
    await _prefs!.setString(_keyEpisodes, jsonEncode(_episodes.map((e) => e.toJson()).toList()));
    await _prefs!.setString(_keyComments, jsonEncode(_comments.map((c) => c.toJson()).toList()));
  }

  /// Cargar datos desde SharedPreferences
  Future<void> _loadFromStorage() async {
    if (_prefs == null) return;

    final usersJson = _prefs!.getString(_keyUsers);
    if (usersJson != null) {
      final List<dynamic> list = jsonDecode(usersJson);
      _users = list.map((json) => User.fromJson(json)).toList();
    }

    final currentUserId = _prefs!.getString(_keyCurrentUserId);
    if (currentUserId != null) {
      try {
        _currentUser = _users.firstWhere((u) => u.id == currentUserId);
      } catch (e) {
        _currentUser = null;
      }
    }

    final seasonsJson = _prefs!.getString(_keySeasons);
    if (seasonsJson != null) {
      final List<dynamic> list = jsonDecode(seasonsJson);
      _seasons = list.map((json) => Season.fromJson(json)).toList();
    }

    final groupsJson = _prefs!.getString(_keyGroups);
    if (groupsJson != null) {
      final List<dynamic> list = jsonDecode(groupsJson);
      _groups = list.map((json) => Group.fromJson(json)).toList();
    }

    final episodesJson = _prefs!.getString(_keyEpisodes);
    if (episodesJson != null) {
      final List<dynamic> list = jsonDecode(episodesJson);
      _episodes = list.map((json) => Episode.fromJson(json)).toList();
    }

    final commentsJson = _prefs!.getString(_keyComments);
    if (commentsJson != null) {
      final List<dynamic> list = jsonDecode(commentsJson);
      _comments = list.map((json) => Comment.fromJson(json)).toList();
    }
  }

  // ============= GETTERS =============

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  List<Season> getActiveSeasons() {
    return _seasons.where((s) => s.isActive).toList();
  }

  List<Season> getPastSeasons() {
    return _seasons.where((s) => !s.isActive).toList();
  }

  List<Group> getGroups() {
    return _groups;
  }

  Group? getGroupById(String groupId) {
    try {
      return _groups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }

  Season? getSeasonById(String seasonId) {
    try {
      return _seasons.firstWhere((s) => s.id == seasonId);
    } catch (e) {
      return null;
    }
  }

  List<Episode> getEpisodesBySeason(String seasonId) {
    return _episodes.where((e) => e.seasonId == seasonId).toList()
      ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
  }

  Episode? getEpisodeById(String episodeId) {
    try {
      return _episodes.firstWhere((e) => e.id == episodeId);
    } catch (e) {
      return null;
    }
  }

  List<Comment> getCommentsByEpisode(String episodeId) {
    return _comments.where((c) => c.episodeId == episodeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Season> getSeasonsByUser(String userId) {
    final userGroups = _groups.where((g) => g.ownerId == userId).map((g) => g.id).toList();
    return _seasons.where((s) => userGroups.contains(s.groupId)).toList();
  }

  // NUEVO: Obtener usuario por ID
  User? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  // ============= STATS =============

  Map<String, int> getUserStats(String userId) {
    final userSeasons = getSeasonsByUser(userId);
    final userEpisodes = _episodes.where((e) =>
        userSeasons.any((s) => s.id == e.seasonId)
    ).toList();

    final totalViews = userEpisodes.fold<int>(0, (sum, e) => sum + e.views);
    final totalLikes = userEpisodes.fold<int>(0, (sum, e) => sum + e.likes);

    return {
      'seasons': userSeasons.length,
      'episodes': userEpisodes.length,
      'views': totalViews,
      'likes': totalLikes,
    };
  }

  // ============= SIMULACIÓN DE DELAY =============

  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // ============= AUTENTICACIÓN =============

  Future<User?> login(String email, String password) async {
    await _simulateNetworkDelay();

    try {
      final user = _users.firstWhere(
            (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password,
      );

      _currentUser = user;
      await _prefs?.setString(_keyCurrentUserId, user.id);

      return user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> register(String name, String email, String password) async {
    await _simulateNetworkDelay();

    final emailExists = _users.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (emailExists) {
      return null;
    }

    final newUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      password: password,
      username: '@${name.toLowerCase().replaceAll(' ', '')}',
      avatarUrl: 'https://i.pravatar.cc/300?img=${DateTime.now().millisecond % 70}',
      createdAt: DateTime.now(),
    );

    _users.add(newUser);
    _currentUser = newUser;

    await _saveToStorage();
    return newUser;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _prefs?.remove(_keyCurrentUserId);
  }

  // ============= ACCIONES =============

  Future<bool> toggleLikeEpisode(String episodeId) async {
    await _simulateNetworkDelay();

    final episode = getEpisodeById(episodeId);
    if (episode == null) return false;

    final index = _episodes.indexWhere((e) => e.id == episodeId);
    _episodes[index] = episode.copyWith(likes: episode.likes + 1);

    await _saveToStorage();
    return true;
  }

  Future<Comment?> addComment(String episodeId, String text) async {
    await _simulateNetworkDelay();

    if (_currentUser == null) return null;

    final newComment = Comment(
      id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
      episodeId: episodeId,
      userId: _currentUser!.id,
      username: _currentUser!.username ?? '@user',
      userAvatarUrl: _currentUser!.avatarUrl ?? '',
      text: text,
      createdAt: DateTime.now(),
    );

    _comments.add(newComment);

    // Actualizar contador de comentarios en el episodio
    final episode = getEpisodeById(episodeId);
    if (episode != null) {
      final index = _episodes.indexWhere((e) => e.id == episodeId);
      _episodes[index] = episode.copyWith(commentsCount: episode.commentsCount + 1);
    }

    await _saveToStorage();
    return newComment;
  }

  Future<void> resetData() async {
    await _prefs?.clear();
    await init();
  }
}