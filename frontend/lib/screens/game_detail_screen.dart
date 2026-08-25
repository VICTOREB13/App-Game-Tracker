import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/game.dart';
import '../services/notion_service.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;
  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final _notion = NotionService.instance;
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

  void _addQuickHours(double delta) {
    final current = double.tryParse(_hoursController.text) ?? 0.0;
    final updated = current + delta;
    setState(() {
      _hoursController.text =
          updated % 1 == 0 ? updated.toInt().toString() : updated.toStringAsFixed(1);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+${delta % 1 == 0 ? delta.toInt() : delta}h añadidas al contador'),
        backgroundColor: const Color(0xFF00F0FF),
        duration: const Duration(seconds: 1),
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
            primary: Color(0xFF00F0FF),
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
      final updatedGame = Game(
        notionPageId: widget.game.notionPageId,
        title: _titleController.text,
        status: _selectedStatus,
        platform: _selectedPlatform,
        hoursPlayed: double.tryParse(_hoursController.text),
        genres: _selectedGenres,
        rating: _selectedRating,
        hltbMain: double.tryParse(_hltbMainController.text),
        hltbCompletionist: double.tryParse(_hltbCompController.text),
        coverUrl: _coverUrlController.text,
        summary: _summaryController.text.isNotEmpty
            ? _summaryController.text
            : null,
        link: _linkController.text.isNotEmpty ? _linkController.text : null,
        startDate: _startDate,
        completedDate: _completedDate,
      );

      await _notion.updatePage(
        widget.game.notionPageId,
        updatedGame.toNotionProperties(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cambios guardados en Notion',
                style: GoogleFonts.inter(color: const Color(0xFF0A0E1A))),
            backgroundColor: const Color(0xFF00F0FF),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFFF2D78),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGame() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF141927),
            title: Text('¿Eliminar juego?',
                style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFFF0F2F5))),
            content: Text(
              'Se moverá a la papelera de Notion.',
              style:
                  GoogleFonts.inter(color: const Color(0xFF6B7394)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF6B7394))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Eliminar',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFFF2D78))),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;
    try {
      await _notion.deletePage(widget.game.notionPageId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al borrar: $e'),
            backgroundColor: const Color(0xFFFF2D78),
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
      appBar: AppBar(
        title: Text('Ficha del Juego', style: GoogleFonts.spaceGrotesk()),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF2D78)),
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
                              CachedNetworkImage(
                                imageUrl: _coverUrlController.text,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF0A0E1A).withOpacity(0.6),
                                      const Color(0xFF0A0E1A),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Centered Main Cover Card
                    Container(
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
                        child: _coverUrlController.text.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _coverUrlController.text,
                                height: 220,
                                width: 160,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                    height: 220,
                                    width: 160,
                                    color: const Color(0xFF1C2237)),
                                errorWidget: (_, __, ___) => Container(
                                  height: 220,
                                  width: 160,
                                  color: const Color(0xFF1C2237),
                                  child: const Icon(Icons.sports_esports_rounded,
                                      size: 50, color: Color(0xFF3A4060)),
                                ),
                              )
                            : Container(
                                height: 220,
                                width: 160,
                                color: const Color(0xFF1C2237),
                                child: const Icon(Icons.sports_esports_rounded,
                                    size: 50, color: Color(0xFF3A4060)),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cover URL Input
                TextField(
                  controller: _coverUrlController,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF6B7394)),
                  decoration: const InputDecoration(
                    labelText: 'URL de Portada',
                    prefixIcon: Icon(Icons.image_outlined,
                        size: 18, color: Color(0xFF6B7394)),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(labelText: 'Título del Juego'),
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
                        decoration: const InputDecoration(
                          labelText: 'Horas Jugadas',
                          prefixIcon: Icon(Icons.timer_outlined,
                              color: Color(0xFF6B7394)),
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
                      color: const Color(0xFF141927),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF00F0FF).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso de Campaña',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00F0FF),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF00F0FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFF1C2237),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00F0FF)),
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
                                  color: const Color(0xFF6B7394)),
                            ),
                            if (hltbComp > 0)
                              Text(
                                '100% Completista: ${hltbComp.toInt()}h',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7394)),
                              ),
                            Text(
                              hours >= hltbMain
                                  ? 'Completado'
                                  : 'Faltan ~${(hltbMain - hours).clamp(0, 999).toStringAsFixed(0)}h',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hours >= hltbMain
                                    ? const Color(0xFFFF2D78)
                                    : const Color(0xFFFFBE0B),
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

                // Genres Section
                _buildSectionHeader('Géneros'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allGenres.map((g) {
                    final isSelected = _selectedGenres.contains(g);
                    return FilterChip(
                      label: Text(
                        g,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isSelected
                              ? const Color(0xFF0A0E1A)
                              : const Color(0xFF6B7394),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00F0FF),
                      backgroundColor: const Color(0xFF1C2237),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      showCheckmark: false,
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

                // Link
                TextField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link / Sitio web',
                    prefixIcon: Icon(Icons.link_rounded,
                        size: 18, color: Color(0xFF6B7394)),
                  ),
                ),
                const SizedBox(height: 24),

                // HLTB Settings Section
                _buildSectionHeader('Metadatos HowLongToBeat'),
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
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0A0E1A),
                            ),
                          )
                        : Text('Guardar Todo en Notion',
                            style: GoogleFonts.spaceGrotesk(
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
    return ElevatedButton(
      onPressed: () => _addQuickHours(hoursToAdd),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        backgroundColor: const Color(0xFF1C2237),
        foregroundColor: const Color(0xFF00F0FF),
        elevation: 0,
        side: const BorderSide(color: Color(0xFF00F0FF), width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF00F0FF),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      dropdownColor: const Color(0xFF1C2237),
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF0F2F5)),
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s, style: GoogleFonts.inter(fontSize: 13)),
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
          color: const Color(0xFF141927),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1C2237)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: const Color(0xFF6B7394))),
                if (date != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: Color(0xFF6B7394)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Color(0xFF00F0FF)),
                const SizedBox(width: 6),
                Text(
                  date == null
                      ? 'Seleccionar'
                      : DateFormat('dd/MM/yyyy').format(date),
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFFF0F2F5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
}
