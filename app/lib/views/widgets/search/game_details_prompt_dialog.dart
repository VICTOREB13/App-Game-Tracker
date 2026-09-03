import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../services/theme_manager.dart';
import '../genre_helper.dart';
import '../platform_helper.dart';
import '../status_helper.dart';
import '../../../models/game_details_result.dart';
import 'prompt_dialog_header.dart';
import 'prompt_genre_selector.dart';
import 'prompt_platform_selector.dart';

/// Diálogo modal interactivo para personalizar estado, plataforma, horas y géneros
/// antes de añadir un videojuego de RAWG a la biblioteca.
class GameDetailsPromptDialog extends StatefulWidget {
  final Map<String, dynamic> rawgGame;
  const GameDetailsPromptDialog({super.key, required this.rawgGame});

  static Future<GameDetailsResult?> show({required BuildContext context, required Map<String, dynamic> rawgGame}) =>
      showDialog<GameDetailsResult>(context: context, builder: (ctx) => GameDetailsPromptDialog(rawgGame: rawgGame));

  @override
  State<GameDetailsPromptDialog> createState() => _GameDetailsPromptDialogState();
}

class _GameDetailsPromptDialogState extends State<GameDetailsPromptDialog> {
  late final TextEditingController _hoursController;
  String _selectedStatus = StatusHelper.porJugar;
  DateTime? _selectedStartDate;
  late String _selectedPlatform;
  final List<String> _detectedPlatforms = [];
  final List<String> _selectedGenres = [];
  final List<String> _availableGenres = List<String>.from(GenreHelper.allGenres);

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(text: '0');
    _detectedPlatforms.addAll({
      for (final item in (widget.rawgGame['platforms'] as List? ?? []))
        if (((item as Map?)?['platform'] as Map?)?['name']?.toString().trim() case final String n when n.isNotEmpty)
          PlatformHelper.canonicalize(n),
    });
    _selectedPlatform = _detectedPlatforms.contains('PC') ? 'PC' : (_detectedPlatforms.firstOrNull ?? 'PC');
    final gSet = {
      for (final g in (widget.rawgGame['genres'] as List? ?? []))
        if ((g as Map?)?['name']?.toString().trim() case final String n when n.isNotEmpty) n,
    };
    _selectedGenres.addAll(gSet);
    for (final g in gSet) {
      if (!_availableGenres.contains(g)) {
        _availableGenres.add(g);
      }
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, GameDetailsResult(
        status: _selectedStatus, platform: _selectedPlatform, startDate: _selectedStartDate,
        hoursPlayed: double.tryParse(_hoursController.text.trim()) ?? 0, genres: _selectedGenres,
      ));

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border(context))),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            PromptDialogHeader.fromRawg(rawgGame: widget.rawgGame),
            const SizedBox(height: 16),
            Divider(color: AppColors.border(context)),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildStatusAndHours(),
                  const SizedBox(height: 12),
                  _buildStartDatePicker(),
                  const SizedBox(height: 14),
                  PromptPlatformSelector(
                    selectedPlatform: _selectedPlatform, detectedPlatforms: _detectedPlatforms,
                    onPlatformChanged: (p) => setState(() => _selectedPlatform = p),
                  ),
                  const SizedBox(height: 16),
                  PromptGenreSelector(
                    selectedGenres: _selectedGenres, availableGenres: _availableGenres,
                    onGenreToggled: (g, s) => setState(() => s ? _selectedGenres.add(g) : _selectedGenres.remove(g)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            _buildActions(),
          ]),
        ),
      );

  Widget _buildStatusAndHours() => Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Estado', style: GoogleFonts.inter(color: AppColors.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _selectedStatus, dropdownColor: AppColors.surface(context), menuMaxHeight: 220,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary(context)),
              items: StatusHelper.gameStatuses.map((s) => DropdownMenuItem(value: s, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(StatusHelper.getIcon(s), size: 14, color: StatusHelper.getColor(s)), const SizedBox(width: 8), Text(s, style: GoogleFonts.inter(fontSize: 13))]))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatus = val);
                }
              },
              decoration: InputDecoration(
                filled: true, fillColor: AppColors.surfaceSubtle(context), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border(context))),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Horas Jugadas', style: GoogleFonts.inter(color: AppColors.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            TextField(
              controller: _hoursController, keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary(context)),
              decoration: InputDecoration(prefixIcon: Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary(context)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            ),
          ]),
        ),
      ]);

  Widget _buildStartDatePicker() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Fecha de Inicio', style: GoogleFonts.inter(color: AppColors.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
            if (!mounted) {
              return;
            }
            if (p != null) {
              setState(() => _selectedStartDate = p);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border(context))),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFDC2626)), const SizedBox(width: 8),
              Text(_selectedStartDate == null ? 'Sin fecha de inicio' : DateFormat('dd/MM/yyyy').format(_selectedStartDate!),
                  style: GoogleFonts.inter(fontSize: 12, color: _selectedStartDate == null ? AppColors.textSecondary(context) : AppColors.textPrimary(context))),
            ]),
          ),
        ),
      ]);

  Widget _buildActions() => Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context)))),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text('Añadir a mi Biblioteca', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ]);
}

