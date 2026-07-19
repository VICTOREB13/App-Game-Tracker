import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notion_service.dart';
import '../services/notion_parser.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String? _rawgKey;

  @override
  void initState() {
    super.initState();
    _loadRawgKey();
  }

  Future<void> _loadRawgKey() async {
    final prefs = await SharedPreferences.getInstance();
    _rawgKey = prefs.getString('rawg_key') ?? '';
  }

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    if (_rawgKey == null || _rawgKey!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Configura tu RAWG API Key en Settings para buscar juegos',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFFFBE0B),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await http.get(Uri.parse(
          'https://api.rawg.io/api/games?key=$_rawgKey&search=$query&page_size=10'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['results'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error searching RAWG: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _promptGameDetails(Map<String, dynamic> rawgGame) async {
    String selectedStatus = 'Por jugar';
    String selectedPlatform = 'PC';

    final List<String> availablePlatforms = [
      'PC', 'Mac', 'Mobile',
      'Playstation 5', 'Playstation 4', 'Playstation 3',
      'Playstation 2', 'Playstation 1',
      'Xbox', 'Nintendo Switch', 'Wii U',
      'Nintendo 64', 'Nintendo DS',
      'GOG', 'Epic Games',
    ];

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF141927),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                rawgGame['name'] ?? 'Juego',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFF0F2F5),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado:',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B7394), fontSize: 12)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1C2237),
                    value: selectedStatus,
                    items: ['Por jugar', 'Jugando', 'Jugado']
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: GoogleFonts.inter(
                                    color: const Color(0xFFF0F2F5)))))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedStatus = val!),
                  ),
                  const SizedBox(height: 16),
                  Text('Plataforma:',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B7394), fontSize: 12)),
                  const SizedBox(height: 4),
                  DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1C2237),
                    value: selectedPlatform,
                    items: availablePlatforms
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: GoogleFonts.inter(
                                    color: const Color(0xFFF0F2F5),
                                    fontSize: 13))))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedPlatform = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B7394))),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Añadir',
                      style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave == true) {
      await _addGameToNotion(rawgGame, selectedStatus, selectedPlatform);
    }
  }

  Future<void> _addGameToNotion(
    Map<String, dynamic> rawgGame,
    String status,
    String platform,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child:
            CircularProgressIndicator(color: Color(0xFF00F0FF)),
      ),
    );

    try {
      final notion = NotionService.instance;

      // Build genres from RAWG
      List<String> genres = [];
      if (rawgGame['genres'] != null && rawgGame['genres'] is List) {
        genres = (rawgGame['genres'] as List)
            .map((g) => g['name'].toString())
            .toList();
      }

      // Build properties
      final properties = <String, dynamic>{
        'Título': NotionParser.buildTitle(rawgGame['name'] ?? 'Sin nombre'),
        'Estado': NotionParser.buildStatus(status),
        'Plataforma': NotionParser.buildSelect(platform),
        'Horas Jugadas': NotionParser.buildNumber(0),
      };

      if (genres.isNotEmpty) {
        properties['Géneros'] = NotionParser.buildMultiSelect(genres);
      }

      // Add cover if available
      final coverUrl = rawgGame['background_image'];
      if (coverUrl != null && coverUrl.toString().isNotEmpty) {
        properties['Portada'] =
            NotionParser.buildExternalFile(coverUrl.toString());
      }

      // Add HLTB from RAWG's playtime
      if (rawgGame['playtime'] != null) {
        properties['HLTB Principal'] =
            NotionParser.buildNumber(rawgGame['playtime']);
      }

      await notion.createPage(notion.gamesDbId, properties);

      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${rawgGame['name']} añadido a Notion',
                style: GoogleFonts.inter(color: const Color(0xFF0A0E1A))),
            backgroundColor: const Color(0xFF00F0FF),
          ),
        );
        Navigator.pop(context, true); // Return to dashboard
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFFF2D78),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Añadir Juego', style: GoogleFonts.spaceGrotesk()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: _searchGames,
              style: GoogleFonts.inter(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Buscar juego...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF6B7394)),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF00F0FF)),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF6B7394)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      ),
                filled: true,
                fillColor: const Color(0xFF141927),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty && !_isSearching
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded,
                              size: 64,
                              color: const Color(0xFF6B7394)
                                  .withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Busca en la librería de RAWG',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF6B7394),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final game = _searchResults[index];
                        return Card(
                          color: const Color(0xFF141927),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () => _promptGameDetails(game),
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: game['background_image'] != null
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              game['background_image'],
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 90,
                                          height: 90,
                                          color: const Color(0xFF1C2237),
                                          child: const Icon(
                                              Icons.gamepad_rounded,
                                              color: Color(0xFF3A4060)),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        game['name'] ?? '',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: const Color(0xFFF0F2F5),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        game['released'] ?? '',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF6B7394),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.add_circle_rounded,
                                      color: Color(0xFF00F0FF), size: 28),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
