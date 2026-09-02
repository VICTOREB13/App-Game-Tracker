import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/game.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../services/theme_manager.dart';
import '../services/metadata_service.dart';
import '../services/hltb_service.dart';
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

  String _canonicalPlatform(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower == 'pc' || lower.contains('steam') || lower.contains('windows')) {
      return 'PC';
    }
    if (lower.contains('playstation 5') || lower == 'ps5') return 'Playstation 5';
    if (lower.contains('playstation 4') || lower == 'ps4') return 'Playstation 4';
    if (lower.contains('playstation 3') || lower == 'ps3') return 'Playstation 3';
    if (lower.contains('playstation 2') || lower == 'ps2') return 'Playstation 2';
    if (lower.contains('playstation') || lower == 'ps1' || lower == 'psx') {
      return 'Playstation 1';
    }
    if (lower.contains('xbox series') ||
        lower.contains('xbox one') ||
        lower.contains('xbox 360') ||
        lower.contains('xbox')) {
      return 'Xbox';
    }
    if (lower.contains('switch')) return 'Nintendo Switch';
    if (lower.contains('wii u')) return 'Wii U';
    if (lower.contains('wii')) return 'Wii U';
    if (lower.contains('nintendo ds') ||
        lower.contains('3ds') ||
        lower.contains('ds')) {
      return 'Nintendo DS';
    }
    if (lower.contains('nintendo 64') || lower.contains('n64')) {
      return 'Nintendo 64';
    }
    if (lower.contains('mac') ||
        lower.contains('apple') ||
        lower.contains('macos')) {
      return 'Mac';
    }
    if (lower.contains('ios') ||
        lower.contains('android') ||
        lower.contains('mobile')) {
      return 'Mobile';
    }
    if (lower.contains('gog')) return 'GOG';
    if (lower.contains('epic')) return 'Epic Games';
    return raw;
  }

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
    _rawgKey = await SecureStorageService.instance.getRawgKey() ?? '';
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
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await http.get(Uri.parse(
          'https://api.rawg.io/api/games?key=$_rawgKey&search=$trimmed&page_size=15'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _searchResults = (data['results'] as List<dynamic>?) ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error searching RAWG: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _promptGameDetails(Map<String, dynamic> rawgGame) async {
    final result = await showDialog<_GameDetailsResult>(
      context: context,
      builder: (context) => _GameDetailsPromptDialog(
        rawgGame: rawgGame,
        availablePlatforms: _availablePlatforms,
        allAvailableGenres: _allAvailableGenres,
        canonicalPlatform: _canonicalPlatform,
      ),
    );

    if (result != null) {
      await _addGameToLibrary(
        rawgGame: rawgGame,
        status: result.status,
        platform: result.platform,
        startDate: result.startDate,
        hoursPlayed: result.hoursPlayed,
        genres: result.genres,
      );
    }
  }

  Future<void> _addGameToLibrary({
    required Map<String, dynamic> rawgGame,
    required String status,
    required String platform,
    required DateTime? startDate,
    required num hoursPlayed,
    required List<String> genres,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFDC2626)),
      ),
    );

    try {
      final title = rawgGame['name']?.toString() ?? 'Sin nombre';
      final coverUrl = rawgGame['background_image']?.toString();
      final playtime = (rawgGame['playtime'] as num?)?.toDouble();

      // Consultar Wikipedia para el enlace oficial
      String? wikiLink;
      try {
        wikiLink = await MetadataService.instance.searchWikipedia(title);
      } catch (e) {
        debugPrint('Error buscando Wikipedia para $title: $e');
      }

      // Consultar HowLongToBeat para duración exacta de Campaña y Completista
      num? finalHltbMain = playtime;
      num? finalHltbComp;
      try {
        final hltbData = await HltbService.instance.searchHltb(title);
        if (hltbData != null) {
          if (hltbData.mainStory != null) finalHltbMain = hltbData.mainStory;
          if (hltbData.completionist != null) finalHltbComp = hltbData.completionist;
        }
      } catch (e) {
        debugPrint('Error buscando HLTB para $title: $e');
      }

      DateTime? completedDate;
      String finalStatus = status;
      if (finalHltbMain != null &&
          finalHltbMain > 0 &&
          hoursPlayed >= finalHltbMain &&
          status != 'Jugado') {
        finalStatus = 'Jugado';
        completedDate = DateTime.now();
      }

      final newGame = Game(
        title: title,
        coverUrl: coverUrl,
        status: finalStatus,
        platform: platform,
        hoursPlayed: hoursPlayed,
        genres: genres,
        hltbMain: finalHltbMain,
        hltbCompletionist: finalHltbComp,
        link: wikiLink,
        startDate: startDate,
        completedDate: completedDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.insertGame(newGame);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡"${newGame.title}" añadido a tu biblioteca!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return to dashboard and refresh
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar en la biblioteca: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Buscar y Añadir Juegos',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
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
                  fontSize: 15,
                  color: AppColors.textPrimary(context),
                ),
                decoration: InputDecoration(
                  hintText:
                      'Buscar juego en RAWG (ej: Elden Ring, Hollow Knight)...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary(context),
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFFDC2626)),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.clear,
                              color: AppColors.textSecondary(context)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResults = []);
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.surface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.border(context)),
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
                                color: AppColors.textSecondary(context)
                                    .withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'Escribe el nombre de un juego para buscar',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final game = _searchResults[index] as Map<String, dynamic>;
                          final genreNames = ((game['genres'] as List<dynamic>?) ?? [])
                              .map((g) => (g as Map<String, dynamic>?)?['name']?.toString() ?? '')
                              .where((s) => s.isNotEmpty)
                              .take(3)
                              .join(' • ');

                          return Card(
                            color: AppColors.surface(context),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppColors.border(context)),
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
                                            imageUrl:
                                                game['background_image'].toString(),
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 90,
                                            height: 90,
                                            color: AppColors.surfaceSubtle(
                                                context),
                                            child: Icon(
                                              Icons.gamepad_rounded,
                                              color: AppColors.textSecondary(
                                                  context),
                                            ),
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
                                            game['name']?.toString() ?? '',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary(
                                                  context),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            game['released']?.toString() ?? 'Sin fecha',
                                            style: GoogleFonts.inter(
                                              color: AppColors.textSecondary(
                                                  context),
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (genreNames.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              genreNames,
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFFDC2626)
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
                                        color: const Color(0xFFDC2626)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFDC2626)
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 20,
                                      ),
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

