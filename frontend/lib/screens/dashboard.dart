import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/game.dart';
import '../services/notion_service.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'game_detail_screen.dart';
import 'analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _notion = NotionService.instance;
  final _searchController = TextEditingController();

  List<Game> _games = [];
  List<Game> _filteredGames = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSearchActive = false;
  String _searchQuery = '';
  String _selectedStatusFilter = 'Todos';
  String _selectedSort = 'Recientes';

  final List<String> _statusFilters = [
    'Todos',
    'Jugando',
    'Por jugar',
    'Jugado',
  ];

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGames({bool forceRefresh = false}) async {
    try {
      final pages = await _notion.getGames(useCache: !forceRefresh);
      final loadedGames =
          pages.map((page) => Game.fromNotionPage(page)).toList();

      if (mounted) {
        setState(() {
          _games = loadedGames;
          _applyFilters();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar juegos de Notion: $e'),
            backgroundColor: const Color(0xFFFF2D78),
          ),
        );
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
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

        // Search query filter (matches title, platform, or genres)
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          final titleMatch = g.title.toLowerCase().contains(query);
          final platformMatch =
              g.platform != null && g.platform!.toLowerCase().contains(query);
          final genreMatch = g.genres
              .any((genre) => genre.toLowerCase().contains(query));
          matchesQuery = titleMatch || platformMatch || genreMatch;
        }

        return matchesStatus && matchesQuery;
      }).toList();

      if (_selectedSort == 'A-Z') {
        _filteredGames.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      }
      // "Recientes" maintains the Notion last_edited_time DESC sorting
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchActive
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(
                    fontSize: 15, color: const Color(0xFFF0F2F5)),
                decoration: InputDecoration(
                  hintText: 'Buscar en tu biblioteca...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF6B7394)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF00F0FF), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF6B7394), size: 20),
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
            : Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00F0FF),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x5500F0FF),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mi Biblioteca',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              color: _isSearchActive
                  ? const Color(0xFFFF2D78)
                  : const Color(0xFF00F0FF),
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
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF00F0FF)),
                    )
                  : const Icon(Icons.refresh_rounded, color: Color(0xFF00F0FF)),
              tooltip: 'Refrescar de Notion',
              onPressed: _isRefreshing
                  ? null
                  : () {
                      setState(() => _isRefreshing = true);
                      _fetchGames(forceRefresh: true);
                    },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFFFFBE0B)),
              tooltip: 'Estadísticas',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Color(0xFF6B7394)),
              tooltip: 'Configuración',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                if (result == true) _fetchGames(forceRefresh: true);
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ..._statusFilters.map(_buildFilterChip),
                  const SizedBox(width: 12),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFF1C2237),
                  ),
                  const SizedBox(width: 12),
                  _buildSortDropdown(),
                ],
              ),
            ),
          ),

          // Search indicator & Game count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredGames.length} de ${_games.length} juegos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7394),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFF00F0FF).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Filtro: "$_searchQuery"',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF00F0FF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Grid with Responsive Breakpoints (Mobile, Tablet, Desktop)
          Expanded(
            child: _isLoading
                ? _buildSkeletonGrid()
                : RefreshIndicator(
                    color: const Color(0xFF00F0FF),
                    backgroundColor: const Color(0xFF141927),
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
                                    color: const Color(0xFF6B7394)
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No se encontraron juegos para "$_searchQuery"'
                                        : 'No hay juegos con el filtro "$_selectedStatusFilter"',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF6B7394),
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                          _applyFilters();
                                        });
                                      },
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 16),
                                      label: const Text('Limpiar búsqueda'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF00F0FF),
                                        side: const BorderSide(
                                            color: Color(0xFF00F0FF)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: _filteredGames.length,
                            itemBuilder: (context, index) {
                              final game = _filteredGames[index];
                              return GestureDetector(
                                onTap: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GameDetailScreen(game: game),
                                    ),
                                  );
                                  if (res == true) {
                                    _fetchGames(forceRefresh: true);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          );
          if (res == true) _fetchGames(forceRefresh: true);
        },
        backgroundColor: const Color(0xFF00F0FF),
        foregroundColor: const Color(0xFF0A0E1A),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Añadir',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedStatusFilter == label;
    Color chipColor;
    switch (label) {
      case 'Jugando':
        chipColor = const Color(0xFF00F0FF);
        break;
      case 'Por jugar':
        chipColor = const Color(0xFFFFBE0B);
        break;
      case 'Jugado':
        chipColor = const Color(0xFFFF2D78);
        break;
      default:
        chipColor = const Color(0xFF6B7394);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? const Color(0xFF0A0E1A) : chipColor,
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
        backgroundColor: chipColor.withOpacity(0.1),
        side: BorderSide(
          color: isSelected ? Colors.transparent : chipColor.withOpacity(0.3),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2237),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          dropdownColor: const Color(0xFF1C2237),
          style: GoogleFonts.inter(
              fontSize: 12, color: const Color(0xFFF0F2F5)),
          icon: const Icon(Icons.sort_rounded,
              size: 16, color: Color(0xFF6B7394)),
          items: ['Recientes', 'A-Z']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedSort = val!;
              _applyFilters();
            });
          },
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
            color: const Color(0xFF141927),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1C2237)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C2237),
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
                        color: const Color(0xFF1C2237),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2237),
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

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  Color _getStatusColor() {
    switch (game.status) {
      case 'Jugando':
        return const Color(0xFF00F0FF);
      case 'Jugado':
        return const Color(0xFFFF2D78);
      case 'Por jugar':
        return const Color(0xFFFFBE0B);
      default:
        return const Color(0xFF6B7394);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141927),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1C2237),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                game.coverUrl != null && game.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: game.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF1C2237),
                          child: const Center(
                            child: Icon(Icons.gamepad_rounded,
                                color: Color(0xFF3A4060), size: 32),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF1C2237),
                          child: const Center(
                            child: Icon(Icons.gamepad_rounded,
                                color: Color(0xFF3A4060), size: 32),
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF1C2237),
                        child: const Center(
                          child: Icon(Icons.gamepad_rounded,
                              color: Color(0xFF3A4060), size: 32),
                        ),
                      ),
                // Gradient overlay at bottom of image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xFF141927)],
                      ),
                    ),
                  ),
                ),
                // Status indicator - top right neon dot
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
                        color: const Color(0xFF0A0E1A).withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFFFBE0B).withOpacity(0.5),
                            width: 0.5),
                      ),
                      child: Text(
                        game.rating!,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: const Color(0xFFFFBE0B),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF0F2F5),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        game.platform ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7394),
                          fontSize: 11,
                        ),
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
