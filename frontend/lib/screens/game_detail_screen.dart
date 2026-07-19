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
        text: widget.game.hoursPlayed?.toString() ?? '0');
    _hltbMainController = TextEditingController(
        text: widget.game.hltbMain?.toString() ?? '0');
    _hltbCompController = TextEditingController(
        text: widget.game.hltbCompletionist?.toString() ?? '0');
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
    // Add any genres from the game that aren't in our list
    for (var g in _selectedGenres) {
      if (!_allGenres.contains(g)) {
        _allGenres.add(g);
      }
    }

    _startDate = widget.game.startDate;
    _completedDate = widget.game.completedDate;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? _startDate : _completedDate) ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
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
            content: Text('Cambios guardados',
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
            content: Text('Error: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles', style: GoogleFonts.spaceGrotesk()),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.delete_outline, color: Color(0xFFFF2D78)),
            onPressed: _deleteGame,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _coverUrlController.text.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _coverUrlController.text,
                        height: 280,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Container(
                            height: 280,
                            width: 190,
                            color: const Color(0xFF1C2237)),
                        errorWidget: (_, __, ___) => Container(
                          height: 280,
                          width: 190,
                          color: const Color(0xFF1C2237),
                          child: const Icon(Icons.gamepad_rounded,
                              size: 50, color: Color(0xFF3A4060)),
                        ),
                      )
                    : Container(
                        height: 280,
                        width: 190,
                        color: const Color(0xFF1C2237),
                        child: const Icon(Icons.gamepad_rounded,
                            size: 50, color: Color(0xFF3A4060)),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Cover URL
            TextField(
              controller: _coverUrlController,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7394)),
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
              decoration: const InputDecoration(labelText: 'Título'),
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
                    (val) => setState(() => _selectedStatus = val!),
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
            const SizedBox(height: 20),

            // Hours played
            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Horas Jugadas',
                prefixIcon:
                    Icon(Icons.timer_outlined, color: Color(0xFF6B7394)),
              ),
            ),
            const SizedBox(height: 24),

            // Dates
            _buildSectionHeader('Fechas'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    'Fecha de Inicio',
                    _startDate,
                    () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePicker(
                    'Primera vez completado',
                    _completedDate,
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Genres
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
                labelText: 'Resumen / Notas',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // Link
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Link',
                prefixIcon: Icon(Icons.link_rounded,
                    size: 18, color: Color(0xFF6B7394)),
              ),
            ),
            const SizedBox(height: 24),

            // HLTB Section
            _buildSectionHeader('HowLongToBeat'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hltbMainController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Historia (hrs)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hltbCompController,
                    keyboardType: TextInputType.number,
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
                    : Text('Guardar Todo',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
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
      String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141927),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1C2237)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: const Color(0xFF6B7394))),
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
