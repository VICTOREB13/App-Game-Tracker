import 'package:flutter/foundation.dart';

import '../models/game.dart';
import '../services/database_service.dart';
import '../services/hltb_service.dart';
import '../services/metadata_service.dart';
import '../views/widgets/platform_helper.dart';
import '../views/widgets/status_helper.dart';

/// Controlador de la pantalla de detalle/edición de videojuegos bajo el patrón MVC.
///
/// Encapsula el ciclo de vida, estado de edición en memoria, transiciones
/// automáticas de horas y estados, consulta de metadatos externos (HLTB / Wikipedia),
/// persistencia en [DatabaseService] y exportación de ficha social.
class GameDetailController extends ChangeNotifier {
  final DatabaseService _dbService;
  final HltbService _hltbService;
  final MetadataService _metadataService;

  // Entidad de juego original y actualizada
  Game _game;

  // --- Campos Editables ---
  String _title;
  String _status;
  String _platform;
  num _hoursPlayed;
  String? _rating;
  List<String> _genres;
  String _summary;
  String _coverUrl;
  String _link;
  num? _hltbMain;
  num? _hltbCompletionist;
  DateTime? _startDate;
  DateTime? _completedDate;

  // --- Estados de Proceso y Flags ---
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isFetchingHltb = false;
  bool _isSearchingWiki = false;
  String? _errorMessage;

  static const List<String> availableRatings = [
    '★★★★★',
    '★★★★✰',
    '★★★✰✰',
    '★★✰✰✰',
    '★✰✰✰✰',
    '✰✰✰✰✰',
    'Sin calificar',
  ];

  GameDetailController({
    required Game game,
    DatabaseService? dbService,
    HltbService? hltbService,
    MetadataService? metadataService,
  })  : _game = game,
        _dbService = dbService ?? DatabaseService.instance,
        _hltbService = hltbService ?? HltbService.instance,
        _metadataService = metadataService ?? MetadataService.instance,
        _title = game.title,
        _status = StatusHelper.gameStatuses.contains(game.status)
            ? game.status
            : StatusHelper.porJugar,
        _platform = PlatformHelper.getOrderedPlatforms(currentPlatform: game.platform).first,
        _hoursPlayed = game.hoursPlayed ?? 0.0,
        _rating = game.rating,
        _genres = List.from(game.genres),
        _summary = game.summary ?? '',
        _coverUrl = game.coverUrl ?? '',
        _link = game.link ?? '',
        _hltbMain = game.hltbMain,
        _hltbCompletionist = game.hltbCompletionist,
        _startDate = game.startDate,
        _completedDate = game.completedDate;

  // ===========================================================================
  // Getters Públicos
  // ===========================================================================

  Game get game => _game;
  String get title => _title;
  String get status => _status;
  String get platform => _platform;
  num get hoursPlayed => _hoursPlayed;
  String? get rating => _rating;
  List<String> get genres => List.unmodifiable(_genres);
  String get summary => _summary;
  String get coverUrl => _coverUrl;
  String get link => _link;
  num? get hltbMain => _hltbMain;
  num? get hltbCompletionist => _hltbCompletionist;
  DateTime? get startDate => _startDate;
  DateTime? get completedDate => _completedDate;

  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  bool get isFetchingHltb => _isFetchingHltb;
  bool get isSearchingWiki => _isSearchingWiki;
  String? get errorMessage => _errorMessage;

  /// Horas formateadas para campos de texto (ej. "12" o "12.5")
  String get hoursPlayedFormatted =>
      _hoursPlayed % 1 == 0 ? _hoursPlayed.toInt().toString() : _hoursPlayed.toString();

  String get hltbMainFormatted =>
      _hltbMain != null ? (_hltbMain! % 1 == 0 ? _hltbMain!.toInt().toString() : _hltbMain!.toString()) : '0';

  String get hltbCompFormatted =>
      _hltbCompletionist != null
          ? (_hltbCompletionist! % 1 == 0
              ? _hltbCompletionist!.toInt().toString()
              : _hltbCompletionist!.toString())
          : '0';

  // ===========================================================================
  // Mutadores de Campos Editables
  // ===========================================================================

  void setTitle(String val) {
    _title = val;
    notifyListeners();
  }

  void setStatus(String val) {
    _status = val;
    if (val == StatusHelper.jugado && _completedDate == null) {
      _completedDate = DateTime.now();
    }
    notifyListeners();
  }

  void setPlatform(String val) {
    _platform = val;
    notifyListeners();
  }

  void setRating(String? val) {
    if (val == 'Sin calificar' || val == null || val.trim().isEmpty) {
      _rating = null;
    } else {
      _rating = val;
    }
    notifyListeners();
  }

  void setHours(num hours) {
    _hoursPlayed = hours.clamp(0.0, Game.maxPlaytimeHours);
    notifyListeners();
  }

  /// Añade horas delta ejecutando la lógica de transición automática de [applyPlaytimeProgress].
  void addHours(num delta) {
    final updatedHours = (_hoursPlayed + delta).clamp(0.0, Game.maxPlaytimeHours);
    final transition = _game.copyWith(
      status: _status,
      startDate: _startDate,
      completedDate: _completedDate,
      hltbMain: _hltbMain,
    ).applyPlaytimeProgress(totalHours: updatedHours);

    _hoursPlayed = transition.hoursPlayed ?? updatedHours;
    _status = transition.status;
    _startDate = transition.startDate;
    _completedDate = transition.completedDate;
    notifyListeners();
  }

