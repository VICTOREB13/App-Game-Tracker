import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../services/database_service.dart';
import '../services/theme_manager.dart';
import '../widgets/platform_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Game> _games = [];
  bool _isLoading = true;

  // Dynamic Multi-Year Goals
  int _selectedYear = DateTime.now().year;
  int _annualGoal = 12;

  @override
  void initState() {
    super.initState();
    unawaited(_loadYearGoal());
    unawaited(_fetchData());
  }

  Future<void> _loadYearGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt('annual_game_goal_$_selectedYear') ?? 12;
    if (mounted) setState(() => _annualGoal = goal);
  }

  Future<void> _setYearGoal(int newGoal) async {
    setState(() => _annualGoal = newGoal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('annual_game_goal_$_selectedYear', newGoal);
  }

  Future<void> _fetchData() async {
    try {
      final games = await DatabaseService.instance.getAllGames();
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Status distribution
  Map<String, int> _getStatusData() {
    final Map<String, int> counts = {
      'Jugado': 0,
      'Jugando': 0,
      'Por jugar': 0,
    };
    for (var g in _games) {
      counts[g.status] = (counts[g.status] ?? 0) + 1;
    }
    return counts;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Jugado':
        return const Color(0xFF10B981);
      case 'Jugando':
        return const Color(0xFFDC2626);
      case 'Por jugar':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFA1A1AA);
    }
  }

  // Platform distribution
  Map<String, Map<String, int>> _getPlatformData() {
    final Map<String, Map<String, int>> data = {};
    for (var g in _games) {
      final plat = g.platform ?? 'Otra';
      final stat = g.status;
      if (!data.containsKey(plat)) {
        data[plat] = {'Jugado': 0, 'Jugando': 0, 'Por jugar': 0};
      }
      data[plat]![stat] = (data[plat]![stat] ?? 0) + 1;
    }
    return data;
  }

  // Top rated games
  List<Game> _getTopRated() {
    final ratingOrder = ['★★★★★', '★★★★✰', '★★★✰✰', '★★✰✰✰', '★✰✰✰✰'];
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

  Future<void> _showEditGoalDialog() async {
    final newGoal = await showDialog<int>(
      context: context,
      builder: (ctx) => _EditGoalDialog(
        year: _selectedYear,
        initialGoal: _annualGoal,
      ),
    );

    if (newGoal != null && newGoal > 0) {
      await _setYearGoal(newGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(context),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
      );
    }

    final statusData = _getStatusData();
    final platformData = _getPlatformData();
    final totalGames = _games.length;
    final topRated = _getTopRated();
    final totalHours =
        _games.fold<num>(0, (sum, g) => sum + (g.hoursPlayed ?? 0));

    // Backlog Calculator stats
    final backlogGames = _games.where((g) => g.status == 'Por jugar').toList();
    final totalBacklogHours =
        backlogGames.fold<num>(0, (sum, g) => sum + (g.hltbMain ?? 0));

    // Games completed in the selected year
    final completedInSelectedYear = _games.where((g) {
      if (g.status != 'Jugado') return false;
      if (g.completedDate != null) {
        return g.completedDate!.year == _selectedYear;
      }
      return false;
    }).toList();

    final yearProgress = _annualGoal > 0
        ? (completedInSelectedYear.length / _annualGoal).clamp(0.0, 1.0)
        : 0.0;

    // Hall of Fame / Records
    final completedGames =
        _games.where((g) => g.status == 'Jugado').toList();

    // Titan: most hours played among completed games
    Game? titanGame;
    if (completedGames.isNotEmpty) {
      titanGame = completedGames.reduce((a, b) =>
          (a.hoursPlayed ?? 0) >= (b.hoursPlayed ?? 0) ? a : b);
    }

    // Masterpiece: 5-star game with highest playtime
    final fiveStarCompleted = completedGames
        .where((g) => g.rating == '★★★★★')
        .toList();
    Game? masterpieceGame;
    if (fiveStarCompleted.isNotEmpty) {
      masterpieceGame = fiveStarCompleted.reduce((a, b) =>
          (a.hoursPlayed ?? 0) >= (b.hoursPlayed ?? 0) ? a : b);
    }

    // Agile Adventure: shortest completion time with HLTB > 0
    final gamesWithHltb = completedGames
        .where((g) => (g.hltbMain ?? 0) > 0 && (g.hoursPlayed ?? 0) > 0)
        .toList();
    Game? agileGame;
    if (gamesWithHltb.isNotEmpty) {
      agileGame = gamesWithHltb.reduce((a, b) =>
          (a.hoursPlayed ?? 9999) <= (b.hoursPlayed ?? 9999) ? a : b);
    }

    final completionRate = totalGames > 0
        ? ((statusData['Jugado'] ?? 0) / totalGames * 100).toStringAsFixed(1)
        : '0';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Estadísticas & Analíticas',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards (2x2 Grid for Mobile, 1x4 Row for Desktop)
              if (MediaQuery.of(context).size.width < 600)
                Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          'Total Juegos',
                          totalGames.toString(),
                          const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          'Horas Jugadas',
                          totalHours % 1 == 0
                              ? totalHours.toInt().toString()
                              : totalHours.toStringAsFixed(1),
                          const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatCard(
                          'Terminados',
                          (statusData['Jugado'] ?? 0).toString(),
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          'Tasa Éxito',
                          '$completionRate%',
                          const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    _buildStatCard(
                      'Total Juegos',
                      totalGames.toString(),
                      const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Horas Jugadas',
                      totalHours % 1 == 0
                          ? totalHours.toInt().toString()
                          : totalHours.toStringAsFixed(1),
                      const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Terminados',
                      (statusData['Jugado'] ?? 0).toString(),
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      'Tasa Éxito',
                      '$completionRate%',
                      const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Multi-Year Goal & Annual Tracker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Year selector header (Responsive: 2-row on mobile, 1-row on desktop)
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.emoji_events_rounded,
                                    size: 16, color: Color(0xFFDC2626)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Meta Anual de Juegos',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _showEditGoalDialog,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFDC2626).withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_rounded,
                                          size: 11, color: Color(0xFFDC2626)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ajustar',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, size: 22),
                                  color: AppColors.textSecondary(context),
                                  onPressed: () {
                                    setState(() => _selectedYear--);
                                    unawaited(_loadYearGoal());
                                  },
                                  tooltip: 'Año anterior',
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 13, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Año $_selectedYear',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded, size: 22),
                                  color: AppColors.textSecondary(context),
                                  onPressed: () {
                                    setState(() => _selectedYear++);
                                    unawaited(_loadYearGoal());
                                  },
                                  tooltip: 'Año siguiente',
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 32),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.emoji_events_rounded,
                                    size: 16, color: Color(0xFFDC2626)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Meta Anual de Juegos',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ],
                          ),

                          // Year stepper
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded,
                                    size: 20),
                                color: AppColors.textSecondary(context),
                                onPressed: () {
                                  setState(() => _selectedYear--);
                                  unawaited(_loadYearGoal());
                                },
                                tooltip: 'Año anterior',
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle(context),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppColors.border(context)),
                                ),
                                child: Text(
                                  '$_selectedYear',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded,
                                    size: 20),
                                color: AppColors.textSecondary(context),
                                onPressed: () {
                                  setState(() => _selectedYear++);
                                  unawaited(_loadYearGoal());
                                },
                                tooltip: 'Año siguiente',
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _showEditGoalDialog,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFDC2626).withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_rounded,
                                          size: 11, color: Color(0xFFDC2626)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ajustar',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),

                    // Progress info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${completedInSelectedYear.length} de $_annualGoal juegos completados',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(yearProgress * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: yearProgress,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceSubtle(context),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFDC2626)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            completedInSelectedYear.length >= _annualGoal
                                ? '¡Meta superada en $_selectedYear! 🏆'
                                : 'Faltan ${_annualGoal - completedInSelectedYear.length} juegos para la meta',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: completedInSelectedYear.length >= _annualGoal
                                  ? const Color(0xFF10B981)
                                  : AppColors.textSecondary(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (completedInSelectedYear.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Último: ${completedInSelectedYear.last.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.textMuted(context),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Backlog Calculator & Personal Records
              Row(
                children: [
                  // Backlog Calculator
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded,
                                  size: 16, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 6),
                              Text(
                                'Horas en Backlog',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalBacklogHours > 0
                                ? '~${totalBacklogHours.toInt()}h estimadas'
                                : '0 horas',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${backlogGames.length} juegos por empezar',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Backlog Health Ratio
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Text(
                                'Salud de Biblioteca',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$completionRate% finalizado',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${statusData['Jugado'] ?? 0} de $totalGames terminados',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Hall of Fame (Salón de la Fama)
              Text(
                'Salón de la Fama & Récords',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              if (MediaQuery.of(context).size.width < 600)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 175,
                        child: _buildRecordCard(
                          icon: Icons.shield_rounded,
                          color: const Color(0xFFDC2626),
                          badge: 'EL TITÁN',
                          title: titanGame?.title ?? 'Sin títulos',
                          stat: titanGame != null
                              ? '${titanGame.hoursPlayed ?? 0}h dedicadas'
                              : '0h',
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 175,
                        child: _buildRecordCard(
                          icon: Icons.star_rounded,
                          color: const Color(0xFFF59E0B),
                          badge: 'OBRA MAESTRA',
                          title: masterpieceGame?.title ?? 'Sin 5 estrellas',
                          stat: masterpieceGame != null
                              ? '5★ • ${masterpieceGame.hoursPlayed ?? 0}h'
                              : 'Sin calificar',
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 175,
                        child: _buildRecordCard(
                          icon: Icons.bolt_rounded,
                          color: const Color(0xFF10B981),
                          badge: 'AVENTURA ÁGIL',
                          title: agileGame?.title ?? 'Sin títulos',
                          stat: agileGame != null
                              ? '${agileGame.hoursPlayed ?? 0}h'
                              : '0h',
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildRecordCard(
                        icon: Icons.shield_rounded,
                        color: const Color(0xFFDC2626),
                        badge: 'EL TITÁN',
                        title: titanGame?.title ?? 'Sin títulos',
                        stat: titanGame != null
                            ? '${titanGame.hoursPlayed ?? 0}h dedicadas'
                            : '0h',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRecordCard(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFF59E0B),
                        badge: 'OBRA MAESTRA',
                        title: masterpieceGame?.title ?? 'Sin 5 estrellas',
                        stat: masterpieceGame != null
                            ? '5★ • ${masterpieceGame.hoursPlayed ?? 0}h'
                            : 'Sin calificar',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildRecordCard(
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF10B981),
                        badge: 'AVENTURA ÁGIL',
                        title: agileGame?.title ?? 'Sin títulos',
                        stat: agileGame != null
                            ? '${agileGame.hoursPlayed ?? 0}h'
                            : '0h',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // Pie chart: Status distribution
              Text(
                'Distribución por Estado',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: totalGames == 0
                    ? Center(
                        child: Text(
                          'Sin datos',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      )
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 45,
                          sections: statusData.entries
                              .where((e) => e.value > 0)
                              .map((e) {
                            final pct =
                                (e.value / totalGames * 100).toStringAsFixed(0);
                            return PieChartSectionData(
                              color: _getStatusColor(e.key),
                              value: e.value.toDouble(),
                              title: '$pct%',
                              radius: 46,
                              titleStyle: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 20,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: statusData.entries.where((e) => e.value > 0).map((e) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getStatusColor(e.key),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${e.key} (${e.value})',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // Platform chart
              Text(
                'Plataformas en Biblioteca',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 260,
                child: platformData.isEmpty
                    ? Center(
                        child: Text(
                          'Sin datos',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: math.max(
                              MediaQuery.of(context).size.width - 32,
                              platformData.length * 65.0),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: platformData.values
                                      .map((m) =>
                                          m.values.reduce((a, b) => a + b))
                                      .reduce((a, b) => a > b ? a : b)
                                      .toDouble() *
                                  1.15,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final keys = platformData.keys.toList();
                                      if (value.toInt() >= keys.length) {
                                        return const SizedBox();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          keys[value.toInt()],
                                          style: GoogleFonts.inter(
                                            color: AppColors.textSecondary(
                                                context),
                                            fontSize: 9,
                                          ),
                                        ),
                                      );
                                    },
                                    reservedSize: 36,
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: platformData.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final int index = entry.key;
                                final map = entry.value.value;
                                double currentY = 0;
                                final List<BarChartRodStackItem> stackItems =
                                    [];

                                for (var status in [
                                  'Jugado',
                                  'Jugando',
                                  'Por jugar'
                                ]) {
                                  final int count = map[status] ?? 0;
                                  if (count > 0) {
                                    stackItems.add(BarChartRodStackItem(
                                      currentY,
                                      currentY + count,
                                      _getStatusColor(status),
                                    ));
                                    currentY += count;
                                  }
                                }

                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: currentY,
                                      width: 18,
                                      rodStackItems: stackItems,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 36),

              // Top rated
              if (topRated.isNotEmpty) ...[
                Text(
                  'Tus Mejores Calificaciones',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 16),
                ...topRated.map((game) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border(context),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (game.platform != null &&
                              game.platform!.isNotEmpty) ...[
                            PlatformHelper.getIcon(game.platform!, size: 16),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              game.title,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            game.rating ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35), width: 1),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard({
    required IconData icon,
    required Color color,
    required String badge,
    required String title,
    required String stat,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                badge,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditGoalDialog extends StatefulWidget {
  final int year;
  final int initialGoal;

  const _EditGoalDialog({
    required this.year,
    required this.initialGoal,
  });

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Text(
        'Meta Anual ${widget.year}',
        style: GoogleFonts.outfit(
          color: AppColors.textPrimary(context),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuántos juegos te propones completar durante el año ${widget.year}?',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceSubtle(context),
              suffixText: 'juegos',
              suffixStyle:
                  GoogleFonts.inter(color: AppColors.textSecondary(context)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFDC2626)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final val = int.tryParse(_controller.text.trim());
            Navigator.pop(context, val);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Guardar',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

