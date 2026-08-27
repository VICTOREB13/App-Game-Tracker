import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../services/notion_service.dart';
import '../services/notion_parser.dart';
import '../services/theme_manager.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'game_detail_screen.dart';
import 'analytics_screen.dart';
import '../widgets/platform_helper.dart';
import '../widgets/genre_helper.dart';
import '../widgets/filter_modal_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _notion = NotionService.instance;
  final _searchController = TextEditingController();

  late final AnimationController _pulseController;

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

  // Dual View & Pagination
  bool _isGridView = true;
  int _currentPage = 1;
  int _pageSize = 25; // 10, 25, 50, 100, -1 for "Todos"
  bool _isOffline = false;

  final List<String> _statusFilters = [
    'Todos',
    'Jugando',
    'Por jugar',
    'Jugado',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadPreferencesAndCache();
  }

  Future<void> _loadPreferencesAndCache() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGridView = prefs.getBool('preferred_library_view_mode') ?? true;
    final savedPageSize = prefs.getInt('preferred_library_page_size') ?? 25;

    // Load local disk cache immediately (0ms cold start)
    final localPages = await _notion.getLocalCache();
    if (localPages != null && localPages.isNotEmpty && mounted) {
      final loadedGames =
          localPages.map((page) => Game.fromNotionPage(page)).toList();
      setState(() {
        _isGridView = savedGridView;
        _pageSize = savedPageSize;
        _games = loadedGames;
        _applyFilters();
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _isGridView = savedGridView;
          _pageSize = savedPageSize;
        });
      }
    }

    // Fetch fresh data in background (Stale-While-Revalidate)
    _fetchGames();
  }

  Future<void> _toggleViewMode() async {
    final nextMode = !_isGridView;
    setState(() => _isGridView = nextMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preferred_library_view_mode', nextMode);
  }

  Future<void> _changePageSize(int newSize) async {
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preferred_library_page_size', newSize);
  }

  int get _totalPages {
    if (_pageSize <= 0) return 1;
    if (_filteredGames.isEmpty) return 1;
    return (_filteredGames.length / _pageSize).ceil();
  }

  List<Game> get _paginatedGames {
    if (_pageSize <= 0) return _filteredGames;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= _filteredGames.length) return [];
    final end = (start + _pageSize).clamp(0, _filteredGames.length);
    return _filteredGames.sublist(start, end);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Route _buildFluidPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }

  Future<void> _fetchGames({
    bool forceRefresh = false,
    bool userInitiated = false,
  }) async {
    final hadGamesBefore = _games.isNotEmpty;
    try {
      final pages = await _notion.getGames(
        useCache: !forceRefresh,
        forceFullSync: false,
      );
      final loadedGames =
          pages.map((page) => Game.fromNotionPage(page)).toList();

      if (mounted) {
        setState(() {
          _games = loadedGames;
          _applyFilters();
          _isLoading = false;
          _isOffline = false;
        });

        if (userInitiated) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Sincronizado con Notion (${loadedGames.length} juegos)',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
        if (userInitiated || !hadGamesBefore) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No se pudo conectar con Notion. Mostrando datos locales en caché.',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isLoading = false;
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

        // Genre filter (normalizado mediante GenreHelper)
        final matchesGenre = _selectedGenreFilter == 'Todos' ||
            GenreHelper.matches(g.genres, _selectedGenreFilter);

        // Search query filter (matches title, platform, or genres)
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          final titleMatch = g.title.toLowerCase().contains(query);
          final platformMatch =
              g.platform != null && g.platform!.toLowerCase().contains(query);
          final genreMatch = g.genres
              .any((genre) => genre.toLowerCase().contains(query) ||
                  GenreHelper.normalize(genre).toLowerCase().contains(query));
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

      _currentPage = 1;
    });
  }

  List<FilterOption> get _availablePlatformOptions {
    final Map<String, int> counts = {};
    for (var g in _games) {
      if (g.platform != null && g.platform!.trim().isNotEmpty) {
        final p = g.platform!.trim();
        counts[p] = (counts[p] ?? 0) + 1;
      }
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        final cmp = counts[b]!.compareTo(counts[a]!);
        if (cmp != 0) return cmp;
        return a.compareTo(b);
      });

    return sortedKeys.map((name) {
      return FilterOption(
        label: name,
        count: counts[name] ?? 0,
        icon: PlatformHelper.getIcon(name, size: 16, isColor: true),
        color: const Color(0xFFDC2626),
      );
    }).toList();
  }

  List<FilterOption> get _availableGenreOptions {
    final Map<String, int> counts = {};
    for (var g in _games) {
      final Set<String> normalizedForGame = {};
      for (var gen in g.genres) {
        if (gen.trim().isNotEmpty) {
          normalizedForGame.add(GenreHelper.normalize(gen));
        }
      }
      for (var norm in normalizedForGame) {
        counts[norm] = (counts[norm] ?? 0) + 1;
      }
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        final cmp = counts[b]!.compareTo(counts[a]!);
        if (cmp != 0) return cmp;
        return a.compareTo(b);
      });

    return sortedKeys.map((name) {
      return FilterOption(
        label: name,
        count: counts[name] ?? 0,
        icon: Icon(
          GenreHelper.getIcon(name),
          size: 16,
          color: GenreHelper.getColor(name),
        ),
        color: GenreHelper.getColor(name),
      );
    }).toList();
  }

  List<Game> get _currentlyPlayingGames {
    return _games.where((g) => g.status == 'Jugando').toList();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedStatusFilter != 'Todos') count++;
    if (_selectedPlatformFilter != 'Todas') count++;
    if (_selectedGenreFilter != 'Todos') count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

  bool get _isAnyFilterActive => _activeFiltersCount > 0;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;
    final isMobileFilter = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: isMobile ? 12 : null,
        title: _isSearchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Buscar en tu biblioteca...',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary(context)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFFDC2626), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textSecondary(context),
                              size: 20),
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
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(width: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Victor ',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          TextSpan(
                            text: 'Engineer',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              color: _isSearchActive
                  ? const Color(0xFFDC2626)
                  : AppColors.textPrimary(context),
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
            if (isMobile) ...[
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFFDC2626)),
                tooltip: 'Estadísticas',
                onPressed: () => Navigator.push(
                  context,
                  _buildFluidPageRoute(const AnalyticsScreen()),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.textPrimary(context)),
                tooltip: 'Más opciones',
                color: AppColors.surface(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.border(context)),
                ),
                onSelected: (val) async {
                  if (val == 'theme') {
                    ThemeManager.instance.toggleTheme();
                  } else if (val == 'refresh') {
                    setState(() => _isRefreshing = true);
                    _fetchGames(forceRefresh: true, userInitiated: true);
                  } else if (val == 'settings') {
                    final result = await Navigator.push(
                      context,
                      _buildFluidPageRoute(const SettingsScreen()),
                    );
                    if (result == true) _fetchGames(forceRefresh: true);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'theme',
                    child: Row(
                      children: [
                        Icon(
                          Theme.of(context).brightness == Brightness.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 18,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF71717A),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'Modo Claro'
                              : 'Modo Oscuro',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        const Icon(Icons.refresh_rounded,
                            size: 18, color: Color(0xFFA1A1AA)),
                        const SizedBox(width: 10),
                        Text(
                          'Sincronizar Notion',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings_rounded,
                            size: 18, color: Color(0xFF71717A)),
                        const SizedBox(width: 10),
                        Text(
                          'Configuración',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF71717A),
                ),
                tooltip: Theme.of(context).brightness == Brightness.dark
                    ? 'Cambiar a Modo Claro'
                    : 'Cambiar a Modo Oscuro',
                onPressed: () => ThemeManager.instance.toggleTheme(),
              ),
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFDC2626)),
                      )
                    : const Icon(Icons.refresh_rounded,
                        color: Color(0xFFA1A1AA)),
                tooltip: 'Refrescar de Notion',
                onPressed: _isRefreshing
                    ? null
                    : () {
                        setState(() => _isRefreshing = true);
                        _fetchGames(forceRefresh: true, userInitiated: true);
                      },
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFFDC2626)),
                tooltip: 'Estadísticas',
                onPressed: () => Navigator.push(
                  context,
                  _buildFluidPageRoute(const AnalyticsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded,
                    color: Color(0xFF71717A)),
                tooltip: 'Configuración',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    _buildFluidPageRoute(const SettingsScreen()),
                  );
                  if (result == true) _fetchGames(forceRefresh: true);
                },
              ),
            ],
          ],
        ],
      ),
      body: Column(
        children: [
          // Hero Spotlight "Jugando Ahora" (if any active games and not actively searching)
          if (!_isSearchActive && playingGames.isNotEmpty && !_isLoading)
            _buildHeroSpotlight(playingGames.first),

          // Filter Toolbar (Responsive: 2 Rows on Mobile, 1 Row on Desktop)
          if (isMobileFilter)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: Estados Principales
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ..._statusFilters.map(_buildFilterChip),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Fila 2: Selectores de Catálogo & Orden
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildPlatformFilterButton(),
                        const SizedBox(width: 8),
                        _buildGenreFilterButton(),
                        const SizedBox(width: 8),
                        _buildSortDropdown(),
                        if (_isAnyFilterActive) ...[
                          const SizedBox(width: 8),
                          _buildClearFiltersButton(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            // Unified Filter Toolbar for Desktop (Single Row)
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
                      color: AppColors.border(context),
                    ),
                    const SizedBox(width: 8),
                    _buildPlatformFilterButton(),
                    const SizedBox(width: 8),
                    _buildGenreFilterButton(),
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

          // Search indicator & Game count & View Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_filteredGames.length} de ${_games.length} juegos',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFA1A1AA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isOffline) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.4),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Modo Local',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFDC2626).withOpacity(0.3)),
                        ),
                        child: Text(
                          'Filtro: "$_searchQuery"',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Dual View Mode Toggle Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _isGridView ? null : _toggleViewMode,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isGridView
                                    ? const Color(0xFFDC2626)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.grid_view_rounded,
                                    size: 13,
                                    color: _isGridView
                                        ? Colors.white
                                        : AppColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Grid',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _isGridView
                                          ? Colors.white
                                          : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: !_isGridView ? null : _toggleViewMode,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: !_isGridView
                                    ? const Color(0xFFDC2626)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.view_list_rounded,
                                    size: 14,
                                    color: !_isGridView
                                        ? Colors.white
                                        : AppColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lista',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: !_isGridView
                                          ? Colors.white
                                          : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main View (Grid or Compact List)
          Expanded(
            child: _isLoading
                ? _buildSkeletonGrid()
                : RefreshIndicator(
                    color: const Color(0xFFDC2626),
                    backgroundColor: AppColors.surface(context),
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
                                    color: const Color(0xFF71717A)
                                        .withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No se encontraron juegos para "$_searchQuery"'
                                        : 'No hay juegos con los filtros seleccionados',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFA1A1AA),
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
                                        foregroundColor:
                                            const Color(0xFFDC2626),
                                        side: const BorderSide(
                                            color: Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : _isGridView
                            ? GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 220,
                                  childAspectRatio: 0.62,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                                itemCount: _paginatedGames.length,
                                itemBuilder: (context, index) {
                                  final game = _paginatedGames[index];
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey(
                                        'stagger_${game.notionPageId}_$index'),
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                        milliseconds:
                                            320 + ((index % 10) * 35)),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, animValue, child) {
                                      return Opacity(
                                        opacity: animValue,
                                        child: Transform.translate(
                                          offset: Offset(
                                              0, 16 * (1.0 - animValue)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _GameCard(
                                      game: game,
                                      onTap: () async {
                                        final res = await Navigator.push(
                                          context,
                                          _buildFluidPageRoute(
                                            GameDetailScreen(game: game),
                                          ),
                                        );
                                        if (res == true) {
                                          _fetchGames(forceRefresh: true);
                                        }
                                      },
                                      onLongPress: () =>
                                          _showQuickActionMenu(game),
                                    ),
                                  );
                                },
                              )
                            : _buildListView(_paginatedGames),
                  ),
          ),

          // Smart Pagination Bar
          _buildPaginationBar(),
        ],
      ),
      floatingActionButton: isMobileFilter
          ? FloatingActionButton(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  _buildFluidPageRoute(const SearchScreen()),
                );
                if (res == true) _fetchGames(forceRefresh: true);
              },
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              tooltip: 'Añadir juego',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  _buildFluidPageRoute(const SearchScreen()),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDC2626).withOpacity(isDark ? 0.35 : 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFDC2626).withOpacity(0.08)
                : Colors.black.withOpacity(0.04),
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
                opacity: isDark ? 0.15 : 0.07,
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
                          color: AppColors.surfaceSubtle(context),
                          child: Icon(Icons.sports_esports_rounded,
                              color: AppColors.textSecondary(context)),
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
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFDC2626),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFDC2626).withOpacity(
                                                0.3 + 0.6 * _pulseController.value),
                                            blurRadius: 4 + 6 * _pulseController.value,
                                            spreadRadius: 1 + 1.5 * _pulseController.value,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 6),
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
                          color: AppColors.textPrimary(context),
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
                              color: AppColors.textSecondary(context),
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
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, animProgress, child) {
                            return LinearProgressIndicator(
                              value: animProgress,
                              minHeight: 4,
                              backgroundColor: AppColors.border(context),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFDC2626)),
                            );
                          },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        chipColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark
                    ? chipColor
                    : (label == 'Todos'
                        ? AppColors.textPrimary(context)
                        : chipColor)),
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
        backgroundColor: isDark
            ? chipColor.withOpacity(0.12)
            : (isSelected ? chipColor : Colors.white),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : (isDark
                  ? chipColor.withOpacity(0.35)
                  : AppColors.border(context)),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
    );
  }

  Widget _buildPlatformFilterButton() {
    final isFiltered = _selectedPlatformFilter != 'Todas';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        FilterModalSheet.show(
          context: context,
          title: 'Plataformas',
          selectedValue: _selectedPlatformFilter,
          options: _availablePlatformOptions,
          allLabel: 'Todas',
          onSelected: (val) {
            setState(() {
              _selectedPlatformFilter = val;
              _applyFilters();
            });
          },
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isFiltered
              ? const Color(0xFFDC2626).withOpacity(isDark ? 0.15 : 0.08)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFiltered
                ? const Color(0xFFDC2626)
                : AppColors.border(context),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFiltered) ...[
              PlatformHelper.getIcon(_selectedPlatformFilter, size: 14, isColor: true),
              const SizedBox(width: 6),
            ] else ...[
              Icon(
                Icons.videogame_asset_outlined,
                size: 14,
                color: AppColors.textSecondary(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              isFiltered ? _selectedPlatformFilter : 'Plataforma: Todas',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                color: isFiltered
                    ? const Color(0xFFDC2626)
                    : AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isFiltered
                  ? const Color(0xFFDC2626)
                  : AppColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreFilterButton() {
    final isFiltered = _selectedGenreFilter != 'Todos';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        FilterModalSheet.show(
          context: context,
          title: 'Géneros',
          selectedValue: _selectedGenreFilter,
          options: _availableGenreOptions,
          allLabel: 'Todos',
          onSelected: (val) {
            setState(() {
              _selectedGenreFilter = val;
              _applyFilters();
            });
          },
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isFiltered
              ? const Color(0xFFDC2626).withOpacity(isDark ? 0.15 : 0.08)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFiltered
                ? const Color(0xFFDC2626)
                : AppColors.border(context),
            width: 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? GenreHelper.getIcon(_selectedGenreFilter)
                  : Icons.tune_rounded,
              size: 14,
              color: isFiltered
                  ? const Color(0xFFDC2626)
                  : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 6),
            Text(
              isFiltered ? _selectedGenreFilter : 'Género: Todos',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                color: isFiltered
                    ? const Color(0xFFDC2626)
                    : AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isFiltered
                  ? const Color(0xFFDC2626)
                  : AppColors.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          dropdownColor: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textPrimary(context),
          ),
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.sort_rounded,
              size: 16,
              color: AppColors.textSecondary(context),
            ),
          ),
          items: ['Recientes', 'A-Z']
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textPrimary(context))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: _clearAllFilters,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withOpacity(isDark ? 0.12 : 0.08),
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
              _activeFiltersCount > 1 ? 'Limpiar ($_activeFiltersCount)' : 'Limpiar',
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

  Widget _buildPaginationBar() {
    if (_filteredGames.isEmpty) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.border(context), width: 0.8),
        ),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Row(
        children: [
          // Items per page dropdown (Left side)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isMobile ? 'Ver:' : 'Por pág:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _pageSize,
                    dropdownColor: AppColors.surface(context),
                    icon: Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textSecondary(context), size: 18),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 25, child: Text('25')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                      DropdownMenuItem(value: 100, child: Text('100')),
                      DropdownMenuItem(value: -1, child: Text('Todos')),
                    ],
                    onChanged: (val) {
                      if (val != null) _changePageSize(val);
                    },
                  ),
                ),
              ),
            ],
          ),

          // Center Spacer
          const Spacer(),

          // Navigation controls (Centered)
          if (_pageSize > 0 && _totalPages > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  color: _currentPage > 1
                      ? AppColors.textPrimary(context)
                      : AppColors.textMuted(context),
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                  tooltip: 'Página anterior',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Text(
                    '$_currentPage / $_totalPages',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  color: _currentPage < _totalPages
                      ? AppColors.textPrimary(context)
                      : AppColors.textMuted(context),
                  onPressed: _currentPage < _totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                  tooltip: 'Página siguiente',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            )
          else
            Text(
              '${_filteredGames.length} juegos en total',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary(context),
              ),
            ),

          // Right Spacer to keep navigation centered
          const Spacer(),

          // Dedicated safety zone: ensures FloatingActionButton NEVER overlaps pagination controls!
          SizedBox(width: isMobile ? 64 : 100),
        ],
      ),
    );
  }

  Widget _buildListView(List<Game> games) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final game = games[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey('list_stagger_${game.notionPageId}_$index'),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 250 + ((index % 10) * 25)),
          curve: Curves.easeOutQuart,
          builder: (context, animValue, child) {
            return Opacity(
              opacity: animValue,
              child: Transform.translate(
                offset: Offset(0, 10 * (1.0 - animValue)),
                child: child,
              ),
            );
          },
          child: _GameListRow(
            game: game,
            onTap: () async {
              final res = await Navigator.push(
                context,
                _buildFluidPageRoute(
                  GameDetailScreen(game: game),
                ),
              );
              if (res == true) _fetchGames(forceRefresh: true);
            },
            onLongPress: () => _showQuickActionMenu(game),
            onQuickAddHours: () => _quickAddHours(game, 1),
          ),
        );
      },
    );
  }
}

