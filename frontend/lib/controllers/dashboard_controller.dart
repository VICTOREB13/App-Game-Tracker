import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../services/database_service.dart';
import '../views/widgets/dashboard/filter_metadata_helper.dart';
import '../views/widgets/filter_modal_sheet.dart';

/// Controlador del Dashboard bajo el patrón arquitectónico MVC.
///
/// Encapsula el estado de la biblioteca de videojuegos, paginación,
/// filtros activos, opciones de visualización/zoom y operaciones de actualización rápida,
/// desacoplando la capa de presentación de [DatabaseService] y [SharedPreferences].
class DashboardController extends ChangeNotifier {
  final DatabaseService _dbService;
  SharedPreferences? _prefs;

  // Claves para persistencia de preferencias de interfaz
  static const String keyViewMode = 'preferred_library_view_mode';
  static const String keyPageSize = 'preferred_library_page_size';
  static const String keyCardSize = 'preferred_library_card_size';

  // --- Estado de Carga y Datos ---
  List<Game> _filteredGames = [];
  Game? _heroGame;
  int _totalGamesCount = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // --- Filtros Activos ---
  String _searchQuery = '';
  String _statusFilter = 'Todos';
  String _platformFilter = 'Todas';
  String _genreFilter = 'Todos';
  String _sortOption = 'Recientes';
  List<FilterOption> _platformOptions = [];
  List<FilterOption> _genreOptions = [];

  // --- Paginación ---
  int _currentPage = 1;
  int _pageSize = 25;

  // --- Visualización y Zoom ---
  bool _isGridView = true;
  double _gridCardExtent = 220.0;

