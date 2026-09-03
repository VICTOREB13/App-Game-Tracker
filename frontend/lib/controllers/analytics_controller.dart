import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../services/database_service.dart';
import '../views/widgets/genre_helper.dart';
import '../views/widgets/status_helper.dart';

/// Controlador de Analíticas y Métricas de la biblioteca bajo el patrón MVC.
///
/// Encapsula el cálculo reactivo de:
/// - Distribución por estado (Jugado, Jugando, Por jugar).
/// - Distribución por plataforma y género.
/// - Sumatoria total y promedios de horas de juego.
/// - Calculadora de backlog y horas estimadas pendientes.
/// - Metas anuales multi-año (guardadas en [SharedPreferences]).
/// - Salón de la Fama / Récords personales (Titán, Obra Maestra, Aventura Ágil).
class AnalyticsController extends ChangeNotifier {
  final DatabaseService _dbService;
  SharedPreferences? _prefs;

  // Clave base para metas anuales
  static const String _keyGoalPrefix = 'annual_game_goal_';

  // --- Estado ---
  List<Game> _games = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedYear;
  int _annualGoal = 12;

  AnalyticsController({
    DatabaseService? dbService,
    SharedPreferences? prefs,
    int? initialYear,
  })  : _dbService = dbService ?? DatabaseService.instance,
        _prefs = prefs,
        _selectedYear = initialYear ?? DateTime.now().year;

  // ===========================================================================
  // Getters Públicos de Estado Básico
  // ===========================================================================

  List<Game> get games => List.unmodifiable(_games);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedYear => _selectedYear;
  int get annualGoal => _annualGoal;

  // ===========================================================================
  // Métodos de Carga y Configuración
  // ===========================================================================

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Carga la biblioteca completa de juegos y las metas anuales correspondientes.
  Future<void> loadAnalytics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allGames = await _dbService.getAllGames();
      _games = allGames;

