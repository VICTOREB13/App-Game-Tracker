import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Tarjeta de configuración para alternar el tema visual de la aplicación
class ThemeSettingsCard extends StatelessWidget {
  const ThemeSettingsCard({super.key});

  Widget _buildThemeOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFDC2626)
                : AppColors.surfaceSubtle(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFDC2626)
                  : AppColors.border(context),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary(context),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        final current = ThemeManager.instance.themeMode;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tema Visual',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildThemeOption(
                    context: context,
                    label: 'Oscuro',
                    icon: Icons.dark_mode_rounded,
                    isSelected: current == ThemeMode.dark,
                    onTap: () =>
                        ThemeManager.instance.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 10),
                  _buildThemeOption(
                    context: context,
                    label: 'Claro',
                    icon: Icons.light_mode_rounded,
                    isSelected: current == ThemeMode.light,
                    onTap: () =>
                        ThemeManager.instance.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 10),
                  _buildThemeOption(
                    context: context,
                    label: 'Sistema',
                    icon: Icons.brightness_auto_rounded,
                    isSelected: current == ThemeMode.system,
                    onTap: () =>
                        ThemeManager.instance.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