  DashboardController({
    DatabaseService? dbService,
    SharedPreferences? prefs,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _prefs = prefs;

  // ===========================================================================
  // Getters Públicos
  // ===========================================================================

  List<Game> get filteredGames => List.unmodifiable(_filteredGames);
  Game? get heroGame => _heroGame;
  int get totalGamesCount => _totalGamesCount;
  int get filteredGamesCount => _filteredGames.length;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get platformFilter => _platformFilter;
  String get genreFilter => _genreFilter;
  String get sortOption => _sortOption;
  List<FilterOption> get platformOptions => List.unmodifiable(_platformOptions);
  List<FilterOption> get genreOptions => List.unmodifiable(_genreOptions);

  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages =>
      _pageSize <= 0 || _filteredGames.isEmpty
          ? 1
          : (_filteredGames.length / _pageSize).ceil();

  bool get isGridView => _isGridView;
  double get gridCardExtent => _gridCardExtent;

  /// Retorna la lista de videojuegos correspondiente a la página actual.
  List<Game> get paginatedGames {
    if (_pageSize <= 0) return _filteredGames;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= _filteredGames.length) return const [];
    final end = (start + _pageSize).clamp(0, _filteredGames.length);
    return _filteredGames.sublist(start, end);
  }

  /// Conteo de filtros activos diferentes de sus valores por defecto.
  int get activeFiltersCount =>
      (_statusFilter != 'Todos' ? 1 : 0) +
      (_platformFilter != 'Todas' ? 1 : 0) +
      (_genreFilter != 'Todos' ? 1 : 0) +
      (_searchQuery.trim().isNotEmpty ? 1 : 0);

  // ===========================================================================
  // Métodos de Inicialización y Persistencia de Preferencias
  // ===========================================================================

  /// Obtiene o inicializa la instancia de [SharedPreferences].
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Inicializa las preferencias guardadas del usuario y carga la biblioteca.
  Future<void> initialize() async {
    try {
      final prefs = await _getPrefs();
      _isGridView = prefs.getBool(keyViewMode) ?? true;
      _pageSize = prefs.getInt(keyPageSize) ?? 25;
      _gridCardExtent = prefs.getDouble(keyCardSize) ?? 220.0;
    } catch (e) {
      debugPrint('[DashboardController] Error cargando preferencias: $e');
    }

    await loadFilterMetadata();
    await loadGames();
  }

  // ===========================================================================
  // Carga de Datos y Metadatos de Filtros
  // ===========================================================================

  /// Carga metadatos globales (conteo total, juego en curso 'Hero', chips de plataformas y géneros).
  Future<void> loadFilterMetadata() async {
    try {
      final allGames = await _dbService.getAllGames();
      final playing = allGames.where((g) => g.status == 'Jugando').toList();

      _totalGamesCount = allGames.length;
      _heroGame = playing.isNotEmpty ? playing.first : null;
      _platformOptions = FilterMetadataHelper.buildPlatformOptions(allGames);
      _genreOptions = FilterMetadataHelper.buildGenreOptions(allGames);
    } catch (e) {
      debugPrint('[DashboardController] Error cargando metadatos de filtros: $e');
    }
  }

  /// Carga la lista filtrada de videojuegos desde SQLite según los filtros activos.
  Future<void> loadGames({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (forceRefresh) {
        await loadFilterMetadata();
      }

      final results = await _dbService.getAllGames(
        status: _statusFilter,
        platform: _platformFilter,
        genre: _genreFilter,
        search: _searchQuery,
        sortBy: _sortOption,
      );

      _filteredGames = results;
      _currentPage = 1;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar los videojuegos: $e';
      debugPrint('[DashboardController] loadGames error: $e');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Refresca forzadamente la biblioteca completa y sus metadatos.
  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    await loadGames(forceRefresh: true);
  }

  // ===========================================================================
  // Paginación
  // ===========================================================================

  /// Establece la página actual garantizando que se encuentre dentro de los límites válidos.
  void setPage(int page) {
    final targetPage = page.clamp(1, totalPages);
    if (_currentPage != targetPage) {
      _currentPage = targetPage;
      notifyListeners();
    }
  }

  /// Cambia el tamaño de página y persiste la preferencia.
  Future<void> setPageSize(int newSize) async {
    if (newSize <= 0) return;
    _pageSize = newSize;
    _currentPage = 1;
    notifyListeners();

    try {
      final prefs = await _getPrefs();
      await prefs.setInt(keyPageSize, newSize);
    } catch (e) {
      debugPrint('[DashboardController] Error guardando pageSize: $e');
    }
  }

  // ===========================================================================
  // Filtros Activos
  // ===========================================================================

  /// Actualiza la consulta de búsqueda y recarga los juegos.
  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    await loadGames();
  }

  /// Actualiza el filtro de estado y recarga los juegos.
  Future<void> setStatusFilter(String status) async {
    _statusFilter = status;
    await loadGames();
  }

  /// Actualiza el filtro de plataforma y recarga los juegos.
  Future<void> setPlatformFilter(String platform) async {
    _platformFilter = platform;
    await loadGames();
  }

  /// Actualiza el filtro de género y recarga los juegos.
  Future<void> setGenreFilter(String genre) async {
    _genreFilter = genre;
    await loadGames();
  }

  /// Actualiza la opción de ordenamiento y recarga los juegos.
  Future<void> setSortOption(String sort) async {
    _sortOption = sort;
    await loadGames();
  }

  /// Restaura todos los filtros y criterios de búsqueda a su estado inicial.
  Future<void> clearFilters() async {
    _statusFilter = 'Todos';
    _platformFilter = 'Todas';
    _genreFilter = 'Todos';
    _sortOption = 'Recientes';
    _searchQuery = '';
    await loadGames();
  }

  // ===========================================================================
  // Visualización y Zoom
  // ===========================================================================

  /// Alterna entre vista de cuadrícula (Grid) y lista compacta (List).
  Future<void> toggleViewMode() async {
    _isGridView = !_isGridView;
    notifyListeners();

    try {
      final prefs = await _getPrefs();
      await prefs.setBool(keyViewMode, _isGridView);
    } catch (e) {
      debugPrint('[DashboardController] Error guardando viewMode: $e');
    }
  }

  /// Modifica el ancho objetivo de las tarjetas en la cuadrícula con límites seguros.
  Future<void> setGridCardExtent(double newExtent) async {
    final clamped = newExtent.clamp(140.0, 420.0);
    _gridCardExtent = clamped;
    notifyListeners();

    try {
      final prefs = await _getPrefs();
      await prefs.setDouble(keyCardSize, clamped);
    } catch (e) {
      debugPrint('[DashboardController] Error guardando cardExtent: $e');
    }
  }

  // ===========================================================================
  // Acciones Rápidas (Quick Actions)
  // ===========================================================================

  /// Suma rápidamente horas al juego, aplicando transiciones automáticas
  /// y persistiendo en la base de datos local SQLite.
  Future<Game> quickAddHours(Game game, num delta) async {
    final updated = game.applyPlaytimeProgress(additionalHours: delta);

    // Actualizar en memoria local inmediatamente para UX responsiva
    final idx = _filteredGames.indexWhere((g) => g.id == game.id);
    if (idx != -1) {
      _filteredGames[idx] = updated;
    }
    if (_heroGame?.id == game.id) {
      _heroGame = updated;
    }
    notifyListeners();

    try {
      await _dbService.updateGame(updated);
    } catch (e) {
      debugPrint('[DashboardController] Error persistiendo quickAddHours: $e');
      _errorMessage = 'Error al actualizar horas: $e';
      notifyListeners();
    }

    return updated;
  }

  /// Modifica directamente el estado de un juego ('Por jugar', 'Jugando', 'Jugado')
  /// y actualiza metadatos y listas.
  Future<Game> updateGameStatus(Game game, String newStatus) async {
    final updated = game.copyWith(
      status: newStatus,
      completedDate: (newStatus == 'Jugado' && game.completedDate == null)
          ? DateTime.now()
          : game.completedDate,
      updatedAt: DateTime.now(),
    );

    final idx = _filteredGames.indexWhere((g) => g.id == game.id);
    if (idx != -1) {
      _filteredGames[idx] = updated;
    }
    notifyListeners();

    try {
      await _dbService.updateGame(updated);
      await loadFilterMetadata();
      await loadGames();
    } catch (e) {
      debugPrint('[DashboardController] Error persistiendo updateGameStatus: $e');
      _errorMessage = 'Error al actualizar estado: $e';
      notifyListeners();
    }

    return updated;
  }
}