      final prefs = await _getPrefs();
      _annualGoal = prefs.getInt('$_keyGoalPrefix$_selectedYear') ?? 12;
    } catch (e) {
      debugPrint('[AnalyticsController] Error cargando analíticas: $e');
      _errorMessage = 'Error al cargar analíticas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia el año seleccionado y recarga la meta correspondiente.
  Future<void> setSelectedYear(int year) async {
    if (_selectedYear == year) return;
    _selectedYear = year;
    notifyListeners();

    try {
      final prefs = await _getPrefs();
      _annualGoal = prefs.getInt('$_keyGoalPrefix$_selectedYear') ?? 12;
      notifyListeners();
    } catch (e) {
      debugPrint('[AnalyticsController] Error cargando meta anual: $e');
    }
  }

  /// Ajusta la meta anual del año seleccionado y la persiste en preferencias.
  Future<void> setAnnualGoal(int newGoal) async {
    if (newGoal <= 0) return;
    _annualGoal = newGoal;
    notifyListeners();

    try {
      final prefs = await _getPrefs();
      await prefs.setInt('$_keyGoalPrefix$_selectedYear', newGoal);
    } catch (e) {
      debugPrint('[AnalyticsController] Error guardando meta anual: $e');
    }
  }

  /// Decrementa el año analizado.
  Future<void> previousYear() async {
    await setSelectedYear(_selectedYear - 1);
  }

  /// Incrementa el año analizado.
  Future<void> nextYear() async {
    await setSelectedYear(_selectedYear + 1);
  }

  // ===========================================================================
  // Métricas Generales y Horas
  // ===========================================================================

  int get totalGames => _games.length;

  double get totalHours =>
      _games.fold<double>(0.0, (sum, g) => sum + (g.hoursPlayed ?? 0).toDouble());

  String get totalHoursFormatted =>
      totalHours % 1 == 0 ? totalHours.toInt().toString() : totalHours.toStringAsFixed(1);

  // ===========================================================================
  // Distribución por Estado
  // ===========================================================================

  /// Conteo de juegos por cada estado canónico.
  Map<String, int> get statusDistribution {
    final Map<String, int> counts = {
      StatusHelper.jugado: 0,
      StatusHelper.jugando: 0,
      StatusHelper.porJugar: 0,
    };
    for (final g in _games) {
      final status = g.status;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  int get completedCount => statusDistribution[StatusHelper.jugado] ?? 0;
  int get playingCount => statusDistribution[StatusHelper.jugando] ?? 0;
  int get backlogCount => statusDistribution[StatusHelper.porJugar] ?? 0;

  double get completionRateValue =>
      totalGames > 0 ? (completedCount / totalGames) * 100.0 : 0.0;

  String get completionRate => completionRateValue.toStringAsFixed(1);

  /// Porcentaje de cada estado respecto al total de la biblioteca.
  Map<String, double> get statusPercentages {
    if (totalGames == 0) return {};
    final dist = statusDistribution;
    return dist.map((k, v) => MapEntry(k, (v / totalGames) * 100.0));
  }

  // ===========================================================================
  // Distribución por Plataforma
  // ===========================================================================

  /// Matriz de plataforma -> estado -> conteo para gráficos de barras apiladas.
  Map<String, Map<String, int>> get platformDistribution {
    final Map<String, Map<String, int>> data = {};
    for (final g in _games) {
      final plat = (g.platform != null && g.platform!.trim().isNotEmpty)
          ? g.platform!.trim()
          : 'Otra';
      final stat = g.status;

      if (!data.containsKey(plat)) {
        data[plat] = {
          StatusHelper.jugado: 0,
          StatusHelper.jugando: 0,
          StatusHelper.porJugar: 0,
        };
      }
      data[plat]![stat] = (data[plat]![stat] ?? 0) + 1;
    }
    return data;
  }

  /// Conteo total de títulos por plataforma.
  Map<String, int> get platformTotals {
    final Map<String, int> totals = {};
    for (final entry in platformDistribution.entries) {
      totals[entry.key] = entry.value.values.fold(0, (a, b) => a + b);
    }
    return totals;
  }

  // ===========================================================================
  // Distribución por Género
  // ===========================================================================

  /// Conteo de juegos asociados a cada género normalizado.
  Map<String, int> get genreDistribution {
    final Map<String, int> counts = {};
    for (final g in _games) {
      final normalizedSet = g.genres
          .where((gen) => gen.trim().isNotEmpty)
          .map(GenreHelper.normalize)
          .where((gen) => gen.isNotEmpty)
          .toSet();

      for (final norm in normalizedSet) {
        counts[norm] = (counts[norm] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Sumatoria de horas de juego registradas por género normalizado.
  Map<String, double> get genreHours {
    final Map<String, double> hoursMap = {};
    for (final g in _games) {
      final hours = (g.hoursPlayed ?? 0).toDouble();
      if (hours <= 0) continue;

      final normalizedSet = g.genres
          .where((gen) => gen.trim().isNotEmpty)
          .map(GenreHelper.normalize)
          .where((gen) => gen.isNotEmpty)
          .toSet();

      for (final norm in normalizedSet) {
        hoursMap[norm] = (hoursMap[norm] ?? 0.0) + hours;
      }
    }
    return hoursMap;
  }

  // ===========================================================================
  // Calculadora de Backlog
  // ===========================================================================

  List<Game> get backlogGames =>
      _games.where((g) => g.status == StatusHelper.porJugar).toList();

  double get totalBacklogHours =>
      backlogGames.fold<double>(0.0, (sum, g) => sum + (g.hltbMain ?? 0).toDouble());

  String get totalBacklogHoursFormatted =>
      totalBacklogHours > 0 ? '~${totalBacklogHours.toInt()}h estimadas' : '0 horas';

  // ===========================================================================
  // Metas Anuales (Multi-Year Goal Tracker)
  // ===========================================================================

  /// Lista de juegos marcados como culminados durante el año seleccionado.
  List<Game> get completedInSelectedYear => _games.where((g) {
        if (g.status != StatusHelper.jugado) return false;
        if (g.completedDate != null) {
          return g.completedDate!.year == _selectedYear;
        }
        return false;
      }).toList();

  int get completedInSelectedYearCount => completedInSelectedYear.length;

  double get yearProgress => _annualGoal > 0
      ? (completedInSelectedYearCount / _annualGoal).clamp(0.0, 1.0)
      : 0.0;

  bool get isYearGoalMet => completedInSelectedYearCount >= _annualGoal;

  int get remainingForYearGoal =>
      (_annualGoal - completedInSelectedYearCount).clamp(0, _annualGoal);

  Game? get lastCompletedInSelectedYear =>
      completedInSelectedYear.isNotEmpty ? completedInSelectedYear.last : null;

  // ===========================================================================
  // Salón de la Fama & Récords Personales (Hall of Fame)
  // ===========================================================================

  List<Game> get completedGames =>
      _games.where((g) => g.status == StatusHelper.jugado).toList();

  /// El Titán: juego completado con la mayor cantidad de horas acumuladas.
  Game? get titanGame {
    if (completedGames.isEmpty) return null;
    return completedGames.reduce((a, b) =>
        (a.hoursPlayed ?? 0) >= (b.hoursPlayed ?? 0) ? a : b);
  }

  /// Obra Maestra: juego con calificación de 5 estrellas ('★★★★★') con más horas registradas.
  Game? get masterpieceGame {
    final fiveStar = completedGames
        .where((g) => g.rating == '★★★★★')
        .toList();
    if (fiveStar.isEmpty) return null;
    return fiveStar.reduce((a, b) =>
        (a.hoursPlayed ?? 0) >= (b.hoursPlayed ?? 0) ? a : b);
  }

  /// Aventura Ágil: juego completado en el menor tiempo registrado con HLTB > 0 y horas > 0.
  Game? get agileGame {
    final candidates = completedGames
        .where((g) => (g.hltbMain ?? 0) > 0 && (g.hoursPlayed ?? 0) > 0)
        .toList();
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) =>
        (a.hoursPlayed ?? 99999) <= (b.hoursPlayed ?? 99999) ? a : b);
  }

  /// Las mejores calificaciones ordenadas por estrellas decrecientes.
  List<Game> get topRatedGames {
    const ratingOrder = ['★★★★★', '★★★★✰', '★★★✰✰', '★★✰✰✰', '★✰✰✰✰'];
    final rated = _games
        .where((g) => g.rating != null && ratingOrder.contains(g.rating))
        .toList();

    rated.sort((a, b) {
      final ai = ratingOrder.indexOf(a.rating!);
      final bi = ratingOrder.indexOf(b.rating!);
      return ai.compareTo(bi);
    });

    return rated.take(5).toList();
  }
}
