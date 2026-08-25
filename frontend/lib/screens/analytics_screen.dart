import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game.dart';
import '../services/notion_service.dart';
import '../widgets/platform_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _notion = NotionService.instance;
  List<Game> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final pages = await _notion.getGames();
      if (mounted) {
        setState(() {
          _games = pages.map((p) => Game.fromNotionPage(p)).toList();
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
        return const Color(0xFFFF2D78);
      case 'Jugando':
        return const Color(0xFF00F0FF);
      case 'Por jugar':
        return const Color(0xFFFFBE0B);
      default:
        return const Color(0xFF6B7394);
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
    final rated =
        _games.where((g) => g.rating != null && ratingOrder.contains(g.rating)).toList();
    rated.sort((a, b) {
      final ai = ratingOrder.indexOf(a.rating!);
      final bi = ratingOrder.indexOf(b.rating!);
      return ai.compareTo(bi);
    });
    return rated.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
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
    final totalBacklogHours = backlogGames.fold<num>(
        0, (sum, g) => sum + (g.hltbMain ?? 0));

    // Current Year Stats
    final currentYear = DateTime.now().year;
    final completedThisYear = _games.where((g) {
      if (g.status != 'Jugado') return false;
      if (g.completedDate != null) {
        return g.completedDate!.year == currentYear;
      }
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas & Analíticas', style: GoogleFonts.spaceGrotesk()),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards Row 1
              Row(
                children: [
                  _buildStatCard('Total Juegos', totalGames.toString(),
                      const Color(0xFF00F0FF)),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      'Horas Jugadas',
                      totalHours % 1 == 0
                          ? totalHours.toInt().toString()
                          : totalHours.toStringAsFixed(1),
                      const Color(0xFFFF2D78)),
                  const SizedBox(width: 10),
                  _buildStatCard(
                      'Terminados',
                      (statusData['Jugado'] ?? 0).toString(),
                      const Color(0xFFFFBE0B)),
                ],
              ),
              const SizedBox(height: 20),

              // Backlog Pulse & Year Review Highlights
              Row(
                children: [
                  // Backlog Calculator
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141927),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFFFBE0B).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.hourglass_top_rounded,
                                  size: 16, color: Color(0xFFFFBE0B)),
                              const SizedBox(width: 6),
                              Text(
                                'Calculadora de Backlog',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFBE0B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalBacklogHours > 0
                                ? '~${totalBacklogHours.toInt()} horas'
                                : '0 horas',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF0F2F5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${backlogGames.length} juegos pendientes por jugar',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B7394),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Year in Review
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141927),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF00F0FF).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  size: 16, color: Color(0xFF00F0FF)),
                              const SizedBox(width: 6),
                              Text(
                                'Completados $currentYear',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00F0FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${completedThisYear.length} juegos',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF0F2F5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            completedThisYear.isNotEmpty
                                ? 'Victorias de este año'
                                : 'Aún sin títulos en $currentYear',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B7394),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Pie chart
              Text('Distribución por Estado',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: totalGames == 0
                    ? Center(
                        child: Text('Sin datos',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF6B7394))))
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
                              radius: 50,
                              titleStyle: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0A0E1A),
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
                            color: const Color(0xFF6B7394), fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Platform chart
              Text('Plataformas en Biblioteca',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: platformData.isEmpty
                    ? Center(
                        child: Text('Sin datos',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF6B7394))))
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
                                              color: const Color(0xFF6B7394),
                                              fontSize: 9),
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
                                final List<BarChartRodStackItem> stackItems = [];

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
              const SizedBox(height: 40),

              // Top rated
              if (topRated.isNotEmpty) ...[
                Text('Tus Mejores Calificaciones',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...topRated.map((game) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141927),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: const Color(0xFF1C2237), width: 1),
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
                                color: const Color(0xFFF0F2F5),
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
                                fontSize: 14, color: const Color(0xFFFFBE0B)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 10, color: const Color(0xFF6B7394)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
