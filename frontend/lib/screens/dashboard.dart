import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'game_detail_screen.dart';
import 'analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  List<Game> _games = [];
  List<Game> _filteredGames = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'Todos';
  String _selectedSort = 'Recientes';

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Ordenar por last_played_at DESC (Style Steam)
      final data = await supabase
          .from('games')
          .select()
          .eq('user_id', user.id)
          .order('last_played_at', ascending: false);

      final List<Game> loadedGames = (data as List).map((json) => Game.fromJson(json)).toList();
      
      if (mounted) {
        setState(() {
          _games = loadedGames;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar juegos: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredGames = _games.where((g) {
        if (_selectedStatusFilter == 'Todos') return true;
        return g.status == _selectedStatusFilter;
      }).toList();

      if (_selectedSort == 'A-Z') {
        _filteredGames.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      }
    });
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mi Biblioteca', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.blueAccent), onPressed: () {
            setState(() => _isLoading = true);
            _fetchGames();
          }),
          IconButton(
            icon: const Icon(Icons.pie_chart, color: Colors.amber),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _fetchGames(); // Refrescar al volver
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          // Barra de Filtros y Orden
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Todos'),
                _buildFilterChip('Jugando'),
                _buildFilterChip('Por Jugar'),
                _buildFilterChip('Pausado'),
                _buildFilterChip('Completado'),
                const SizedBox(width: 16),
                const VerticalDivider(color: Colors.white24),
                DropdownButton<String>(
                  value: _selectedSort,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  underline: Container(),
                  items: ['Recientes', 'A-Z'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSort = val!;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchGames,
                    child: _filteredGames.isEmpty
                        ? const Center(child: Text('No hay juegos que mostrar', style: TextStyle(color: Colors.white54)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65, // Ajustado para evitar saltos
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredGames.length,
                            itemBuilder: (context, index) {
                              final game = _filteredGames[index];
                              return GestureDetector(
                                onTap: () async {
                                  final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)));
                                  if (res == true) {
                                    setState(() => _isLoading = true);
                                    _fetchGames();
                                  }
                                },
                                child: _GameCard(game: game),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
          if (res == true) _fetchGames();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedStatusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.black : Colors.white)),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedStatusFilter = label;
            _applyFilters();
          });
        },
        selectedColor: Colors.blueAccent,
        backgroundColor: Colors.grey[900],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con altura fija para evitar saltos
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: game.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: game.coverUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[800]),
                      errorWidget: (context, url, error) => const Icon(Icons.gamepad, color: Colors.white24, size: 40),
                    )
                  : Container(color: Colors.grey[800], child: const Icon(Icons.gamepad, color: Colors.white24, size: 40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(game.platform ?? 'Otra', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    _StatusBadge(status: game.status ?? 'Por Jugar'),
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
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = Colors.grey;
    if (status == 'Jugando') badgeColor = Colors.greenAccent;
    if (status == 'Completado') badgeColor = Colors.amber;
    if (status == 'Por Jugar') badgeColor = Colors.blueAccent;
    if (status == 'Pausado') badgeColor = Colors.orangeAccent;
    if (status == 'Abandonado') badgeColor = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: badgeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: badgeColor, width: 0.5)),
      child: Text(status, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
