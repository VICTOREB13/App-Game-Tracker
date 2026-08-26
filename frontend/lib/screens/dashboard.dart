import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/game.dart';
import '../services/notion_service.dart';
import '../services/notion_parser.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'game_detail_screen.dart';
import 'analytics_screen.dart';
import '../widgets/platform_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _notion = NotionService.instance;
  final _searchController = TextEditingController();

  List<Game> _games = [];
  List<Game> _filteredGames = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSearchActive = false;
  String _searchQuery = '';
  String _selectedStatusFilter = 'Todos';
  String _selectedPlatformFilter = 'Todas';
  String _selectedGenreFilter = 'Todos';
  String _selectedSort = 'Recientes';

  final List<String> _statusFilters = [
    'Todos',
    'Jugando',
    'Por jugar',
    'Jugado',
  ];

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGames({bool forceRefresh = false}) async {
    try {
      final pages = await _notion.getGames(useCache: !forceRefresh);
      final loadedGames =
          pages.map((page) => Game.fromNotionPage(page)).toList();

      if (mounted) {
        setState(() {
          _games = loadedGames;
          _applyFilters();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar juegos de Notion: $e'),
            backgroundColor: const Color(0xFFFF2D78),
          ),
        );
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();

    setState(() {
      _filteredGames = _games.where((g) {
        // Status filter
        final matchesStatus = _selectedStatusFilter == 'Todos' ||
            g.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

        // Platform filter
        final matchesPlatform = _selectedPlatformFilter == 'Todas' ||
            (g.platform != null &&
                g.platform!.toLowerCase() ==
                    _selectedPlatformFilter.toLowerCase());

        // Genre filter
        final matchesGenre = _selectedGenreFilter == 'Todos' ||
            g.genres.any((gen) =>
                gen.toLowerCase() == _selectedGenreFilter.toLowerCase());

        // Search query filter (matches title, platform, or genres)
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          final titleMatch = g.title.toLowerCase().contains(query);
          final platformMatch =
              g.platform != null && g.platform!.toLowerCase().contains(query);
          final genreMatch = g.genres
              .any((genre) => genre.toLowerCase().contains(query));
          matchesQuery = titleMatch || platformMatch || genreMatch;
        }

        return matchesStatus &&
            matchesPlatform &&
            matchesGenre &&
            matchesQuery;
      }).toList();

      if (_selectedSort == 'A-Z') {
        _filteredGames.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      }
      // "Recientes" maintains the Notion last_edited_time DESC sorting
    });
  }

  List<String> get _availablePlatformsInLibrary {
    final Set<String> platforms = {'Todas'};
    for (var g in _games) {
      if (g.platform != null && g.platform!.isNotEmpty) {
        platforms.add(g.platform!);
      }
    }
    return platforms.toList();
  }

  List<String> get _availableGenresInLibrary {
    final Set<String> genres = {'Todos'};
    for (var g in _games) {
      for (var gen in g.genres) {
        if (gen.isNotEmpty) genres.add(gen);
      }
    }
    return genres.toList();
  }

  List<Game> get _currentlyPlayingGames {
    return _games.where((g) => g.status == 'Jugando').toList();
  }

  bool get _isAnyFilterActive =>
      _selectedStatusFilter != 'Todos' ||
      _selectedPlatformFilter != 'Todas' ||
      _selectedGenreFilter != 'Todos' ||
      _searchQuery.isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      _selectedStatusFilter = 'Todos';
      _selectedPlatformFilter = 'Todas';
      _selectedGenreFilter = 'Todos';
      _selectedSort = 'Recientes';
      _searchQuery = '';
      _searchController.clear();
      _isSearchActive = false;
      _applyFilters();
    });
  }

  // Quick Action: Add 1 hour to a game directly
  Future<void> _quickAddHours(Game game, num deltaHours) async {
    final newHours = (game.hoursPlayed ?? 0) + deltaHours;

    // Optimistic UI update
    setState(() {
      final idx = _games.indexWhere((g) => g.notionPageId == game.notionPageId);
      if (idx != -1) {
        _games[idx] = _games[idx].copyWith(hoursPlayed: newHours);
        _applyFilters();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+${deltaHours}h registradas en ${game.title}',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await _notion.updatePage(
        game.notionPageId,
        {'Horas Jugadas': NotionParser.buildNumber(newHours)},
      );
    } catch (e) {
      debugPrint('Error updating hours in Notion: $e');
    }
  }

  // Quick Action: Change game status
  Future<void> _quickChangeStatus(Game game, String newStatus) async {
    DateTime? completedDate = game.completedDate;
    if (newStatus == 'Jugado' && completedDate == null) {
      completedDate = DateTime.now();
    }

    setState(() {
      final idx = _games.indexWhere((g) => g.notionPageId == game.notionPageId);
      if (idx != -1) {
        _games[idx] = _games[idx].copyWith(
          status: newStatus,
          completedDate: completedDate,
        );
        _applyFilters();
      }
    });

    try {
      final props = <String, dynamic>{
        'Estado': NotionParser.buildStatus(newStatus),
      };
      if (completedDate != null) {
        props['Fecha de Culminación (primera campaña)'] =
            NotionParser.buildDate(completedDate);
      }
      await _notion.updatePage(game.notionPageId, props);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${game.title} marcado como "$newStatus"',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating status in Notion: $e');
    }
  }

  // Contextual Long-Press Modal
  void _showQuickActionMenu(Game game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121215),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF27272A)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game Header in Modal
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: game.coverUrl!,
                              width: 44,
                              height: 56,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 44,
                              height: 56,
                              color: const Color(0xFF18181B),
                              child: const Icon(Icons.sports_esports_rounded,
                                  color: Color(0xFF71717A)),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFAFAFA),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${game.platform ?? 'Sin plataforma'} • ${game.hoursPlayed ?? 0}h jugadas',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFFA1A1AA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF27272A)),
                const SizedBox(height: 8),

                // Quick Status Switcher
                Text(
                  'Cambiar Estado',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA1A1AA),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusQuickButton(game, 'Por jugar', const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _buildStatusQuickButton(game, 'Jugando', const Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    _buildStatusQuickButton(game, 'Jugado', const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Log Action
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timer_rounded,
                        color: Color(0xFFDC2626), size: 20),
                  ),
                  title: Text(
                    'Registrar sesión (+1 hora)',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFFFAFAFA)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _quickAddHours(game, 1);
                  },
                ),

                // Full Edit Action
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Color(0xFFFAFAFA), size: 20),
                  ),
                  title: Text(
                    'Ver detalle / Editar ficha',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: const Color(0xFFFAFAFA)),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameDetailScreen(game: game),
                      ),
                    );
                    if (res == true) _fetchGames(forceRefresh: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusQuickButton(Game game, String status, Color color) {
    final isCurrent = game.status == status;
    return Expanded(
      child: InkWell(
        onTap: isCurrent
            ? null
            : () {
                Navigator.pop(context);
                _quickChangeStatus(game, status);
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isCurrent ? color.withOpacity(0.2) : const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent ? color : const Color(0xFF27272A),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent ? color : const Color(0xFFA1A1AA),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playingGames = _currentlyPlayingGames;

    return Scaffold(
      appBar: AppBar(
        title: _isSearchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(
                    fontSize: 15, color: const Color(0xFFFAFAFA)),
                decoration: InputDecoration(
                  hintText: 'Buscar en tu biblioteca...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF71717A)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFFDC2626), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFFA1A1AA), size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFilters();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _applyFilters();
                  });
                },
              )
            : Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'VE',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Victor ',
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFAFAFA),
                          ),
                        ),
                        TextSpan(
                          text: 'Engineer',
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              color: _isSearchActive
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFFAFAFA),
            ),
            tooltip: _isSearchActive ? 'Cerrar búsqueda' : 'Buscar juegos',
            onPressed: () {
              setState(() {
                if (_isSearchActive) {
                  _isSearchActive = false;
                  _searchController.clear();
                  _searchQuery = '';
                  _applyFilters();
                } else {
                  _isSearchActive = true;
                }
              });
            },
          ),
          if (!_isSearchActive) ...[
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFDC2626)),
                    )
                  : const Icon(Icons.refresh_rounded, color: Color(0xFFA1A1AA)),
              tooltip: 'Refrescar de Notion',
              onPressed: _isRefreshing
                  ? null
                  : () {
                      setState(() => _isRefreshing = true);
                      _fetchGames(forceRefresh: true);
                    },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFFDC2626)),
              tooltip: 'Estadísticas',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Color(0xFF71717A)),
              tooltip: 'Configuración',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                if (result == true) _fetchGames(forceRefresh: true);
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Hero Spotlight "Jugando Ahora" (if any active games and not actively searching)
          if (!_isSearchActive && playingGames.isNotEmpty && !_isLoading)
            _buildHeroSpotlight(playingGames.first),

          // Unified Filter Toolbar (Single Row: Statuses | Platform | Genre | Sort | Clear)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ..._statusFilters.map(_buildFilterChip),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFF1C2237),
                  ),
                  const SizedBox(width: 8),
                  _buildPlatformDropdown(),
                  const SizedBox(width: 8),
                  _buildGenreDropdown(),
                  const SizedBox(width: 8),
                  _buildSortDropdown(),
                  if (_isAnyFilterActive) ...[
                    const SizedBox(width: 8),
                    _buildClearFiltersButton(),
                  ],
                ],
              ),
            ),
          ),

          // Search indicator & Game count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredGames.length} de ${_games.length} juegos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7394),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFF00F0FF).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Filtro: "$_searchQuery"',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF00F0FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Grid with Responsive Breakpoints (Mobile, Tablet, Desktop)
          Expanded(
            child: _isLoading
                ? _buildSkeletonGrid()
                : RefreshIndicator(
                    color: const Color(0xFF00F0FF),
                    backgroundColor: const Color(0xFF141927),
                    onRefresh: () => _fetchGames(forceRefresh: true),
                    child: _filteredGames.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchQuery.isNotEmpty
                                        ? Icons.search_off_rounded
                                        : Icons.gamepad_outlined,
                                    size: 64,
                                    color: const Color(0xFF6B7394)
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No se encontraron juegos para "$_searchQuery"'
                                        : 'No hay juegos con los filtros seleccionados',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF6B7394),
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_isAnyFilterActive) ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _clearAllFilters,
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 16),
                                      label: const Text('Restablecer filtros'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFDC2626),
                                        side: const BorderSide(
                                            color: Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: _filteredGames.length,
                            itemBuilder: (context, index) {
                              final game = _filteredGames[index];
                              return GestureDetector(
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GameDetailScreen(game: game),
                                    ),
                                  );
                                  if (res == true) {
                                    _fetchGames(forceRefresh: true);
                                  }
                                },
                                onLongPress: () => _showQuickActionMenu(game),
                                child: _GameCard(game: game),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
          if (res == true) _fetchGames(forceRefresh: true);
        },
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Añadir',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Hero Spotlight Card for Currently Playing game
  Widget _buildHeroSpotlight(Game game) {
    final hours = game.hoursPlayed ?? 0;
    final hltb = game.hltbMain ?? 0;
    final progress = hltb > 0 ? (hours / hltb).clamp(0.0, 1.0) : 0.0;
    final percentText = (progress * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background subtle backdrop
          if (game.coverUrl != null && game.coverUrl!.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: CachedNetworkImage(
                  imageUrl: game.coverUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: game.coverUrl!,
                          width: 60,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 60,
                          height: 80,
                          color: const Color(0xFF27272A),
                          child: const Icon(Icons.sports_esports_rounded,
                              color: Color(0xFF71717A)),
                        ),
                ),
                const SizedBox(width: 14),
                // Details & Progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: const Color(0xFFDC2626).withOpacity(0.4),
                                  width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'JUGANDO AHORA',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDC2626),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (game.platform != null)
                            PlatformHelper.buildBadge(game.platform!),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFAFAFA),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Progress Bar & Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            hltb > 0
                                ? '${hours % 1 == 0 ? hours.toInt() : hours}h / ${hltb % 1 == 0 ? hltb.toInt() : hltb.toStringAsFixed(1)}h HLTB'
                                : '${hours % 1 == 0 ? hours.toInt() : hours}h jugadas',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFFA1A1AA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (hltb > 0)
                            Text(
                              '$percentText%',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: const Color(0xFF27272A),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Quick +1h button
                ElevatedButton(
                  onPressed: () => _quickAddHours(game, 1),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(42, 42),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 16),
                      Text(
                        '1h',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedStatusFilter == label;
    Color chipColor;
    switch (label) {
      case 'Jugando':
        chipColor = const Color(0xFFDC2626);
        break;
      case 'Por jugar':
        chipColor = const Color(0xFFF59E0B);
        break;
      case 'Jugado':
        chipColor = const Color(0xFF10B981);
        break;
      default:
        chipColor = const Color(0xFFA1A1AA);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : chipColor,
          ),
        ),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedStatusFilter = label;
            _applyFilters();
          });
        },
        selectedColor: chipColor,
        backgroundColor: chipColor.withOpacity(0.1),
        side: BorderSide(
          color: isSelected ? Colors.transparent : chipColor.withOpacity(0.3),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildPlatformDropdown() {
    final platforms = _availablePlatformsInLibrary;
    final isFiltered = _selectedPlatformFilter != 'Todas';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isFiltered
            ? const Color(0xFFDC2626).withOpacity(0.15)
            : const Color(0xFF121215),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFiltered
              ? const Color(0xFFDC2626)
              : const Color(0xFF27272A),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: platforms.contains(_selectedPlatformFilter)
              ? _selectedPlatformFilter
              : 'Todas',
          dropdownColor: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.inter(
              fontSize: 12,
              color: isFiltered
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFFAFAFA)),
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.arrow_drop_down_rounded,
                size: 20,
                color: isFiltered
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFA1A1AA)),
          ),
          items: platforms
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (p != 'Todas') ...[
                          PlatformHelper.getIcon(p, size: 14),
                          const SizedBox(width: 8),
                        ] else ...[
                          const Icon(Icons.videogame_asset_outlined,
                              size: 14, color: Color(0xFF71717A)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          p == 'Todas' ? 'Plataforma: Todas' : p,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: p == _selectedPlatformFilter
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: p == _selectedPlatformFilter
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFFAFAFA),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedPlatformFilter = val;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildGenreDropdown() {
    final genres = _availableGenresInLibrary;
    final isFiltered = _selectedGenreFilter != 'Todos';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isFiltered
            ? const Color(0xFFDC2626).withOpacity(0.15)
            : const Color(0xFF121215),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFiltered
              ? const Color(0xFFDC2626)
              : const Color(0xFF27272A),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: genres.contains(_selectedGenreFilter)
              ? _selectedGenreFilter
              : 'Todos',
          dropdownColor: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.inter(
              fontSize: 12,
              color: isFiltered
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFFAFAFA)),
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.arrow_drop_down_rounded,
                size: 20,
                color: isFiltered
                    ? const Color(0xFFDC2626)
                    : const Color(0xFFA1A1AA)),
          ),
          items: genres
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 14, color: Color(0xFF71717A)),
                        const SizedBox(width: 8),
                        Text(
                          s == 'Todos' ? 'Género: Todos' : s,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: s == _selectedGenreFilter
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: s == _selectedGenreFilter
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFFAFAFA),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedGenreFilter = val;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          dropdownColor: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFFFAFAFA)),
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.sort_rounded,
                size: 16, color: Color(0xFFA1A1AA)),
          ),
          items: ['Recientes', 'A-Z']
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: GoogleFonts.inter(fontSize: 12)),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedSort = val;
                _applyFilters();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return InkWell(
      onTap: _clearAllFilters,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFDC2626).withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_rounded,
                size: 14, color: Color(0xFFDC2626)),
            const SizedBox(width: 4),
            Text(
              'Limpiar',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121215),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF18181B),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (game.status) {
      case 'Jugando':
        statusColor = const Color(0xFFDC2626);
        break;
      case 'Por jugar':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'Jugado':
        statusColor = const Color(0xFF10B981);
        break;
      default:
        statusColor = const Color(0xFFA1A1AA);
    }

    final hours = game.hoursPlayed ?? 0;
    final hltb = game.hltbMain ?? 0;
    final progress = hltb > 0 ? (hours / hltb).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF27272A),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                game.coverUrl != null && game.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: game.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF18181B),
                          child: const Center(
                            child: Icon(Icons.gamepad_rounded,
                                color: Color(0xFF71717A), size: 32),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF18181B),
                          child: const Center(
                            child: Icon(Icons.gamepad_rounded,
                                color: Color(0xFF71717A), size: 32),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF18181B),
                        child: const Center(
                          child: Icon(Icons.gamepad_rounded,
                              color: Color(0xFF71717A), size: 32),
                        ),
                      ),
                // Gradient overlay at bottom of image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 44,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xFF121215)],
                      ),
                    ),
                  ),
                ),
                // Status indicator - top right red dot
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Rating pill if available
                if (game.rating != null && game.rating!.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09090B).withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.5),
                            width: 0.5),
                      ),
                      child: Text(
                        game.rating!,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ),
                // Micro-progress bar at bottom of cover if HLTB available
                if (hltb > 0 && hours > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.transparent,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFAFAFA),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (game.platform != null &&
                              game.platform!.isNotEmpty) ...[
                            PlatformHelper.getIcon(game.platform!, size: 12),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              game.platform ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFA1A1AA),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      status: game.status,
                      color: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
