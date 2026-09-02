import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/game.dart';
import '../services/database_service.dart';
import '../services/theme_manager.dart';
import '../services/hltb_service.dart';
import '../services/metadata_service.dart';
import '../widgets/platform_helper.dart';
import '../widgets/app_cover_image.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;
  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final GlobalKey _socialCardKey = GlobalKey();
  bool _isExporting = false;
  bool _isFetchingHltb = false;
  bool _isSearchingWiki = false;
  late TextEditingController _titleController;
  late TextEditingController _hoursController;
  late TextEditingController _hltbMainController;
  late TextEditingController _hltbCompController;
  late TextEditingController _coverUrlController;
  late TextEditingController _summaryController;
  late TextEditingController _linkController;

  late String _selectedStatus;
  late String _selectedPlatform;
  late String _selectedRating;
  late List<String> _selectedGenres;
  DateTime? _startDate;
  DateTime? _completedDate;
  bool _isSaving = false;
  bool _isGenreAccordionExpanded = false;

  final List<String> _statuses = ['Por jugar', 'Jugando', 'Jugado'];

  final List<String> _platforms = [
    'PC', 'Mac', 'Mobile',
    'Playstation 5', 'Playstation 4', 'Playstation 3',
    'Playstation 2', 'Playstation 1',
    'Xbox', 'Nintendo Switch', 'Wii U',
    'Nintendo 64', 'Nintendo DS',
    'GOG', 'Epic Games',
  ];

  final List<String> _ratings = [
    '★★★★★', '★★★★✰', '★★★✰✰', '★★✰✰✰', '★✰✰✰✰', '✰✰✰✰✰',
  ];

  final List<String> _allGenres = [
    'Acción', 'Aventura', 'Acción-aventura', 'RPG', 'Rol', 'Rol de acción',
    'Disparos', 'Shooter', 'Estrategia', 'Simulador', 'Simulación',
    'Plataformas', 'Lucha', 'Puzle', 'Arcade', 'Casual', 'Indie',
    'MMORPG', 'Massively Multiplayer', 'Hack and Slash', 'Souls', 'Soulslike',
    'Metroidvania', 'Roguelike', 'Terror y supervivencia', 'Carreras',
    'Anime', 'Gacha', 'Sigilo', 'Zombies',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game.title);
    _hoursController = TextEditingController(
        text: widget.game.hoursPlayed != null
            ? (widget.game.hoursPlayed! % 1 == 0
                ? widget.game.hoursPlayed!.toInt().toString()
                : widget.game.hoursPlayed!.toString())
            : '0');
    _hltbMainController = TextEditingController(
        text: widget.game.hltbMain != null
            ? (widget.game.hltbMain! % 1 == 0
                ? widget.game.hltbMain!.toInt().toString()
                : widget.game.hltbMain!.toString())
            : '0');
    _hltbCompController = TextEditingController(
        text: widget.game.hltbCompletionist != null
            ? (widget.game.hltbCompletionist! % 1 == 0
                ? widget.game.hltbCompletionist!.toInt().toString()
                : widget.game.hltbCompletionist!.toString())
            : '0');
    _coverUrlController =
        TextEditingController(text: widget.game.coverUrl ?? '');
    _summaryController =
        TextEditingController(text: widget.game.summary ?? '');
    _linkController = TextEditingController(text: widget.game.link ?? '');

    _selectedStatus = _statuses.contains(widget.game.status)
        ? widget.game.status
        : _statuses[0];
    _selectedPlatform = _platforms.contains(widget.game.platform)
        ? widget.game.platform!
        : _platforms[0];
    _selectedRating = widget.game.rating ?? _ratings.last;
    if (!_ratings.contains(_selectedRating)) {
      _selectedRating = _ratings.last;
    }

    _selectedGenres = List.from(widget.game.genres);
    for (var g in _selectedGenres) {
      if (!_allGenres.contains(g)) {
        _allGenres.add(g);
      }
    }

    _startDate = widget.game.startDate;
    _completedDate = widget.game.completedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hoursController.dispose();
    _hltbMainController.dispose();
    _hltbCompController.dispose();
    _coverUrlController.dispose();
    _summaryController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _fetchHltbData() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isFetchingHltb = true);
    try {
      final result = await HltbService.instance.searchHltb(title);
      if (!mounted) return;

      if (result != null && (result.mainStory != null || result.completionist != null)) {
        setState(() {
          if (result.mainStory != null) {
            _hltbMainController.text = result.mainStory!.toString();
          }
          if (result.completionist != null) {
            _hltbCompController.text = result.completionist!.toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ HowLongToBeat: Campaña ${result.mainStory ?? 0}h • 100% ${result.completionist ?? 0}h',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se encontraron estimaciones en HowLongToBeat para "$title"',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error consultando HowLongToBeat: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingHltb = false);
      }
    }
  }

  Future<void> _fetchWikipediaLink() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSearchingWiki = true);
    try {
      final url = await MetadataService.instance.searchWikipedia(title);
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        setState(() {
          _linkController.text = url;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Enlace de Wikipedia asignado: $url',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontró página de Wikipedia para "$title"',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error consultando Wikipedia: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingWiki = false);
    }
  }

  Future<void> _pickLocalImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
      );

      if (result != null && result.files.single.path != null) {
        final pickedFilePath = result.files.single.path!;
        final pickedFile = File(pickedFilePath);

        // Directorio interno persistente de portadas
        final appDir = await getApplicationDocumentsDirectory();
        final coversDir = Directory(p.join(appDir.path, 'covers'));
        if (!await coversDir.exists()) {
          await coversDir.create(recursive: true);
        }

        final ext = p.extension(pickedFilePath).toLowerCase();
        final destName = 'cover_${widget.game.id}_${DateTime.now().millisecondsSinceEpoch}$ext';
        final destPath = p.join(coversDir.path, destName);

        await pickedFile.copy(destPath);

        setState(() {
          _coverUrlController.text = destPath;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Imagen de portada seleccionada'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _addQuickHours(double delta) {
    final current = double.tryParse(_hoursController.text) ?? 0.0;
    final updated = (current + delta).clamp(0.0, 99999.0);
    setState(() {
      _hoursController.text =
          updated % 1 == 0 ? updated.toInt().toString() : updated.toStringAsFixed(1);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+${delta % 1 == 0 ? delta.toInt() : delta}h añadidas al contador'),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? _startDate : _completedDate) ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFDC2626),
            surface: Color(0xFF141927),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _completedDate = picked;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final newCover = _coverUrlController.text.trim();
      final hours = double.tryParse(_hoursController.text) ?? 0.0;
      final hltbMain = double.tryParse(_hltbMainController.text);
      final hltbComp = double.tryParse(_hltbCompController.text);

      String finalStatus = _selectedStatus;
      DateTime? finalCompleted = _completedDate;

      // Auto-culminación si horas superan HLTB
      if (hltbMain != null &&
          hltbMain > 0 &&
          hours >= hltbMain &&
          _selectedStatus != 'Jugado') {
        finalStatus = 'Jugado';
        finalCompleted ??= DateTime.now();
      }

      final updatedGame = widget.game.copyWith(
        title: _titleController.text.trim(),
        status: finalStatus,
        platform: _selectedPlatform,
        hoursPlayed: hours,
        genres: _selectedGenres,
        rating: _selectedRating == 'Sin calificar' ? null : _selectedRating,
        hltbMain: hltbMain,
        hltbCompletionist: hltbComp,
        coverUrl: newCover.isNotEmpty ? newCover : null,
        summary: _summaryController.text.trim().isNotEmpty
            ? _summaryController.text.trim()
            : null,
        link: _linkController.text.trim().isNotEmpty
            ? _linkController.text.trim()
            : null,
        startDate: _startDate,
        completedDate: finalCompleted,
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateGame(updatedGame);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cambios guardados en la biblioteca local',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGame() async {
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.border(context)),
            ),
            title: Text('¿Eliminar juego?',
                style: GoogleFonts.outfit(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.bold)),
            content: Text(
              'Este videojuego será eliminado de tu base de datos local.',
              style: GoogleFonts.inter(color: AppColors.textSecondary(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary(context))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;
    try {
      await DatabaseService.instance.deleteGame(widget.game.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al borrar: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = double.tryParse(_hoursController.text) ?? 0.0;
    final hltbMain = double.tryParse(_hltbMainController.text) ?? 0.0;
    final hltbComp = double.tryParse(_hltbCompController.text) ?? 0.0;
    final progress = hltbMain > 0 ? (hours / hltbMain).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text('Ficha del Juego',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(context),
            )),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded,
                color: AppColors.textPrimary(context)),
            tooltip: 'Exportar Ficha Social',
            onPressed: _showSocialCardDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFDC2626)),
            tooltip: 'Eliminar juego',
            onPressed: _deleteGame,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cinematic Header with Cover Backdrop & Image
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Backdrop blur container
                    if (_coverUrlController.text.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppCoverImage(
                                coverUrl: _coverUrlController.text,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.background(context)
                                          .withOpacity(0.5),
                                      AppColors.background(context),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Centered Main Cover Card with Hero animation
                    Hero(
                      tag: 'game-cover-${widget.game.id}',
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AppCoverImage(
                            coverUrl: _coverUrlController.text,
                            height: 220,
                            width: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      PlatformHelper.buildBadge(_selectedPlatform,
                          fontSize: 11, iconSize: 14),
                      _buildStatusPill(_selectedStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Cover URL Input
                TextField(
                  controller: _coverUrlController,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary(context)),
                  decoration: InputDecoration(
                    labelText: 'URL de Portada',
                    prefixIcon: Icon(Icons.image_outlined,
                        size: 18, color: AppColors.textSecondary(context)),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration:
                      const InputDecoration(labelText: 'Título del Juego'),
                ),
                const SizedBox(height: 20),

                // Status & Platform row
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        'Estado',
                        _selectedStatus,
                        _statuses,
                        (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatus = val;
                              // Auto-fill completion date when marking as played
                              if (val == 'Jugado' && _completedDate == null) {
                                _completedDate = DateTime.now();
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        'Plataforma',
                        _selectedPlatform,
                        _platforms,
                        (val) => setState(() => _selectedPlatform = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rating
                _buildDropdown(
                  'Calificación',
                  _selectedRating,
                  _ratings,
                  (val) => setState(() => _selectedRating = val!),
                ),
                const SizedBox(height: 24),

                // Hours Played & Quick Action Buttons
                _buildSectionHeader('Tiempo de Juego'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _hoursController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (val) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Horas Jugadas',
                          prefixIcon: Icon(Icons.timer_outlined,
                              color: AppColors.textSecondary(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Quick +buttons
                    _buildQuickHourButton('+30m', 0.5),
                    const SizedBox(width: 6),
                    _buildQuickHourButton('+1h', 1.0),
                    const SizedBox(width: 6),
                    _buildQuickHourButton('+2h', 2.0),
                  ],
                ),
                const SizedBox(height: 24),

                // HLTB Progress Card if available
                if (hltbMain > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFDC2626).withOpacity(0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso de Campaña',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
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
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: progress),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              final isDark =
                                  Theme.of(context).brightness == Brightness.dark;
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                backgroundColor: isDark
                                    ? const Color(0xFF27272A)
                                    : const Color(0xFFE4E4E7),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFDC2626)),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Historia: ${hltbMain.toInt()}h',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textSecondary(context)),
                            ),
                            if (hltbComp > 0)
                              Text(
                                '100% Completista: ${hltbComp.toInt()}h',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary(context)),
                              ),
                            Text(
                              hours >= hltbMain
                                  ? 'Completado'
                                  : 'Faltan ~${(hltbMain - hours).clamp(0, 999).toStringAsFixed(0)}h',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hours >= hltbMain
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Dates Section
                _buildSectionHeader('Fechas de Registro'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        'Fecha de Inicio',
                        _startDate,
                        () => _selectDate(context, true),
                        onClear: () => setState(() => _startDate = null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePicker(
                        'Culminación (1ra Campaña)',
                        _completedDate,
                        () => _selectDate(context, false),
                        onClear: () => setState(() => _completedDate = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Genres Collapsible Section
                _buildSectionHeader('Géneros'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isGenreAccordionExpanded
                          ? const Color(0xFFDC2626).withOpacity(0.5)
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
                              horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.category_rounded,
                                      size: 18, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Seleccionar Géneros',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${_selectedGenres.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _isGenreAccordionExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary(context),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isGenreAccordionExpanded) ...[
                        Divider(height: 1, color: AppColors.border(context)),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _allGenres.map((g) {
                              final isSelected = _selectedGenres.contains(g);
                              return FilterChip(
                                label: Text(
                                  g,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary(context),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFFDC2626),
                                backgroundColor:
                                    AppColors.surfaceSubtle(context),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppColors.border(context),
                                ),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 0),
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
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
                      ] else if (_selectedGenres.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedGenres.join(' • '),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
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
                const SizedBox(height: 24),

                // Summary
                TextField(
                  controller: _summaryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Resumen / Notas personales',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                // Cover Image Customizer
                _buildSectionHeader('Portada del Videojuego'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppCoverImage(
                            coverUrl: _coverUrlController.text,
                            width: 50,
                            height: 68,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personalizar carátula',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ingresa una URL web o sube un archivo directamente desde tu galería.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _pickLocalImage,
                                  icon: const Icon(Icons.photo_library_rounded,
                                      size: 16, color: Color(0xFFDC2626)),
                                  label: Text(
                                    'Elegir de mi Galería / Disco',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary(context),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    side: BorderSide(
                                        color: AppColors.border(context)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _coverUrlController,
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary(context),
                        ),
                        decoration: InputDecoration(
                          labelText: 'URL web de portada (o ruta local)',
                          hintText: 'https://ejemplo.com/portada.jpg',
                          prefixIcon: const Icon(Icons.image_outlined,
                              size: 18, color: Color(0xFFDC2626)),
                          suffixIcon: _coverUrlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    _coverUrlController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Link / Wikipedia
                TextField(
                  controller: _linkController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Enlace Enciclopédico (Wikipedia)',
                    hintText: 'https://es.wikipedia.org/wiki/...',
                    prefixIcon: const Icon(Icons.public_rounded,
                        size: 18, color: Color(0xFFDC2626)),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_linkController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Borrar enlace',
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _linkController.clear();
                              setState(() {});
                            },
                          ),
                        _isSearchingWiki
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: 'Buscar enlace en Wikipedia',
                                icon: const Icon(Icons.travel_explore_rounded,
                                    color: Color(0xFFDC2626), size: 20),
                                onPressed: _fetchWikipediaLink,
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // HLTB Settings Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Metadatos HowLongToBeat'),
                    TextButton.icon(
                      onPressed: _isFetchingHltb ? null : _fetchHltbData,
                      icon: _isFetchingHltb
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFDC2626),
                              ),
                            )
                          : const Icon(Icons.timer_outlined,
                              size: 16, color: Color(0xFFDC2626)),
                      label: Text(
                        _isFetchingHltb ? 'Buscando...' : 'Buscar en HLTB',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hltbMainController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration:
                            const InputDecoration(labelText: 'Historia (hrs)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _hltbCompController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration:
                            const InputDecoration(labelText: '100% (hrs)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFFDC2626).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Guardar Cambios',
                            style: GoogleFonts.outfit(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickHourButton(String label, double hoursToAdd) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ElevatedButton(
      onPressed: () => _addQuickHours(hoursToAdd),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        backgroundColor: isDark
            ? const Color(0xFF121215)
            : const Color(0xFFFEF2F2),
        foregroundColor: const Color(0xFFDC2626),
        elevation: 0,
        side: BorderSide(
          color: isDark
              ? const Color(0xFFDC2626)
              : const Color(0xFFDC2626).withOpacity(0.4),
          width: 0.8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFDC2626),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status) {
      case 'Jugando':
        color = const Color(0xFFDC2626);
        break;
      case 'Por jugar':
        color = const Color(0xFFF59E0B);
        break;
      case 'Jugado':
        color = const Color(0xFF10B981);
        break;
      default:
        color = const Color(0xFFA1A1AA);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final isPlatform = label.toLowerCase().contains('plataforma');

    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      dropdownColor: AppColors.surface(context),
      borderRadius: BorderRadius.circular(12),
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textPrimary(context),
      ),
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPlatform) ...[
                      PlatformHelper.getIcon(s, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildDatePicker(
      String label, DateTime? date, VoidCallback onTap,
      {VoidCallback? onClear}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary(context))),
                if (date != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded,
                        size: 12, color: AppColors.textSecondary(context)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Text(
                  date == null
                      ? 'Seleccionar'
                      : DateFormat('dd/MM/yyyy').format(date),
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSocialCardDialog() {
    final isCurrentDark = Theme.of(context).brightness == Brightness.dark;
    bool cardIsDark = isCurrentDark;

    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.border(context), width: 1),
            ),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with title and theme selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFFDC2626).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.share_rounded,
                                size: 16, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tarjeta Social de Reseña',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Theme Switcher for card (Claro / Oscuro)
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.border(context)),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => setDialogState(
                                      () => cardIsDark = false),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: !cardIsDark
                                          ? const Color(0xFFDC2626)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.light_mode_rounded,
                                          size: 12,
                                          color: !cardIsDark
                                              ? Colors.white
                                              : AppColors.textSecondary(
                                                  context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Claro',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: !cardIsDark
                                                ? Colors.white
                                                : AppColors.textSecondary(
                                                    context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => setDialogState(
                                      () => cardIsDark = true),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cardIsDark
                                          ? const Color(0xFFDC2626)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.dark_mode_rounded,
                                          size: 12,
                                          color: cardIsDark
                                              ? Colors.white
                                              : AppColors.textSecondary(
                                                  context),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Oscuro',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: cardIsDark
                                                ? Colors.white
                                                : AppColors.textSecondary(
                                                    context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                size: 18,
                                color: AppColors.textSecondary(context)),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // RepaintBoundary Card
                  RepaintBoundary(
                    key: _socialCardKey,
                    child: _buildSocialCardPreview(isDark: cardIsDark),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cerrar',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary(context)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _isExporting
                            ? null
                            : () async {
                                setDialogState(() => _isExporting = true);
                                await _exportSocialCard(isDark: cardIsDark);
                                if (ctx.mounted) {
                                  setDialogState(() => _isExporting = false);
                                  Navigator.pop(ctx);
                                }
                              },
                        icon: _isExporting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 16),
                        label: Text(
                          _isExporting
                              ? 'Exportando...'
                              : 'Guardar PNG (Descargas)',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ));
  }

  Widget _buildSocialCardPreview({required bool isDark}) {
    final title = _titleController.text.trim().isEmpty
        ? widget.game.title
        : _titleController.text.trim();
    final hours = double.tryParse(_hoursController.text) ??
        (widget.game.hoursPlayed ?? 0.0);
    final rating = _selectedRating;
    final summary = _summaryController.text.trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D10) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFDC2626).withOpacity(0.12)
                : Colors.black.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Brand & Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Monogram & Title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'VE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Victor ',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFAFAFA)
                                : const Color(0xFF09090B),
                          ),
                        ),
                        TextSpan(
                          text: 'Engineer',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        TextSpan(
                          text: ' • Game Tracker',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFFA1A1AA)
                                : const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Rating stars
              if (rating.isNotEmpty && rating != '✰✰✰✰✰')
                Text(
                  rating,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Body: Cover thumbnail + details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppCoverImage(
                  coverUrl: _coverUrlController.text,
                  width: 76,
                  height: 104,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFFAFAFA)
                            : const Color(0xFF09090B),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (_selectedPlatform.isNotEmpty) ...[
                          PlatformHelper.getIcon(_selectedPlatform,
                              size: 14,
                              isColor: true),
                          const SizedBox(width: 5),
                          Text(
                            _selectedPlatform,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF71717A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_selectedStatus == 'Jugado'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFDC2626))
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: (_selectedStatus == 'Jugado'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFDC2626))
                                  .withOpacity(0.4),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _selectedStatus,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _selectedStatus == 'Jugado'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Playtime & completion
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 13, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          '${hours % 1 == 0 ? hours.toInt() : hours}h jugadas',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFAFAFA)
                                : const Color(0xFF09090B),
                          ),
                        ),
                        if (_completedDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•  ${DateFormat('dd MMM yyyy').format(_completedDate!)}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Review / Notes Quote if available
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF18181B)
                    : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFE4E4E7),
                ),
              ),
              child: Text(
                '“$summary”',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? const Color(0xFFA1A1AA)
                      : const Color(0xFF3F3F46),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportSocialCard({bool isDark = true}) async {
    try {
      final boundary = _socialCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      String savePath = '';
      final modeSuffix = isDark ? 'Dark' : 'Light';
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? '';
        final downloadsDir = Directory('$userProfile\\Downloads');
        final title = _titleController.text.trim().isEmpty
            ? widget.game.title
            : _titleController.text.trim();
        final cleanTitle = title
            .replaceAll(RegExp(r'[^\w\s-]'), '')
            .replaceAll(' ', '_');
        final filePath =
            '${downloadsDir.path}\\Resena_VE_${cleanTitle}_${modeSuffix}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);
        savePath = filePath;
      } else {
        final file =
            File('Resena_VE_${modeSuffix}_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);
        savePath = file.path;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tarjeta ($modeSuffix) exportada en Descargas: $savePath',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar tarjeta: $e',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }
}
