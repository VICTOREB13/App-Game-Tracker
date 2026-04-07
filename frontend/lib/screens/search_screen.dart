import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  final String rawgKey = dotenv.env['RAWG_KEY'] ?? '';

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    
    try {
      final response = await http.get(Uri.parse('https://api.rawg.io/api/games?key=$rawgKey&search=$query&page_size=10'));
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
    String selectedStatus = 'Por Jugar';
    String selectedPlatform = 'PC';
    
    final List<String> availablePlatforms = [
      'PC', 'PlayStation 5', 'PlayStation 4', 'PlayStation 3', 'PlayStation 2', 'PlayStation 1',
      'PSP', 'PS Vita', 'Xbox Series X|S', 'Xbox One', 'Xbox 360', 'Xbox Original',
      'Nintendo Switch', 'Wii U', 'Wii', 'GameCube', 'Nintendo 64', 'SNES', 'NES',
      'Nintendo 3DS', 'Nintendo DS', 'Game Boy Advance', 'Game Boy', 
      'Sega Genesis', 'Sega Dreamcast', 'Mobile', 'Otra'
    ];
    
    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text('Detalles de ${rawgGame['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estado de Juego:', style: TextStyle(color: Colors.white70)),
                  DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    value: selectedStatus,
                    items: ['Por Jugar', 'Jugando', 'Pausado', 'Completado', 'Abandonado']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                  const SizedBox(height: 16),
                  const Text('Plataforma:', style: TextStyle(color: Colors.white70)),
                  DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    value: selectedPlatform,
                    items: availablePlatforms
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) => setState(() => selectedPlatform = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true), 
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  child: const Text('Añadir Juego', style: TextStyle(color: Colors.white))
                ),
              ],
            );
          }
        );
      }
    );

    if (shouldSave == true) {
      await _addGameToSupabase(rawgGame, selectedStatus, selectedPlatform);
    }
  }

  Future<void> _addGameToSupabase(Map<String, dynamic> rawgGame, String status, String platform) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      String? genresStr;
      if (rawgGame['genres'] != null && rawgGame['genres'] is List) {
        genresStr = (rawgGame['genres'] as List).map((g) => g['name'].toString()).join(', ');
      }
      
      String? tagsStr;
      if (rawgGame['tags'] != null && rawgGame['tags'] is List) {
        tagsStr = (rawgGame['tags'] as List).map((t) => t['name'].toString()).join(', ');
      }

      final payload = {
        'title': rawgGame['name'],
        'cover_url': rawgGame['background_image'],
        'status': status,
        'platform': platform,
        'external_id': rawgGame['id'].toString(),
        'hours_played': 0.0,
        'is_manual': true,
        if (genresStr != null && genresStr.isNotEmpty) 'genre': genresStr,
        if (tagsStr != null && tagsStr.isNotEmpty) 'tags': tagsStr,
      };

      if (user != null) {
        payload['user_id'] = user.id;
      }

      await supabase.from('games').insert(payload);

      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Cierra loader
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${rawgGame['name']} añadido con éxito')));
      // ignore: use_build_context_synchronously
      Navigator.pop(context, true); // Retorna true para indicarle al Dashboard que refresque

    } catch (e) {
      Navigator.pop(context); // Cierra loader
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error al guardar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Juego'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onSubmitted: _searchGames,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: "Escribe el nombre del juego...",
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _isSearching
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty && !_isSearching
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.video_library, size: 80, color: Colors.white24),
                        SizedBox(height: 16),
                        Text("Busca en la librería de RAWG", style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final game = _searchResults[index];
                        return Card(
                          color: Theme.of(context).colorScheme.surface,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            onTap: () => _promptGameDetails(game),
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                  child: game['background_image'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: game['background_image'],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(width: 100, height: 100, color: Colors.black26, child: const Icon(Icons.image)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(game['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 2),
                                      const SizedBox(height: 4),
                                      Text(game['released'] ?? 'Fecha desconocida', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Icon(Icons.add_circle, color: Colors.blueAccent, size: 30),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