class _GameListRow extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onQuickAddHours;

  const _GameListRow({
    required this.game,
    required this.onTap,
    required this.onLongPress,
    required this.onQuickAddHours,
  });

  @override
  State<_GameListRow> createState() => _GameListRowState();
}

class _GameListRowState extends State<_GameListRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceSubtle(context)
                : AppColors.surface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFDC2626).withOpacity(0.5)
                  : AppColors.border(context),
              width: 1,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: const Color(0xFFDC2626).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail cover with Hero
              Hero(
                tag: 'game-cover-${game.notionPageId}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: game.coverUrl != null && game.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: game.coverUrl!,
                          width: 36,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 36,
                            height: 48,
                            color: AppColors.border(context),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 36,
                            height: 48,
                            color: AppColors.border(context),
                            child: Icon(Icons.gamepad_rounded,
                                size: 16,
                                color: AppColors.textSecondary(context)),
                          ),
                        )
                      : Container(
                          width: 36,
                          height: 48,
                          color: AppColors.border(context),
                          child: Icon(Icons.gamepad_rounded,
                              size: 16,
                              color: AppColors.textSecondary(context)),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Platform/Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      game.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isHovered
                            ? const Color(0xFFDC2626)
                            : AppColors.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (game.platform != null &&
                            game.platform!.isNotEmpty) ...[
                          PlatformHelper.getIcon(game.platform!, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            game.platform!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFFA1A1AA),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _StatusBadge(status: game.status, color: statusColor),
                        if (game.rating != null &&
                            game.rating!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            game.rating!,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Hours / HLTB Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hltb > 0
                        ? '${hours % 1 == 0 ? hours.toInt() : hours}h / ${hltb % 1 == 0 ? hltb.toInt() : hltb.toStringAsFixed(1)}h'
                        : '${hours % 1 == 0 ? hours.toInt() : hours}h',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFA1A1AA),
                    ),
                  ),
                  if (hltb > 0) ...[
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: const Color(0xFF27272A),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),

              // Quick +1h button
              InkWell(
                onTap: widget.onQuickAddHours,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '+1h',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final Game game;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GameCard({
    required this.game,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFFDC2626).withOpacity(0.7)
                    : AppColors.border(context),
                width: _isHovered ? 1.2 : 1,
              ),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.22),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  )
                else if (Theme.of(context).brightness == Brightness.dark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image with Hero
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'game-cover-${game.notionPageId}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(13)),
                          child: AnimatedScale(
                            scale: _isHovered ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: game.coverUrl != null &&
                                    game.coverUrl!.isNotEmpty
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
                                    errorWidget: (context, url, error) =>
                                        Container(
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
                          ),
                        ),
                      ),
                      // Gradient overlay at bottom of image
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.surface(context)
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Status indicator - top right dot with glow
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
                              color: const Color(0xFF09090B).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      const Color(0xFFF59E0B).withOpacity(0.5),
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
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, animProg, _) {
                              return LinearProgressIndicator(
                                value: animProg,
                                minHeight: 3,
                                backgroundColor: Colors.transparent,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(statusColor),
                              );
                            },
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
                          color: _isHovered
                              ? const Color(0xFFDC2626)
                              : AppColors.textPrimary(context),
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
                                  PlatformHelper.getIcon(game.platform!,
                                      size: 12),
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
          ),
        ),
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