  void setSummary(String val) {
    _summary = val;
    notifyListeners();
  }

  void setCoverUrl(String val) {
    _coverUrl = val;
    notifyListeners();
  }

  void setLink(String val) {
    _link = val;
    notifyListeners();
  }

  void setHltbMain(num? val) {
    _hltbMain = val != null ? val.clamp(0.0, Game.maxPlaytimeHours) : null;
    notifyListeners();
  }

  void setHltbCompletionist(num? val) {
    _hltbCompletionist = val != null ? val.clamp(0.0, Game.maxPlaytimeHours) : null;
    notifyListeners();
  }

  void setStartDate(DateTime? date) {
    _startDate = date;
    notifyListeners();
  }

  void setCompletedDate(DateTime? date) {
    _completedDate = date;
    notifyListeners();
  }

  /// Agrega o quita un género de la lista de seleccionados.
  void toggleGenre(String genre) {
    final trimmed = genre.trim();
    if (trimmed.isEmpty) return;

    if (_genres.contains(trimmed)) {
      _genres.remove(trimmed);
    } else {
      _genres.add(trimmed);
    }
    notifyListeners();
  }

  void setGenres(List<String> genres) {
    _genres = List.from(genres);
    notifyListeners();
  }

  // ===========================================================================
  // Métricas Externas (HLTB & Wikipedia)
  // ===========================================================================

  /// Consulta HowLongToBeat para obtener las horas estimadas de campaña y completista.
  Future<void> fetchHltbData() async {
    final targetTitle = _title.trim();
    if (targetTitle.isEmpty) return;

    _isFetchingHltb = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _hltbService.searchHltb(targetTitle);
      if (res != null) {
        if (res.mainStory != null) {
          _hltbMain = res.mainStory;
        }
        if (res.completionist != null) {
          _hltbCompletionist = res.completionist;
        }
      }
    } catch (e) {
      debugPrint('[GameDetailController] Error consultando HLTB: $e');
      _errorMessage = 'Error consultando HowLongToBeat: $e';
    } finally {
      _isFetchingHltb = false;
      notifyListeners();
    }
  }

  /// Consulta Wikipedia para obtener el enlace enciclopédico oficial del juego.
  Future<void> fetchWikipediaLink() async {
    final targetTitle = _title.trim();
    if (targetTitle.isEmpty) return;

    _isSearchingWiki = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = await _metadataService.searchWikipedia(targetTitle);
      if (url != null && url.isNotEmpty) {
        _link = url;
      }
    } catch (e) {
      debugPrint('[GameDetailController] Error consultando Wikipedia: $e');
      _errorMessage = 'Error consultando Wikipedia: $e';
    } finally {
      _isSearchingWiki = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // Persistencia y Eliminación
  // ===========================================================================

  /// Aplica progreso de horas, valida límites y guarda los cambios en SQLite.
  Future<Game> saveGame() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanCover = _coverUrl.trim();
      final cleanSummary = _summary.trim();
      final cleanLink = _link.trim();

      // Aplica reglas de progreso automático (por ejemplo, pasa a 'Jugando' si >= 1h o 'Jugado' si >= HLTB)
      final progressed = _game.copyWith(
        status: _status,
        startDate: _startDate,
        completedDate: _completedDate,
        hltbMain: _hltbMain,
      ).applyPlaytimeProgress(totalHours: _hoursPlayed);

      final updatedGame = _game.copyWith(
        title: _title.trim().isNotEmpty ? _title.trim() : _game.title,
        status: progressed.status,
        platform: _platform.trim().isNotEmpty ? _platform.trim() : null,
        hoursPlayed: progressed.hoursPlayed,
        genres: _genres,
        rating: _rating,
        hltbMain: _hltbMain,
        hltbCompletionist: _hltbCompletionist,
        coverUrl: cleanCover.isNotEmpty ? cleanCover : null,
        summary: cleanSummary.isNotEmpty ? cleanSummary : null,
        link: cleanLink.isNotEmpty ? cleanLink : null,
        startDate: progressed.startDate,
        completedDate: progressed.completedDate,
        updatedAt: DateTime.now(),
      );

      await _dbService.updateGame(updatedGame);
      _game = updatedGame;
      return updatedGame;
    } catch (e) {
      debugPrint('[GameDetailController] Error guardando juego: $e');
      _errorMessage = 'Error al guardar el juego: $e';
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Elimina permanentemente el juego de la base de datos local SQLite.
  Future<void> deleteGame() async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dbService.deleteGame(_game.id);
    } catch (e) {
      debugPrint('[GameDetailController] Error eliminando juego: $e');
      _errorMessage = 'Error al eliminar el juego: $e';
      rethrow;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // Exportación de Ficha Social
  // ===========================================================================

  /// Retorna un mapa con los datos canónicos necesarios para renderizar y exportar
  /// la tarjeta social en imagen PNG.
  Map<String, dynamic> exportSocialCardData() {
    return {
      'game': _game,
      'title': _title.trim().isNotEmpty ? _title.trim() : _game.title,
      'hoursPlayed': _hoursPlayed,
      'rating': _rating ?? 'Sin calificar',
      'summary': _summary.trim(),
      'platform': _platform,
      'status': _status,
      'completedDate': _completedDate,
      'coverUrl': _coverUrl.trim(),
    };
  }
}
