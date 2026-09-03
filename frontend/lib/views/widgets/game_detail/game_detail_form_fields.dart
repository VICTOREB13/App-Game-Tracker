import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../services/theme_manager.dart';
import '../platform_helper.dart';
import '../status_helper.dart';

/// Encabezado tipográfico uniforme para secciones de detalle
class GameSectionHeader extends StatelessWidget {
  final String title;

  const GameSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFDC2626),
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Botón estilizado para incrementar rápidamente horas de juego (+30m, +1h, +2h)
class QuickHourButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const QuickHourButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton(
      onPressed: onPressed,
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
}

/// Dropdown reutilizable con iconos automáticos para plataformas y estados
class GameDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const GameDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPlatform = label.toLowerCase().contains('plataforma');
    final isStatus = label.toLowerCase().contains('estado');
    final effectiveItems = isPlatform
        ? PlatformHelper.getOrderedPlatforms(currentPlatform: value)
        : items;

    return DropdownButtonFormField<String>(
      value: effectiveItems.contains(value) ? value : effectiveItems.first,
      dropdownColor: AppColors.surface(context),
      borderRadius: BorderRadius.circular(12),
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textPrimary(context),
      ),
      items: effectiveItems
          .map((s) => DropdownMenuItem(
                value: s,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPlatform) ...[
                      PlatformHelper.getIcon(s, size: 16),
                      const SizedBox(width: 8),
                    ] else if (isStatus) ...[
                      Icon(
                        StatusHelper.getIcon(s),
                        size: 16,
                        color: StatusHelper.getColor(s),
                      ),
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
}

/// Selector de fechas con visualización formateada y botón de borrado opcional
class GameDatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const GameDatePickerField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                if (date != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 6),
                Text(
                  date == null ? 'Seleccionar' : DateFormat('dd/MM/yyyy').format(date!),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary(context),
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

/// Bloque compuesto para registrar y sumar horas con botones rápidos
class GameHoursEditor extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<double> onAddHours;
  final VoidCallback onChanged;

  const GameHoursEditor({
    super.key,
    required this.controller,
    required this.onAddHours,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GameSectionHeader('Horas Jugadas'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.timer_outlined, color: AppColors.textSecondary(context)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            QuickHourButton(label: '+30m', onPressed: () => onAddHours(0.5)),
            const SizedBox(width: 6),
            QuickHourButton(label: '+1h', onPressed: () => onAddHours(1.0)),
            const SizedBox(width: 6),
            QuickHourButton(label: '+2h', onPressed: () => onAddHours(2.0)),
          ],
        ),
      ],
    );
  }
}

/// Bloque compuesto para la selección de fechas de inicio y culminación
class GameDatesEditor extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? completedDate;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectCompletedDate;
  final VoidCallback onClearStartDate;
  final VoidCallback onClearCompletedDate;

  const GameDatesEditor({
    super.key,
    required this.startDate,
    required this.completedDate,
    required this.onSelectStartDate,
    required this.onSelectCompletedDate,
    required this.onClearStartDate,
    required this.onClearCompletedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GameSectionHeader('Fechas de Registro'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GameDatePickerField(
                label: 'Fecha de Inicio',
                date: startDate,
                onTap: onSelectStartDate,
                onClear: onClearStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GameDatePickerField(
                label: 'Culminación (1ra Campaña)',
                date: completedDate,
                onTap: onSelectCompletedDate,
                onClear: onClearCompletedDate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Campo con botón y loader para vincular artículo enciclopédico de Wikipedia
class GameWikipediaField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearch;
  final VoidCallback onChanged;

  const GameWikipediaField({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
      decoration: InputDecoration(
        labelText: 'Enlace Enciclopédico (Wikipedia)',
        hintText: 'https://es.wikipedia.org/wiki/...',
        prefixIcon: const Icon(Icons.public_rounded, size: 18, color: Color(0xFFDC2626)),
        suffixIcon: isSearching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                ),
              )
            : IconButton(
                tooltip: 'Buscar en Wikipedia',
                icon: const Icon(Icons.travel_explore_rounded, color: Color(0xFFDC2626), size: 20),
                onPressed: onSearch,
              ),
      ),
    );
  }
}

/// Campos editables de estimaciones HowLongToBeat con botón de búsqueda
class GameHltbInputs extends StatelessWidget {
  final TextEditingController mainController;
  final TextEditingController compController;
  final bool isFetching;
  final VoidCallback onFetch;
  final VoidCallback onChanged;

  const GameHltbInputs({
    super.key,
    required this.mainController,
    required this.compController,
    required this.isFetching,
    required this.onFetch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const GameSectionHeader('Metadatos HowLongToBeat'),
            TextButton.icon(
              onPressed: isFetching ? null : onFetch,
              icon: isFetching
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                    )
                  : const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFDC2626)),
              label: Text(
                isFetching ? 'Buscando...' : 'Buscar en HLTB',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: mainController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(labelText: 'Historia (hrs)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: compController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(labelText: '100% (hrs)'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Botón principal de guardado con spinner de progreso
class GameSaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onSave;

  const GameSaveButton({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSaving ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFFDC2626).withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                'Guardar Cambios',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

/// Muestra un diálogo de confirmación para eliminar un juego
Future<bool> showDeleteGameDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border(ctx)),
          ),
          title: Text(
            '¿Eliminar juego?',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary(ctx),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Este videojuego será eliminado de tu base de datos local.',
            style: GoogleFonts.inter(color: AppColors.textSecondary(ctx)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(ctx))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
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
}

