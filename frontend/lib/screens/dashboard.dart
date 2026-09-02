import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../services/theme_manager.dart';
import '../widgets/app_cover_image.dart';
import '../widgets/filter_modal_sheet.dart';
import '../widgets/genre_helper.dart';
import '../widgets/platform_helper.dart';
import '../widgets/dashboard/game_card_grid.dart';
import '../widgets/dashboard/game_card_list.dart';
import '../widgets/dashboard/hero_spotlight_card.dart';
import '../widgets/dashboard/pagination_control_bar.dart';
import '../widgets/dashboard/steam_sync_dialog.dart';
import 'analytics_screen.dart';
import 'game_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final AnimationController _pulseController;

  List<Game> _filteredGames = [];
  Game? _heroGame;
  int _totalGamesCount = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSearchActive = false;
  String _searchQuery = '';
  String _selectedStatusFilter = 'Todos';
  String _selectedPlatformFilter = 'Todas';
  String _selectedGenreFilter = 'Todos';
  String _selectedSort = 'Recientes';

  // Opciones de filtro cacheadas para alto rendimiento en 60 FPS
  List<FilterOption> _cachedPlatformOptions = [];
  List<FilterOption> _cachedGenreOptions = [];

  // Dual View & Pagination & Card Sizing (Estilo Explorador de Windows)
  bool _isGridView = true;
  int _currentPage = 1;
  int _pageSize = 25; // 10, 25, 50, 100, -1 para "Todos"
  double _gridCardExtent = 220.0; // Rango: 150px (Compacto) a 380px (Enorme)

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
    unawaited(_loadPreferencesAndFetch());
  }

  Future<void> _loadPreferencesAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGridView = prefs.getBool('preferred_library_view_mode') ?? true;
    final savedPageSize = prefs.getInt('preferred_library_page_size') ?? 25;
    final savedCardSize = prefs.getDouble('preferred_library_card_size') ?? 220.0;

    if (mounted) {
      setState(() {
        _isGridView = savedGridView;
        _pageSize = savedPageSize;
        _gridCardExtent = savedCardSize;
      });
    }

    await _fetchFilterMetadata();
    await _fetchGames();
  }

  Future<void> _updateGridCardExtent(double newExtent) async {
    final clamped = newExtent.clamp(140.0, 420.0);
    setState(() {
      _gridCardExtent = clamped;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('preferred_library_card_size', clamped);
  }

  String _getCardSizeLabel(double extent) {
    if (extent <= 180) return 'Compacto';
    if (extent <= 250) return 'Normal';
    if (extent <= 330) return 'Grande';
    return 'Enorme';
  }

  PopupMenuItem<double> _buildSizeMenuItem(
      double value, String label, IconData icon) {
    final isSelected = (_gridCardExtent - value).abs() < 25;
    return PopupMenuItem<double>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? const Color(0xFFDC2626)
                : AppColors.textSecondary(context),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFFDC2626)
                  : AppColors.textPrimary(context),
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 14, color: Color(0xFFDC2626)),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Route<T> _buildFluidPageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
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

  /// Calcula metadatos de filtros una única vez o tras cambios en base de datos
  Future<void> _fetchFilterMetadata() async {
    try {
      final allGames = await DatabaseService.instance.getAllGames();
      final total = allGames.length;

      // Hero game (primer juego con estado 'Jugando')
      final playing = allGames.where((g) => g.status == 'Jugando').toList();
      final hero = playing.isNotEmpty ? playing.first : null;

      // Conteo de plataformas
      final Map<String, int> platCounts = {};
      for (final g in allGames) {
        if (g.platform != null && g.platform!.trim().isNotEmpty) {
          final p = g.platform!.trim();
          platCounts[p] = (platCounts[p] ?? 0) + 1;
        }
      }
      final sortedPlats = platCounts.keys.toList()
        ..sort((a, b) {
          final cmp = platCounts[b]!.compareTo(platCounts[a]!);
          return cmp != 0 ? cmp : a.compareTo(b);
        });

      final platOptions = sortedPlats.map((name) {
        return FilterOption(
          label: name,
          count: platCounts[name] ?? 0,
          icon: PlatformHelper.getIcon(name, size: 16, isColor: true),
          color: const Color(0xFFDC2626),
        );
      }).toList();

      // Conteo de géneros normalizados
      final Map<String, int> genreCounts = {};
      for (final g in allGames) {
        final Set<String> normalizedForGame = {};
        for (final gen in g.genres) {
          if (gen.trim().isNotEmpty) {
            normalizedForGame.add(GenreHelper.normalize(gen));
          }
        }
        for (final norm in normalizedForGame) {
          genreCounts[norm] = (genreCounts[norm] ?? 0) + 1;
        }
      }
      final sortedGenres = genreCounts.keys.toList()
        ..sort((a, b) {
          final cmp = genreCounts[b]!.compareTo(genreCounts[a]!);
          return cmp != 0 ? cmp : a.compareTo(b);
        });

      final genreOptions = sortedGenres.map((name) {
        return FilterOption(
          label: name,
          count: genreCounts[name] ?? 0,
          icon: Icon(
            GenreHelper.getIcon(name),
            size: 16,
            color: GenreHelper.getColor(name),
          ),
          color: GenreHelper.getColor(name),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _totalGamesCount = total;
          _heroGame = hero;
          _cachedPlatformOptions = platOptions;
          _cachedGenreOptions = genreOptions;
        });
      }
    } catch (e) {
      debugPrint('Error calculando metadatos de filtros: $e');
    }
  }

  /// Consulta delegada al motor SQL SQLite (WHERE, ORDER BY, NOCASE)
  Future<void> _fetchGames({
    bool forceRefresh = false,
    bool userInitiated = false,
  }) async {
    try {
      if (forceRefresh) {
        await _fetchFilterMetadata();
      }

      final results = await DatabaseService.instance.getAllGames(
        status: _selectedStatusFilter,
        platform: _selectedPlatformFilter,
        genre: _selectedGenreFilter,
        search: _searchQuery,
        sortBy: _selectedSort,
      );

      if (mounted) {
        setState(() {
          _filteredGames = results;
          _isLoading = false;
          _currentPage = 1;
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
                    'Biblioteca local actualizada (${results.length} resultados)',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
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
        setState(() => _isLoading = false);
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
    });
    unawaited(_fetchGames());
  }

  Future<void> _syncWithSteam() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = await SecureStorageService.instance.getSteamApiKey() ?? '';
    final steamId = prefs.getString('steam_user_id') ?? '';

    if (apiKey.isEmpty || steamId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Configura tu Steam API Key y Steam ID en Ajustes para sincronizar.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ajustes',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push<void>(
                context,
                _buildFluidPageRoute(const SettingsScreen()),
              ).then((_) {
                if (!mounted) return;
                unawaited(_fetchGames(forceRefresh: true));
              });
            },
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final result = await SteamSyncDialog.show(
      context: context,
      apiKey: apiKey,
      steamId: steamId,
    );

    if (!mounted) return;
    if (result != null) {
      await _fetchFilterMetadata();
      await _fetchGames();
    }
  }

  Future<void> _quickAddHours(Game game, num deltaHours) async {
    final newHours = (game.hoursPlayed ?? 0) + deltaHours;

    String finalStatus = game.status;
    DateTime? finalStartDate = game.startDate;
    DateTime? finalCompleted = game.completedDate;
    if (game.hltbMain != null &&
        game.hltbMain! > 0 &&
        newHours >= game.hltbMain! &&
        game.status != 'Jugado') {
      finalStatus = 'Jugado';
      finalCompleted ??= DateTime.now();
    } else if (game.status == 'Por jugar' && newHours >= 1.0) {
      finalStatus = 'Jugando';
      finalStartDate ??= DateTime.now();
    }

    final updated = game.copyWith(
      hoursPlayed: newHours,
      status: finalStatus,
      startDate: finalStartDate,
      completedDate: finalCompleted,
      updatedAt: DateTime.now(),
    );

    // Actualización optimista de UI
    setState(() {
      final idx = _filteredGames.indexWhere((g) => g.id == game.id);
      if (idx != -1) {
        _filteredGames[idx] = updated;
      }
      if (_heroGame?.id == game.id) {
        _heroGame = updated;
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '+${deltaHours}h registradas en ${game.title}',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      await DatabaseService.instance.updateGame(updated);
    } catch (e) {
      debugPrint('Error actualizando horas en SQLite: $e');
    }
  }

  Future<void> _quickChangeStatus(Game game, String newStatus) async {
    DateTime? completedDate = game.completedDate;
    if (newStatus == 'Jugado' && completedDate == null) {
      completedDate = DateTime.now();
    }

    final updated = game.copyWith(
      status: newStatus,
      completedDate: completedDate,
      updatedAt: DateTime.now(),
    );

    setState(() {
      final idx = _filteredGames.indexWhere((g) => g.id == game.id);
      if (idx != -1) {
        _filteredGames[idx] = updated;
      }
    });

    try {
      await DatabaseService.instance.updateGame(updated);
      await _fetchFilterMetadata();
      await _fetchGames();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${game.title} marcado como "$newStatus"',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error actualizando estado en SQLite: $e');
    }
  }

  void _showQuickActionMenu(Game game) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121215),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF27272A)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppCoverImage(
                        coverUrl: game.coverUrl,
                        width: 44,
                        height: 56,
                        fit: BoxFit.cover,
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
                    _buildStatusQuickButton(
                        game, 'Por jugar', const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _buildStatusQuickButton(
                        game, 'Jugando', const Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    _buildStatusQuickButton(
                        game, 'Jugado', const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 16),

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
                    Navigator.pop(ctx);
                    unawaited(_quickAddHours(game, 1));
                  },
                ),

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
                    Navigator.pop(ctx);
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute<bool>(
                        builder: (_) => GameDetailScreen(game: game),
                      ),
                    );
                    if (!mounted) return;
                    if (res == true) await _fetchGames(forceRefresh: true);
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
                unawaited(_quickChangeStatus(game, status));
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
                  fontSize: 15,
                  color: AppColors.textPrimary(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar en tu biblioteca (SQL)...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary(context),
                  ),
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
                            setState(() => _searchQuery = '');
                            unawaited(_fetchGames());
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                  unawaited(_fetchGames());
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
                  unawaited(_fetchGames());
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
                onPressed: () => Navigator.push<void>(
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
                    await ThemeManager.instance.toggleTheme();
                  } else if (val == 'steam_sync') {
                    await _syncWithSteam();
                  } else if (val == 'refresh') {
                    setState(() => _isRefreshing = true);
                    await _fetchGames(forceRefresh: true, userInitiated: true);
                  } else if (val == 'settings') {
                    final result = await Navigator.push<bool>(
                      context,
                      _buildFluidPageRoute(const SettingsScreen()),
                    );
                    if (!mounted) return;
                    if (result == true) await _fetchGames(forceRefresh: true);
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
                    value: 'steam_sync',
                    child: Row(
                      children: [
                        const Icon(Icons.sync_rounded,
                            size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Text(
                          'Sincronizar Steam',
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
                          'Recargar Local',
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
                          strokeWidth: 2,
                          color: Color(0xFFDC2626),
                        ),
                      )
                    : const Icon(Icons.sync_rounded,
                        color: Color(0xFFDC2626)),
                tooltip: 'Sincronizar con Steam',
                onPressed: _isRefreshing ? null : () => unawaited(_syncWithSteam()),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFFDC2626)),
                tooltip: 'Estadísticas',
                onPressed: () => Navigator.push<void>(
                  context,
                  _buildFluidPageRoute(const AnalyticsScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded,
                    color: Color(0xFF71717A)),
                tooltip: 'Configuración',
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    _buildFluidPageRoute(const SettingsScreen()),
                  );
                  if (!mounted) return;
                  if (result == true) await _fetchGames(forceRefresh: true);
                },
              ),
            ],
          ],
        ],
      ),
      body: Column(
        children: [
          // Hero Spotlight "Jugando Ahora"
          if (!_isSearchActive && _heroGame != null && !_isLoading)
            HeroSpotlightCard(
              game: _heroGame!,
              pulseAnimation: _pulseController,
              onTap: () async {
                final res = await Navigator.push<bool>(
                  context,
                  _buildFluidPageRoute(
                    GameDetailScreen(game: _heroGame!),
                  ),
                );
                if (!mounted) return;
                if (res == true) await _fetchGames(forceRefresh: true);
              },
              onQuickAddHours: () => unawaited(_quickAddHours(_heroGame!, 1)),
            ),

          // Toolbar de Filtros (Responsive: 2 filas en Mobile, 1 fila en Desktop)
          if (isMobileFilter)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

          // Subheader: contador de juegos y switch Grid/Lista
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_filteredGames.length} de $_totalGamesCount juegos',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFA1A1AA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
                            color: const Color(0xFFDC2626).withOpacity(0.3),
                          ),
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
                    // Dual View Mode Switcher
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
                    if (_isGridView) ...[
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 14),
                              tooltip: 'Reducir tamaño de tarjetas (Ctrl -)',
                              splashRadius: 16,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                  minWidth: 26, minHeight: 26),
                              color: _gridCardExtent > 150
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context)
                                      .withOpacity(0.3),
                              onPressed: _gridCardExtent > 150
                                  ? () => _updateGridCardExtent(
                                      _gridCardExtent - 35)
                                  : null,
                            ),
                            PopupMenuButton<double>(
                              tooltip: 'Tamaño de visualización (Estilo Windows)',
                              color: AppColors.surface(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: AppColors.border(context)),
                              ),
                              onSelected: _updateGridCardExtent,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.photo_size_select_actual_outlined,
                                      size: 13,
                                      color: AppColors.textPrimary(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getCardSizeLabel(_gridCardExtent),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    Icon(Icons.arrow_drop_down_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary(context)),
                                  ],
                                ),
                              ),
                              itemBuilder: (ctx) => [
                                _buildSizeMenuItem(
                                    160.0,
                                    'Iconos compactos (Pequeño)',
                                    Icons.view_module_rounded),
                                _buildSizeMenuItem(
                                    220.0,
                                    'Iconos medianos (Normal)',
                                    Icons.grid_view_rounded),
                                _buildSizeMenuItem(
                                    290.0,
                                    'Iconos grandes',
                                    Icons.window_rounded),
                                _buildSizeMenuItem(
                                    380.0,
                                    'Iconos muy grandes (Detallado)',
                                    Icons.crop_portrait_rounded),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 14),
                              tooltip: 'Aumentar tamaño de tarjetas (Ctrl +)',
                              splashRadius: 16,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                  minWidth: 26, minHeight: 26),
                              color: _gridCardExtent < 380
                                  ? AppColors.textPrimary(context)
                                  : AppColors.textSecondary(context)
                                      .withOpacity(0.3),
                              onPressed: _gridCardExtent < 380
                                  ? () => _updateGridCardExtent(
                                      _gridCardExtent + 35)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Main View: GridView / ListView con animación escalonada y soporte de zoom con Ctrl + Scroll
          Expanded(
            child: Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent &&
                    HardwareKeyboard.instance.isControlPressed &&
                    _isGridView) {
                  if (event.scrollDelta.dy < 0) {
                    _updateGridCardExtent(_gridCardExtent + 25);
                  } else if (event.scrollDelta.dy > 0) {
                    _updateGridCardExtent(_gridCardExtent - 25);
                  }
                }
              },
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
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: _gridCardExtent,
                                    childAspectRatio: 0.62,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                                  itemCount: _paginatedGames.length,
                                  itemBuilder: (context, index) {
                                  final game = _paginatedGames[index];
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey('grid_${game.id}_$index'),
                                    tween:
                                        Tween<double>(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                        milliseconds:
                                            300 + ((index % 10) * 30)),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, animValue, child) {
                                      return Opacity(
                                        opacity: animValue,
                                        child: Transform.translate(
                                          offset: Offset(
                                              0, 14 * (1.0 - animValue)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: GameCardGrid(
                                      game: game,
                                      onTap: () async {
                                        final res = await Navigator.push<bool>(
                                          context,
                                          _buildFluidPageRoute(
                                            GameDetailScreen(game: game),
                                          ),
                                        );
                                        if (!mounted) return;
                                        if (res == true) {
                                          await _fetchGames(forceRefresh: true);
                                        }
                                      },
                                      onLongPress: () =>
                                          _showQuickActionMenu(game),
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                itemCount: _paginatedGames.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final game = _paginatedGames[index];
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey('list_${game.id}_$index'),
                                    tween:
                                        Tween<double>(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                        milliseconds:
                                            250 + ((index % 10) * 25)),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, animValue, child) {
                                      return Opacity(
                                        opacity: animValue,
                                        child: Transform.translate(
                                          offset: Offset(
                                              0, 10 * (1.0 - animValue)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: GameCardList(
                                      game: game,
                                      onTap: () async {
                                        final res = await Navigator.push<bool>(
                                          context,
                                          _buildFluidPageRoute(
                                            GameDetailScreen(game: game),
                                          ),
                                        );
                                        if (!mounted) return;
                                        if (res == true) {
                                          await _fetchGames(forceRefresh: true);
                                        }
                                      },
                                      onLongPress: () =>
                                          _showQuickActionMenu(game),
                                      onQuickAddHours: () =>
                                          unawaited(_quickAddHours(game, 1)),
                                    ),
                                  );
                                },
                              ),
                  ),
          ),

          // Barra de Paginación Desacoplada
          PaginationControlBar(
            totalItems: _filteredGames.length,
            currentPage: _currentPage,
            pageSize: _pageSize,
            totalPages: _totalPages,
            onPageChanged: (newPage) =>
                setState(() => _currentPage = newPage),
            onPageSizeChanged: _changePageSize,
          ),
        ],
      ),
      floatingActionButton: isMobileFilter
          ? FloatingActionButton(
              onPressed: () async {
                final res = await Navigator.push<bool>(
                  context,
                  _buildFluidPageRoute(const SearchScreen()),
                );
                if (!mounted) return;
                if (res == true) await _fetchGames(forceRefresh: true);
              },
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              tooltip: 'Añadir juego',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                final res = await Navigator.push<bool>(
                  context,
                  _buildFluidPageRoute(const SearchScreen()),
                );
                if (!mounted) return;
                if (res == true) await _fetchGames(forceRefresh: true);
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
          setState(() => _selectedStatusFilter = label);
          unawaited(_fetchGames());
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
          options: _cachedPlatformOptions,
          allLabel: 'Todas',
          onSelected: (val) {
            setState(() => _selectedPlatformFilter = val);
            unawaited(_fetchGames());
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
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFiltered) ...[
              PlatformHelper.getIcon(_selectedPlatformFilter,
                  size: 14, isColor: true),
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
          options: _cachedGenreOptions,
          allLabel: 'Todos',
          onSelected: (val) {
            setState(() => _selectedGenreFilter = val);
            unawaited(_fetchGames());
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
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
          items: ['Recientes', 'A-Z', 'Z-A', 'Horas (Mayor)', 'Calificación']
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
              setState(() => _selectedSort = val);
              unawaited(_fetchGames());
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
              _activeFiltersCount > 1
                  ? 'Limpiar ($_activeFiltersCount)'
                  : 'Limpiar',
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
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF121215),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Column(
            children: [
              const Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
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
