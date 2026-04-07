import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final supabase = Supabase.instance.client;
  List<Game> _games = [];
  bool _isLoading = true;
  
  // Filtros
  String _selectedProvider = 'Todos';
  String _selectedPlatform = 'Todas';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase.from('games').select().eq('user_id', user.id);
    
    if (mounted) {
      setState(() {
        _games = (data as List).map((e) => Game.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }

  List<Game> get _filteredGames {
    return _games.where((g) {
      if (_selectedProvider != 'Todos' && g.provider != _selectedProvider) return false;
      if (_selectedPlatform != 'Todas' && g.platform != _selectedPlatform) return false;
      return true;
    }).toList();
  }

  // --- LÓGICA GRÁFICO TORTA (ESTADOS) ---
  Map<String, int> _getStatusData() {
    final Map<String, int> counts = {'Completado': 0, 'Jugando': 0, 'Por Jugar': 0, 'Pausado': 0, 'Abandonado': 0};
    for (var g in _filteredGames) {
      final status = g.status ?? 'Por Jugar';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completado': return Colors.amber;
      case 'Jugando': return Colors.greenAccent;
      case 'Por Jugar': return Colors.blueAccent;
      case 'Pausado': return Colors.orangeAccent;
      case 'Abandonado': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  // --- LÓGICA BARRAS APILADAS (PLATAFORMA VS ESTADO) ---
  Map<String, Map<String, int>> _getPlatformData() {
    final Map<String, Map<String, int>> data = {};
    for (var g in _filteredGames) {
      final plat = g.platform ?? 'Otra';
      final stat = g.status ?? 'Por Jugar';
      if (!data.containsKey(plat)) {
        data[plat] = {'Completado': 0, 'Jugando': 0, 'Por Jugar': 0, 'Pausado': 0, 'Abandonado': 0};
      }
      data[plat]![stat] = (data[plat]![stat] ?? 0) + 1;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFF0F172A), body: Center(child: CircularProgressIndicator()));
    }

    final statusData = _getStatusData();
    final platformData = _getPlatformData();
    final totalGames = _filteredGames.length;

    // Obtener listas únicas
    final providers = ['Todos', ..._games.map((e) => e.provider ?? 'Notion').toSet().toList()];
    final platforms = ['Todas', ..._games.map((e) => e.platform ?? 'Otra').toSet().toList()];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Estadísticas'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FILTROS
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    value: _selectedProvider,
                    items: providers.map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(value: p, child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedProvider = v!),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    value: _selectedPlatform,
                    items: platforms.map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(value: p, child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedPlatform = v!),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // 1. GRÁFICO DE TORTA
          const Text('Distribución por Estados', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: totalGames == 0 ? const Center(child: Text("Sin datos")) : PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: statusData.entries.where((e) => e.value > 0).map((e) {
                  final percentage = (e.value / totalGames * 100).toStringAsFixed(1);
                  return PieChartSectionData(
                    color: _getStatusColor(e.key),
                    value: e.value.toDouble(),
                    title: '$percentage%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Leyenda de Torta
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: statusData.entries.where((e) => e.value > 0).map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: _getStatusColor(e.key)),
                  const SizedBox(width: 4),
                  Text('${e.key} (${e.value})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 48),

          // 2. GRÁFICO DE BARRAS APILADAS
          const Text('Dominancia de Plataformas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: platformData.isEmpty ? const Center(child: Text("Sin datos")) : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(MediaQuery.of(context).size.width - 32, platformData.length * 70.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: platformData.values.map((map) => map.values.reduce((a, b) => a + b)).reduce((a, b) => a > b ? a : b).toDouble() * 1.1,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final keys = platformData.keys.toList();
                            if (value.toInt() >= keys.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(keys[value.toInt()], style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barGroups: platformData.entries.toList().asMap().entries.map((entry) {
                      final int index = entry.key;
                      final map = entry.value.value;
                      double currentY = 0;
                      final List<BarChartRodStackItem> stackItems = [];
                      
                      // Orden de dibujado (de abajo hacia arriba)
                      for (var status in ['Completado', 'Jugando', 'Por Jugar', 'Pausado', 'Abandonado']) {
                        final int count = map[status] ?? 0;
                        if (count > 0) {
                          stackItems.add(BarChartRodStackItem(currentY, currentY + count, _getStatusColor(status)));
                          currentY += count;
                        }
                      }

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: currentY,
                            width: 20,
                            rodStackItems: stackItems,
                            borderRadius: BorderRadius.circular(2),
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