class _GameDetailsResult {
  final String status;
  final String platform;
  final DateTime? startDate;
  final num hoursPlayed;
  final List<String> genres;

  _GameDetailsResult({
    required this.status,
    required this.platform,
    required this.startDate,
    required this.hoursPlayed,
    required this.genres,
  });
}

class _GameDetailsPromptDialog extends StatefulWidget {
  final Map<String, dynamic> rawgGame;
  final List<String> availablePlatforms;
  final List<String> allAvailableGenres;
  final String Function(String) canonicalPlatform;

  const _GameDetailsPromptDialog({
    required this.rawgGame,
    required this.availablePlatforms,
    required this.allAvailableGenres,
    required this.canonicalPlatform,
  });

  @override
  State<_GameDetailsPromptDialog> createState() =>
      _GameDetailsPromptDialogState();
}

class _GameDetailsPromptDialogState extends State<_GameDetailsPromptDialog> {
  late final TextEditingController _hoursController;
  String _selectedStatus = 'Por jugar';
  DateTime? _selectedStartDate;
  late String _selectedPlatform;
  final List<String> _detectedPlatforms = [];
  final List<String> _selectedGenres = [];
  bool _isGenreAccordionExpanded = false;
  bool _showAllPlatforms = false;

  final List<String> _availableStatuses = [
    'Por jugar',
    'Jugando',
    'Jugado',
  ];

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: '0');

    // Extraer plataformas detectadas
    if (widget.rawgGame['platforms'] != null &&
        widget.rawgGame['platforms'] is List) {
      for (final dynamic item in (widget.rawgGame['platforms'] as List<dynamic>)) {
        final pMap = item as Map<String, dynamic>?;
        final pName = (pMap?['platform'] as Map<String, dynamic>?)?['name']?.toString().trim();
        if (pName != null && pName.isNotEmpty) {
          final canonical = widget.canonicalPlatform(pName);
          if (!_detectedPlatforms.contains(canonical)) {
            _detectedPlatforms.add(canonical);
          }
        }
      }
    }

    _selectedPlatform = _detectedPlatforms.contains('PC')
        ? 'PC'
        : (_detectedPlatforms.isNotEmpty ? _detectedPlatforms.first : 'PC');

    // Extraer géneros devueltos por RAWG
    if (widget.rawgGame['genres'] != null &&
        widget.rawgGame['genres'] is List) {
      for (final dynamic g in (widget.rawgGame['genres'] as List<dynamic>)) {
        final gMap = g as Map<String, dynamic>?;
        final name = gMap?['name']?.toString().trim();
        if (name != null && name.isNotEmpty) {
          if (!_selectedGenres.contains(name)) {
            _selectedGenres.add(name);
          }
          if (!widget.allAvailableGenres.contains(name)) {
            widget.allAvailableGenres.add(name);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawgGame = widget.rawgGame;

    return Dialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
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
                          imageUrl: rawgGame['background_image'].toString(),
                          width: 60,
                          height: 80,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          placeholder: (_, __) => Container(
                            width: 60,
                            height: 80,
                            color: AppColors.surfaceSubtle(context),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 60,
                            height: 80,
                            color: AppColors.surfaceSubtle(context),
                            child: Icon(Icons.gamepad_rounded,
                                size: 24,
                                color: AppColors.textSecondary(context)),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 80,
                          color: AppColors.surfaceSubtle(context),
                          child: Icon(Icons.gamepad_rounded,
                              size: 24,
                              color: AppColors.textSecondary(context)),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rawgGame['name']?.toString() ?? 'Juego',
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary(context),
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
                          color: AppColors.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      if (rawgGame['playtime'] != null &&
                          (rawgGame['playtime'] as num) > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          'HLTB estimado: ${rawgGame['playtime']}h',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: AppColors.border(context)),
            const SizedBox(height: 8),

            // Scrollable form fields
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado & Horas Jugadas
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estado',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                dropdownColor: AppColors.surface(context),
                                menuMaxHeight: 220,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textPrimary(context),
                                ),
                                items: _availableStatuses
                                    .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s,
                                            style: GoogleFonts.inter(
                                                fontSize: 13))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedStatus = val);
                                  }
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceSubtle(context),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: AppColors.border(context)),
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
                              Text(
                                'Horas Jugadas',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _hoursController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textPrimary(context),
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.timer_outlined,
                                    size: 16,
                                    color: AppColors.textSecondary(context),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fecha de Inicio
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de Inicio',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _selectedStartDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.border(context)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 14, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedStartDate == null
                                      ? 'Sin fecha de inicio'
                                      : DateFormat('dd/MM/yyyy')
                                          .format(_selectedStartDate!),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: _selectedStartDate == null
                                        ? AppColors.textSecondary(context)
                                        : AppColors.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Plataforma
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sports_esports_rounded,
                                    size: 16, color: Color(0xFFDC2626)),
                                const SizedBox(width: 8),
                                Text(
                                  'Plataforma',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                if (_detectedPlatforms.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: const Color(0xFF10B981)
                                              .withOpacity(0.3),
                                          width: 0.5),
                                    ),
                                    child: Text(
                                      '${_detectedPlatforms.length} disponibles',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_detectedPlatforms.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showAllPlatforms = !_showAllPlatforms;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text(
                                  _showAllPlatforms
                                      ? 'Solo recomendadas'
                                      : '+ Otras plataformas',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          final availableList = _showAllPlatforms ||
                                  _detectedPlatforms.isEmpty
                              ? widget.availablePlatforms
                              : _detectedPlatforms;

                          final listToRender =
                              List<String>.from(availableList);
                          if (!listToRender.contains(_selectedPlatform)) {
                            listToRender.insert(0, _selectedPlatform);
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: listToRender.map((p) {
                              final isSelected = _selectedPlatform == p;
                              final isDark = Theme.of(context).brightness ==
                                  Brightness.dark;
                              return InkWell(
                                onTap: () {
                                  setState(() => _selectedPlatform = p);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFDC2626)
                                            .withOpacity(0.15)
                                        : (isDark
                                            ? const Color(0xFF18181B)
                                            : const Color(0xFFF4F4F5)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFDC2626)
                                          : (isDark
                                              ? const Color(0xFF27272A)
                                              : const Color(0xFFE4E4E7)),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PlatformHelper.getIcon(p,
                                          size: 15, isColor: isSelected),
                                      const SizedBox(width: 7),
                                      Text(
                                        p,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFFDC2626)
                                              : AppColors.textPrimary(context),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.check_circle_rounded,
                                            size: 13,
                                            color: Color(0xFFDC2626)),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Acordeón de Géneros
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isGenreAccordionExpanded
                              ? const Color(0xFFDC2626).withOpacity(0.4)
                              : AppColors.border(context),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isGenreAccordionExpanded =
                                    !_isGenreAccordionExpanded;
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
                                          size: 16, color: Color(0xFFDC2626)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Géneros',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              AppColors.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${_selectedGenres.length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    _isGenreAccordionExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isGenreAccordionExpanded) ...[
                            Divider(
                                height: 1, color: AppColors.border(context)),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: widget.allAvailableGenres.map((g) {
                                  final isSelected =
                                      _selectedGenres.contains(g);
                                  return FilterChip(
                                    label: Text(
                                      g,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textSecondary(context),
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFFDC2626),
                                    backgroundColor: AppColors.surface(context),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.transparent
                                          : AppColors.border(context),
                                    ),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6)),
                                    showCheckmark: false,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedGenres.add(g);
                                        } else {
                                          _selectedGenres.remove(g);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
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
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final result = _GameDetailsResult(
                      status: _selectedStatus,
                      platform: _selectedPlatform,
                      startDate: _selectedStartDate,
                      hoursPlayed:
                          double.tryParse(_hoursController.text.trim()) ?? 0,
                      genres: _selectedGenres,
                    );
                    Navigator.pop(context, result);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Añadir a mi Biblioteca',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

