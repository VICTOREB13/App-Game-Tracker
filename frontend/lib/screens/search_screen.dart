import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../services/notion_service.dart';
import '../services/notion_parser.dart';
import '../widgets/platform_helper.dart';

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

  final List<String> _allAvailableGenres = [
    'Acción', 'Aventura', 'Acción-aventura', 'RPG', 'Rol', 'Rol de acción',
    'Disparos', 'Shooter', 'Estrategia', 'Simulador', 'Simulación',
    'Plataformas', 'Lucha', 'Puzle', 'Arcade', 'Casual', 'Indie',
    'MMORPG', 'Massively Multiplayer', 'Hack and Slash', 'Souls', 'Soulslike',
    'Metroidvania', 'Roguelike', 'Terror y supervivencia', 'Carreras',
    'Anime', 'Gacha', 'Sigilo', 'Zombies',
  ];

  final List<String> _availablePlatforms = [
    'PC', 'Mac', 'Mobile',
    'Playstation 5', 'Playstation 4', 'Playstation 3',
    'Playstation 2', 'Playstation 1',
    'Xbox', 'Nintendo Switch', 'Wii U',
    'Nintendo 64', 'Nintendo DS',
    'GOG', 'Epic Games',
  ];

  final List<String> _availableStatuses = [
    'Por jugar',
    'Jugando',
    'Jugado',
  ];

  @override
  void initState() {
    super.initState();
    _loadRawgKey();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRawgKey() async {
    final prefs = await SharedPreferences.getInstance();
    _rawgKey = prefs.getString('rawg_key') ?? '';
  }

  Future<void> _searchGames(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    if (_rawgKey == null || _rawgKey!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Configura tu RAWG API Key en Configuración para buscar juegos',
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
          'https://api.rawg.io/api/games?key=$_rawgKey&search=$trimmed&page_size=15'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['results'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error searching RAWG: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _promptGameDetails(Map<String, dynamic> rawgGame) async {
    String selectedStatus = 'Por jugar';
    String selectedPlatform = 'PC';
    DateTime? selectedStartDate;
    final hoursController = TextEditingController(text: '0');
    bool isGenreAccordionExpanded = false;

    // Extract genres from RAWG
    final List<String> selectedGenres = [];
    if (rawgGame['genres'] != null && rawgGame['genres'] is List) {
      for (var g in rawgGame['genres']) {
        final name = g['name']?.toString();
        if (name != null && name.isNotEmpty) {
          // Normalize matching with Notion options if found
          final match = _allAvailableGenres.firstWhere(
            (gen) => gen.toLowerCase() == name.toLowerCase(),
            orElse: () => name,
          );
          if (!selectedGenres.contains(match)) {
            selectedGenres.add(match);
          }
        }
      }
    }

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF141927),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF1C2237)),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Game Title and Cover
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: rawgGame['background_image'] != null
                              ? CachedNetworkImage(
                                  imageUrl: rawgGame['background_image'],
                                  width: 60,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    width: 60,
                                    height: 80,
                                    color: const Color(0xFF1C2237),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    width: 60,
                                    height: 80,
                                    color: const Color(0xFF1C2237),
                                    child: const Icon(Icons.gamepad_rounded,
                                        size: 24, color: Color(0xFF3A4060)),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 80,
                                  color: const Color(0xFF1C2237),
                                  child: const Icon(Icons.gamepad_rounded,
                                      size: 24, color: Color(0xFF3A4060)),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rawgGame['name'] ?? 'Juego',
                                style: GoogleFonts.spaceGrotesk(
                                  color: const Color(0xFFF0F2F5),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rawgGame['released'] != null
                                    ? 'Lanzamiento: ${rawgGame['released']}'
                                    : 'Sin fecha de lanzamiento',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF6B7394),
                                  fontSize: 12,
                                ),
                              ),
                              if (rawgGame['playtime'] != null &&
                                  rawgGame['playtime'] > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'HLTB estimado: ${rawgGame['playtime']}h',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF00F0FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF1C2237)),
                    const SizedBox(height: 8),

                    // Scrollable form fields
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Estado & Plataforma
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Estado',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFFA1A1AA),
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      DropdownButtonFormField<String>(
                                        value: selectedStatus,
                                        dropdownColor: const Color(0xFF18181B),
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: const Color(0xFFFAFAFA)),
                                        items: _availableStatuses
                                            .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 13))))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setDialogState(
                                                () => selectedStatus = val);
                                          }
                                        },
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Plataforma',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFFA1A1AA),
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      DropdownButtonFormField<String>(
                                        value: selectedPlatform,
                                        dropdownColor: const Color(0xFF18181B),
                                        borderRadius: BorderRadius.circular(12),
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: const Color(0xFFFAFAFA)),
                                        items: _availablePlatforms
                                            .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    PlatformHelper.getIcon(s, size: 14),
                                                    const SizedBox(width: 8),
                                                    Text(s,
                                                        style: GoogleFonts.inter(
                                                            fontSize: 13)),
                                                  ],
                                                )))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setDialogState(
                                                () => selectedPlatform = val);
                                          }
                                        },
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Fecha de Inicio & Horas Jugadas
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Fecha de Inicio',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFFA1A1AA),
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedStartDate ??
                                                DateTime.now(),
                                            firstDate: DateTime(1980),
                                            lastDate: DateTime.now()
                                                .add(const Duration(days: 365)),
                                            builder: (context, child) => Theme(
                                              data: ThemeData.dark().copyWith(
                                                colorScheme:
                                                    const ColorScheme.dark(
                                                  primary: Color(0xFFDC2626),
                                                  surface: Color(0xFF121215),
                                                ),
                                              ),
                                              child: child!,
                                            ),
                                          );
                                          if (picked != null) {
                                            setDialogState(() =>
                                                selectedStartDate = picked);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 11),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF141927),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: const Color(0xFF1C2237)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.calendar_today_rounded,
                                                      size: 14,
                                                      color: Color(0xFF00F0FF)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    selectedStartDate == null
                                                        ? 'Sin fecha'
                                                        : DateFormat('dd/MM/yyyy')
                                                            .format(
                                                                selectedStartDate!),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: selectedStartDate ==
                                                              null
                                                          ? const Color(0xFF6B7394)
                                                          : const Color(
                                                              0xFFF0F2F5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (selectedStartDate != null)
                                                GestureDetector(
                                                  onTap: () => setDialogState(
                                                      () => selectedStartDate =
                                                          null),
                                                  child: const Icon(
                                                      Icons.close_rounded,
                                                      size: 14,
                                                      color: Color(0xFF6B7394)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Horas Jugadas',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFF6B7394),
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: hoursController,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: const Color(0xFFF0F2F5)),
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.timer_outlined,
                                              size: 16,
                                              color: Color(0xFF6B7394)),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Desplegable / Acordeón de Géneros
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C2237).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isGenreAccordionExpanded
                                        ? const Color(0xFF00F0FF).withOpacity(0.4)
                                        : const Color(0xFF1C2237)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        isGenreAccordionExpanded =
                                            !isGenreAccordionExpanded;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.category_rounded,
                                                  size: 16,
                                                  color: Color(0xFF00F0FF)),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Géneros',
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      const Color(0xFFF0F2F5),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00F0FF)
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${selectedGenres.length}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        const Color(0xFF00F0FF),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            isGenreAccordionExpanded
                                                ? Icons.keyboard_arrow_up_rounded
                                                : Icons.keyboard_arrow_down_rounded,
                                            color: const Color(0xFF6B7394),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isGenreAccordionExpanded) ...[
                                    const Divider(
                                        height: 1, color: Color(0xFF1C2237)),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: _allAvailableGenres.map((g) {
                                          final isSelected =
                                              selectedGenres.contains(g);
                                          return FilterChip(
                                            label: Text(
                                              g,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? const Color(0xFF0A0E1A)
                                                    : const Color(0xFF6B7394),
                                              ),
                                            ),
                                            selected: isSelected,
                                            selectedColor:
                                                const Color(0xFFDC2626),
                                            backgroundColor:
                                                const Color(0xFF18181B),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? Colors.transparent
                                                  : const Color(0xFF27272A),
                                            ),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            showCheckmark: false,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 0),
                                            onSelected: (val) {
                                              setDialogState(() {
                                                if (val) {
                                                  selectedGenres.add(g);
                                                } else {
                                                  selectedGenres.remove(g);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ] else if (selectedGenres.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 0, 14, 10),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              selectedGenres.join(' • '),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFFA1A1AA),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(
                                color: const Color(0xFFA1A1AA)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            'Añadir a Notion',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (shouldSave == true) {
      await _addGameToNotion(
        rawgGame: rawgGame,
        status: selectedStatus,
        platform: selectedPlatform,
        startDate: selectedStartDate,
        hoursPlayed: double.tryParse(hoursController.text) ?? 0,
        genres: selectedGenres,
      );
    }
  }

  Future<void> _addGameToNotion({
    required Map<String, dynamic> rawgGame,
    required String status,
    required String platform,
    required DateTime? startDate,
    required num hoursPlayed,
    required List<String> genres,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFDC2626)),
      ),
    );

    try {
      final notion = NotionService.instance;

      // Build properties
      final properties = <String, dynamic>{
        'Título': NotionParser.buildTitle(rawgGame['name'] ?? 'Sin nombre'),
        'Estado': NotionParser.buildStatus(status),
        'Plataforma': NotionParser.buildSelect(platform),
        'Horas Jugadas': NotionParser.buildNumber(hoursPlayed),
      };

      if (startDate != null) {
        properties['Fecha de Inicio'] = NotionParser.buildDate(startDate);
      }

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
      if (rawgGame['playtime'] != null && rawgGame['playtime'] > 0) {
        properties['HLTB Principal'] =
            NotionParser.buildNumber(rawgGame['playtime']);
      }

      await notion.createPage(notion.gamesDbId, properties);

      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${rawgGame['name']} añadido a Notion con éxito',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true); // Return to dashboard
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar en Notion: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar y Añadir Juegos',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onSubmitted: _searchGames,
                style: GoogleFonts.inter(
                    fontSize: 15, color: const Color(0xFFF0F2F5)),
                decoration: InputDecoration(
                  hintText: 'Buscar juego en RAWG (ej: Elden Ring, Hollow Knight)...',
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
                          icon: const Icon(Icons.clear, color: Color(0xFF6B7394)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        ),
                  filled: true,
                  fillColor: const Color(0xFF141927),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1C2237)),
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
                            Icon(Icons.sports_esports_rounded,
                                size: 64,
                                color: const Color(0xFF6B7394).withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'Escribe el nombre de un juego para buscar',
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
                          final genreNames = (game['genres'] as List? ?? [])
                              .map((g) => g['name']?.toString() ?? '')
                              .where((s) => s.isNotEmpty)
                              .take(3)
                              .join(' • ');

                          return Card(
                            color: const Color(0xFF141927),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF1C2237)),
                            ),
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
                                            imageUrl: game['background_image'],
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
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
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
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            game['released'] ?? 'Sin fecha',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF6B7394),
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (genreNames.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              genreNames,
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF00F0FF)
                                                    .withOpacity(0.8),
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00F0FF)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFF00F0FF)
                                                .withOpacity(0.3)),
                                      ),
                                      child: const Icon(Icons.add_rounded,
                                          color: Color(0xFF00F0FF), size: 20),
                                    ),
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
      ),
    );
  }
}
