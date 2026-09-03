import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/game_detail_controller.dart';
import '../../models/game.dart';
import '../../services/theme_manager.dart';
import '../widgets/game_detail/game_cover_picker_card.dart';
import '../widgets/game_detail/game_detail_form_fields.dart';
import '../widgets/game_detail/game_detail_header.dart';
import '../widgets/game_detail/game_genre_selector.dart';
import '../widgets/game_detail/game_hltb_progress_card.dart';
import '../widgets/game_detail/social_card_dialog.dart';
import '../widgets/platform_helper.dart';
import '../widgets/status_helper.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;
  final GameDetailController? controller;

  const GameDetailScreen({
    super.key,
    required this.game,
    this.controller,
  });

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late final GameDetailController _controller;
  late final TextEditingController _titleController;
  late final TextEditingController _hoursController;
  late final TextEditingController _hltbMainController;
  late final TextEditingController _hltbCompController;
  late final TextEditingController _coverUrlController;
  late final TextEditingController _summaryController;
  late final TextEditingController _linkController;

  static const _ratings = [
    '★★★★★',
    '★★★★✰',
    '★★★✰✰',
    '★★✰✰✰',
    '★✰✰✰✰',
    '✰✰✰✰✰',
    'Sin calificar',
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GameDetailController(game: widget.game);
    _controller.addListener(_onControllerChanged);

    _titleController = TextEditingController(text: _controller.title);
    _hoursController = TextEditingController(text: _controller.hoursPlayedFormatted);
    _hltbMainController = TextEditingController(text: _controller.hltbMainFormatted);
    _hltbCompController = TextEditingController(text: _controller.hltbCompFormatted);
    _coverUrlController = TextEditingController(text: _controller.coverUrl);
    _summaryController = TextEditingController(text: _controller.summary);
    _linkController = TextEditingController(text: _controller.link);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_hltbMainController.text != _controller.hltbMainFormatted) {
      _hltbMainController.text = _controller.hltbMainFormatted;
    }
    if (_hltbCompController.text != _controller.hltbCompFormatted) {
      _hltbCompController.text = _controller.hltbCompFormatted;
    }
    if (_linkController.text != _controller.link) {
      _linkController.text = _controller.link;
    }
    if (_hoursController.text != _controller.hoursPlayedFormatted) {
      _hoursController.text = _controller.hoursPlayedFormatted;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _titleController.dispose();
    _hoursController.dispose();
    _hltbMainController.dispose();
    _hltbCompController.dispose();
    _coverUrlController.dispose();
    _summaryController.dispose();
    _linkController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _addQuickHours(double delta) {
    final current = double.tryParse(_hoursController.text) ?? 0.0;
    _controller.setHours(current);
    _controller.addHours(delta);
    _hoursController.text = _controller.hoursPlayedFormatted;
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _controller.startDate : _controller.completedDate) ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
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
      if (isStart) {
        _controller.setStartDate(picked);
      } else {
        _controller.setCompletedDate(picked);
      }
    }
  }

  Future<void> _fetchHltbData() async {
    _controller.setTitle(_titleController.text.trim());
    await _controller.fetchHltbData();
  }

  Future<void> _fetchWikipediaLink() async {
    _controller.setTitle(_titleController.text.trim());
    await _controller.fetchWikipediaLink();
  }

  Future<void> _saveChanges() async {
    _controller.setTitle(_titleController.text.trim());
    _controller.setSummary(_summaryController.text.trim());
    _controller.setCoverUrl(_coverUrlController.text.trim());
    _controller.setLink(_linkController.text.trim());
    _controller.setHours(double.tryParse(_hoursController.text) ?? 0.0);
    _controller.setHltbMain(double.tryParse(_hltbMainController.text));
    _controller.setHltbCompletionist(double.tryParse(_hltbCompController.text));

    try {
      await _controller.saveGame();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ));
      }
    }
  }

  Future<void> _deleteGame() async {
    if (await showDeleteGameDialog(context)) {
      try {
        await _controller.deleteGame();
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = double.tryParse(_hoursController.text) ?? _controller.hoursPlayed.toDouble();
    final hltbMain = double.tryParse(_hltbMainController.text) ?? (_controller.hltbMain?.toDouble() ?? 0.0);
    final hltbComp = double.tryParse(_hltbCompController.text) ?? (_controller.hltbCompletionist?.toDouble() ?? 0.0);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Ficha del Juego',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: AppColors.textPrimary(context)),
            tooltip: 'Exportar Ficha Social',
            onPressed: () => SocialCardDialog.show(
              context: context,
              game: _controller.game,
              title: _titleController.text.trim().isNotEmpty
                  ? _titleController.text.trim()
                  : _controller.title,
              hoursPlayed: hours,
              rating: _controller.rating ?? 'Sin calificar',
              summary: _summaryController.text.trim(),
              platform: _controller.platform,
              status: _controller.status,
              completedDate: _controller.completedDate,
              coverUrl: _coverUrlController.text.trim(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Eliminar juego',
            onPressed: _controller.isDeleting ? null : _deleteGame,
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
                GameDetailHeader(
                  gameId: _controller.game.id,
                  coverUrl: _coverUrlController.text,
                  platform: _controller.platform,
                  status: _controller.status,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                  decoration: const InputDecoration(labelText: 'Título del Juego'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GameDropdownField(
                        label: 'Estado',
                        value: _controller.status,
                        items: StatusHelper.gameStatuses,
                        onChanged: (val) {
                          if (val != null) _controller.setStatus(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GameDropdownField(
                        label: 'Plataforma',
                        value: _controller.platform,
                        items: PlatformHelper.getOrderedPlatforms(
                          currentPlatform: _controller.platform,
                        ),
                        onChanged: (val) {
                          if (val != null) _controller.setPlatform(val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GameDropdownField(
                  label: 'Calificación',
                  value: _controller.rating ?? 'Sin calificar',
                  items: _ratings,
                  onChanged: (val) {
                    if (val != null) _controller.setRating(val);
                  },
                ),
                const SizedBox(height: 24),
                GameHoursEditor(
                  controller: _hoursController,
                  onAddHours: _addQuickHours,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                GameHltbProgressCard(
                  hoursPlayed: hours,
                  hltbMain: hltbMain,
                  hltbCompletionist: hltbComp,
                ),
                if (hltbMain > 0) const SizedBox(height: 24),
                GameDatesEditor(
                  startDate: _controller.startDate,
                  completedDate: _controller.completedDate,
                  onSelectStartDate: () => _selectDate(true),
                  onSelectCompletedDate: () => _selectDate(false),
                  onClearStartDate: () => _controller.setStartDate(null),
                  onClearCompletedDate: () => _controller.setCompletedDate(null),
                ),
                const SizedBox(height: 24),
                const GameSectionHeader('Géneros'),
                const SizedBox(height: 8),
                GameGenreSelector(
                  selectedGenres: _controller.genres,
                  onGenresChanged: (u) => _controller.setGenres(u),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _summaryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Resumen / Notas personales',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                const GameSectionHeader('Portada del Videojuego'),
                const SizedBox(height: 12),
                GameCoverPickerCard(
                  coverUrlController: _coverUrlController,
                  gameId: _controller.game.id,
                  onCoverChanged: () {
                    _controller.setCoverUrl(_coverUrlController.text);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                GameWikipediaField(
                  controller: _linkController,
                  isSearching: _controller.isSearchingWiki,
                  onSearch: _fetchWikipediaLink,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                GameHltbInputs(
                  mainController: _hltbMainController,
                  compController: _hltbCompController,
                  isFetching: _controller.isFetchingHltb,
                  onFetch: _fetchHltbData,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 36),
                GameSaveButton(
                  isSaving: _controller.isSaving,
                  onSave: _saveChanges,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
