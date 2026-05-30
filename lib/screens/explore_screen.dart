import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/colors.dart';
import '../utils/text_styles.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/season.dart';
import '../models/user.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedTag;
  bool _isLoading = true;
  bool _isSearching = false;

  List<Season> _recommendedSeasons = [];
  List<Season> _allSeasons = [];
  List<Season> _searchSeasonResults = [];
  List<User> _searchCreatorResults = [];

  static const Map<String, String> _tagLabels = {
    'fitness': 'Fitness & Gym',
    'coches': 'Coches & Motor',
    'viajes': 'Viajes & Aventura',
    'gaming': 'Gaming',
    'cocina': 'Cocina & Food',
    'arte': 'Arte & Diseño',
    'musica': 'Música',
    'programacion': 'Tech',
    'moda': 'Moda',
    'deportes': 'Deportes',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _authService.currentUser?.uid;
      final results = await Future.wait([
        if (userId != null)
          _firestoreService.getRecommendedSeasons(userId)
        else
          Future.value(<Season>[]),
        _firestoreService.getAllActiveSeasons(limit: 40),
      ]);
      _recommendedSeasons = results[0];
      _allSeasons = results[1];
    } catch (e) {
      print('❌ Error cargando Explore: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onSearchChanged(String value) async {
    final trimmed = value.trim();
    if (trimmed == _searchQuery) return;

    setState(() => _searchQuery = trimmed);

    if (trimmed.isEmpty) {
      setState(() {
        _searchSeasonResults = [];
        _searchCreatorResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await Future.wait([
        _firestoreService.searchSeasons(trimmed),
        _firestoreService.searchCreators(trimmed),
      ]);
      if (mounted) {
        setState(() {
          _searchSeasonResults = results[0] as List<Season>;
          _searchCreatorResults = results[1] as List<User>;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('❌ Error buscando: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : _buildDiscovery(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: AppTextStyles.body1,
        decoration: InputDecoration(
          hintText: 'Buscar series, creadores...',
          hintStyle: AppTextStyles.inputHint,
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ───────────────── DISCOVERY ─────────────────

  Widget _buildDiscovery() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (_recommendedSeasons.isNotEmpty) ...[
            Text('Para ti', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _recommendedSeasons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildCompactCard(_recommendedSeasons[index]),
              ),
            ),
            const SizedBox(height: 28),
          ],
          Text('Categorías', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _buildCategoryChips(),
          const SizedBox(height: 28),
          Text(
            _selectedTag != null
                ? (_tagLabels[_selectedTag] ?? 'Descubrir')
                : 'Descubrir',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 12),
          _buildSeasonsList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tagLabels.entries.map((entry) {
        final isSelected = _selectedTag == entry.key;
        return GestureDetector(
          onTap: () => setState(
              () => _selectedTag = isSelected ? null : entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              entry.value,
              style: AppTextStyles.caption.copyWith(
                fontSize: 13,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Season> get _filteredSeasons {
    if (_selectedTag == null) return _allSeasons;
    // When a tag is selected, use recommendations that match
    // (since seasons don't have tags directly, we use the recommended list
    // which already came from tag-matching creators)
    if (_recommendedSeasons.isNotEmpty) return _recommendedSeasons;
    return _allSeasons;
  }

  Widget _buildSeasonsList() {
    final seasons = _filteredSeasons;
    if (seasons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.movie_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('No hay contenido disponible',
                style: AppTextStyles.body2),
          ],
        ),
      );
    }
    return Column(
      children: seasons.map(_buildSeasonTile).toList(),
    );
  }

  Widget _buildCompactCard(Season season) {
    final img = season.imageUrl ?? season.thumbnailUrl;
    return GestureDetector(
      onTap: () => context.push('/series/${season.id}'),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.cardBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: img != null
                  ? Image.network(img,
                      width: 140,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(140, 130))
                  : _imagePlaceholder(140, 130),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  season.name,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonTile(Season season) {
    final img = season.imageUrl ?? season.thumbnailUrl;
    return GestureDetector(
      onTap: () => context.push('/series/${season.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10)),
              child: img != null
                  ? Image.network(img,
                      width: 100,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(100, 70))
                  : _imagePlaceholder(100, 70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    season.name,
                    style: AppTextStyles.body1
                        .copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Día ${season.currentDay}/${season.totalDays}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right,
                  color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── SEARCH RESULTS ─────────────────

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final hasResults =
        _searchSeasonResults.isNotEmpty || _searchCreatorResults.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Sin resultados para "$_searchQuery"',
                style: AppTextStyles.body1),
            const SizedBox(height: 8),
            Text('Intenta con otro término',
                style: AppTextStyles.body2),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (_searchSeasonResults.isNotEmpty) ...[
          Text('Series', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ..._searchSeasonResults.map(_buildSeasonTile),
          const SizedBox(height: 24),
        ],
        if (_searchCreatorResults.isNotEmpty) ...[
          Text('Creadores', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          ..._searchCreatorResults.map(_buildCreatorTile),
        ],
      ],
    );
  }

  Widget _buildCreatorTile(User creator) {
    return GestureDetector(
      onTap: () => context.push('/user-profile/${creator.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Image.network(
                creator.avatarUrl ?? 'https://i.pravatar.cc/100',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: AppColors.cardBackground,
                  child: const Icon(Icons.person,
                      color: AppColors.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(creator.name,
                      style: AppTextStyles.body1
                          .copyWith(fontWeight: FontWeight.bold)),
                  if (creator.username != null)
                    Text(creator.username!,
                        style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  // ───────────────── HELPERS ─────────────────

  Widget _imagePlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: Colors.grey.shade900,
      child: const Icon(Icons.movie, color: AppColors.textTertiary),
    );
  }
}
