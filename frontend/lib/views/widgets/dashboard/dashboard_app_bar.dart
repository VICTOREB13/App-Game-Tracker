import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/theme_manager.dart';

/// Barra de navegación superior responsiva del Dashboard con búsqueda animada y acciones rápidas
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearchActive;
  final TextEditingController searchController;
  final String searchQuery;
  final bool isRefreshing;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onSearchToggle;
  final VoidCallback onClearSearch;
  final VoidCallback onSteamSync;
  final VoidCallback onRefresh;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenSettings;

  const DashboardAppBar({
    super.key,
    required this.isSearchActive,
    required this.searchController,
    required this.searchQuery,
    required this.isRefreshing,
    required this.onSearchQueryChanged,
    required this.onSearchToggle,
    required this.onClearSearch,
    required this.onSteamSync,
    required this.onRefresh,
    required this.onOpenAnalytics,
    required this.onOpenSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      titleSpacing: isMobile ? 12 : null,
      title: isSearchActive
          ? TextField(
              controller: searchController,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Buscar en tu biblioteca (SQL)...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textSecondary(context),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary(context),
                          size: 20,
                        ),
                        onPressed: onClearSearch,
                      )
                    : null,
              ),
              onChanged: onSearchQueryChanged,
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'AGT',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Victor ',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        TextSpan(
                          text: 'Engineer',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        IconButton(
          icon: Icon(
            isSearchActive ? Icons.close_rounded : Icons.search_rounded,
            color: isSearchActive
                ? const Color(0xFFDC2626)
                : AppColors.textPrimary(context),
          ),
          tooltip: isSearchActive ? 'Cerrar búsqueda' : 'Buscar juegos',
          onPressed: onSearchToggle,
        ),
        if (!isSearchActive) ...[
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFFDC2626)),
              tooltip: 'Estadísticas',
              onPressed: onOpenAnalytics,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary(context)),
              tooltip: 'Más opciones',
              color: AppColors.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border(context)),
              ),
              onSelected: (val) {
                switch (val) {
                  case 'theme':
                    ThemeManager.instance.toggleTheme();
                    break;
                  case 'steam_sync':
                    onSteamSync();
                    break;
                  case 'refresh':
                    onRefresh();
                    break;
                  case 'settings':
                    onOpenSettings();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF71717A),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isDark ? 'Modo Claro' : 'Modo Oscuro',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'steam_sync',
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 10),
                      Text(
                        'Sincronizar Steam',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFA1A1AA)),
                      const SizedBox(width: 10),
                      Text(
                        'Recargar Local',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_rounded, size: 18, color: Color(0xFF71717A)),
                      const SizedBox(width: 10),
                      Text(
                        'Configuración',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF71717A),
              ),
              tooltip: isDark ? 'Cambiar a Modo Claro' : 'Cambiar a Modo Oscuro',
              onPressed: () => ThemeManager.instance.toggleTheme(),
            ),
            IconButton(
              icon: isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFDC2626),
                      ),
                    )
                  : const Icon(Icons.sync_rounded, color: Color(0xFFDC2626)),
              tooltip: 'Sincronizar con Steam',
              onPressed: isRefreshing ? null : onSteamSync,
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded, color: Color(0xFFDC2626)),
              tooltip: 'Estadísticas',
              onPressed: onOpenAnalytics,
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Color(0xFF71717A)),
              tooltip: 'Configuración',
              onPressed: onOpenSettings,
            ),
          ],
        ],
      ],
    );
  }
}

