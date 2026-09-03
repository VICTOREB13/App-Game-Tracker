import 'package:flutter/foundation.dart';

import '../models/game.dart';
import '../services/database_service.dart';
import '../services/hltb_service.dart';
import '../services/metadata_service.dart';
import '../services/secure_storage_service.dart';

/// Parámetros de configuración al incorporar un juego encontrado a la biblioteca.
class AddGameParams {
  final String status;
  final String platform;
  final num hoursPlayed;
  final List<String> genres;
  final DateTime? startDate;
  final DateTime? completedDate;
  final String? customRating;
  final String? customSummary;

  const AddGameParams({
    required this.status,
    required this.platform,
    required this.hoursPlayed,
    required this.genres,
    this.startDate,
    this.completedDate,
    this.customRating,
    this.customSummary,
  });
}

/// Controlador para la búsqueda e ingesta de videojuegos externos bajo el patrón MVC.
///
/// Encapsula la interacción con la API de RAWG vía [MetadataService],
/// el enriquecimiento previo de datos (Wikipedia y HowLongToBeat),
/// y la persistencia de la nueva entidad [Game] en [DatabaseService].
class GameSearchController extends ChangeNotifier {
  final MetadataService _metadataService;
  final DatabaseService _dbService;
  final SecureStorageService _secureStorage;
  final HltbService _hltbService;

  // --- Estado de Búsqueda ---
  bool _isSearching = false;
  bool _isAdding = false;
  String _query = '';
  List<Map<String, dynamic>> _results = [];
  String? _errorMessage;
  String? _rawgKey;

  GameSearchController({
    MetadataService? metadataService,
    DatabaseService? dbService,
    SecureStorageService? secureStorage,
    HltbService? hltbService,
  })  : _metadataService = metadataService ?? MetadataService.instance,
        _dbService = dbService ?? DatabaseService.instance,
        _secureStorage = secureStorage ?? SecureStorageService.instance,
        _hltbService = hltbService ?? HltbService.instance;

  // ===========================================================================
  // Getters Públicos
  // ===========================================================================

  bool get isSearching => _isSearching;
  bool get isAdding => _isAdding;
  String get query => _query;
  List<Map<String, dynamic>> get results => List.unmodifiable(_results);
  String? get errorMessage => _errorMessage;
  String? get rawgKey => _rawgKey;
  bool get hasRawgKey => _rawgKey != null && _rawgKey!.trim().isNotEmpty;

  // ===========================================================================
  // Gestión de Clave API y Búsqueda
  // ===========================================================================

  /// Carga la clave de RAWG almacenada en el almacén seguro cifrado.
  Future<void> loadRawgKey() async {
    try {
      _rawgKey = await _secureStorage.getRawgKey();
      notifyListeners();
    } catch (e) {
      debugPrint('[GameSearchController] Error cargando RAWG key: $e');
    }
  }

  /// Ejecuta la búsqueda de videojuegos en la API de RAWG.
  Future<void> searchGames(String newQuery, {String? customApiKey}) async {
    final cleanQuery = newQuery.trim();
    _query = cleanQuery;

    if (cleanQuery.isEmpty) {
      _results = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    final key = customApiKey ?? _rawgKey;
    if (key == null || key.trim().isEmpty) {
      _errorMessage = 'Configura tu RAWG API Key en Ajustes para buscar juegos.';
      _results = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final searchResults = await _metadataService.searchRawgGames(
        cleanQuery,
        key.trim(),
        pageSize: 15,
      );

      _results = searchResults;
      _errorMessage = null;
    } catch (e) {
      debugPrint('[GameSearchController] Error buscando en RAWG: $e');
      _errorMessage = 'Error durante la búsqueda: $e';
      _results = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Limpia los resultados y el texto de búsqueda actual.
  void clearSearch() {
    _query = '';
    _results = [];
    _errorMessage = null;
    notifyListeners();
  }

  // ===========================================================================
  // Ingesta y Guardado de Nuevo Juego
  // ===========================================================================

  /// Crea y persiste un nuevo videojuego en SQLite enriqueciéndolo con metadatos
  /// de Wikipedia y HowLongToBeat de forma resiliente.
  Future<Game> addGameToLibrary({
    required Map<String, dynamic> rawgGame,
    required AddGameParams params,
  }) async {
    _isAdding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final title = rawgGame['name']?.toString().trim() ?? 'Sin título';
      final coverUrl = rawgGame['background_image']?.toString().trim();
      final playtime = (rawgGame['playtime'] as num?)?.toDouble();

      // 1. Búsqueda de Wikipedia en paralelo defensivo
      String? wikiLink;
      try {
        wikiLink = await _metadataService.searchWikipedia(title);
      } catch (e) {
        debugPrint('[GameSearchController] Wiki lookup no crítico falló: $e');
      }

      // 2. Búsqueda de HowLongToBeat
      num? finalHltbMain = playtime;
      num? finalHltbComp;
      try {
        final hltbData = await _hltbService.searchHltb(title);
        if (hltbData != null) {
          if (hltbData.mainStory != null) {
            finalHltbMain = hltbData.mainStory;
          }
          if (hltbData.completionist != null) {
            finalHltbComp = hltbData.completionist;
          }
        }
      } catch (e) {
        debugPrint('[GameSearchController] HLTB lookup no crítico falló: $e');
      }

      final now = DateTime.now();

      final baseGame = Game(
        title: title,
        coverUrl: coverUrl != null && coverUrl.isNotEmpty ? coverUrl : null,
        status: params.status,
        platform: params.platform,
        hoursPlayed: params.hoursPlayed,
        genres: params.genres,
        rating: params.customRating,
        summary: params.customSummary,
        hltbMain: finalHltbMain,
        hltbCompletionist: finalHltbComp,
        link: wikiLink,
        startDate: params.startDate,
        completedDate: params.completedDate,
        createdAt: now,
        updatedAt: now,
      );

      // Aplica reglas automáticas de progreso (ej. de 'Por jugar' a 'Jugando' si >= 1h)
      final newGame = baseGame.applyPlaytimeProgress(totalHours: params.hoursPlayed);

      // Persistir en SQLite
      await _dbService.insertGame(newGame);

      return newGame;
    } catch (e) {
      debugPrint('[GameSearchController] Error añadiendo juego: $e');
      _errorMessage = 'Error al agregar el juego: $e';
      rethrow;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }
}
