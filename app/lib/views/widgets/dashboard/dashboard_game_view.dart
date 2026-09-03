import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/game.dart';
import '../../../services/theme_manager.dart';
import 'dashboard_skeleton_grid.dart';
import 'game_card_grid.dart';
import 'game_card_list.dart';

/// Vista de contenido del Dashboard que orquesta la cuadrícula, la lista o el estado vacío con soporte de zoom
class DashboardGameView extends StatelessWidget {
  final bool isLoading;
  final bool isGridView;
  final List<Game> paginatedGames;
  final double gridCardExtent;
  final String searchQuery;
  final bool isAnyFilterActive;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearFilters;
  final ValueChanged<Game> onGameTap;
  final ValueChanged<Game> onGameLongPress;
  final ValueChanged<Game> onQuickAddHours;
  final ValueChanged<double> onGridCardExtentChanged;

  const DashboardGameView({
    super.key,
    required this.isLoading,
    required this.isGridView,
    required this.paginatedGames,
    required this.gridCardExtent,
    required this.searchQuery,
    required this.isAnyFilterActive,
    required this.onRefresh,
    required this.onClearFilters,
    required this.onGameTap,
    required this.onGameLongPress,
    required this.onQuickAddHours,
    required this.onGridCardExtentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent &&
            HardwareKeyboard.instance.isControlPressed &&
            isGridView) {
          if (event.scrollDelta.dy < 0) {
            onGridCardExtentChanged(gridCardExtent + 25);
          } else if (event.scrollDelta.dy > 0) {
            onGridCardExtentChanged(gridCardExtent - 25);
          }
        }
      },
      child: isLoading
          ? DashboardSkeletonGrid(cardExtent: gridCardExtent)
          : RefreshIndicator(
              color: const Color(0xFFDC2626),
              backgroundColor: AppColors.surface(context),
              onRefresh: onRefresh,
              child: paginatedGames.isEmpty
                  ? _buildEmptyState(context)
                  : isGridView
                      ? _buildGridView()
                      : _buildListView(),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.gamepad_outlined,
              size: 64,
              color: const Color(0xFF71717A).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'No se encontraron juegos para "$searchQuery"'
                  : 'No hay juegos con los filtros seleccionados',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFFA1A1AA),
                fontSize: 14,
              ),
            ),
            if (isAnyFilterActive) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Restablecer filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: gridCardExtent,
        childAspectRatio: 0.62,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: paginatedGames.length,
      itemBuilder: (context, index) {
        final game = paginatedGames[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey('grid_${game.id}_$index'),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + ((index % 10) * 30)),
          curve: Curves.easeOutQuart,
          builder: (context, animValue, child) => Opacity(
            opacity: animValue,
            child: Transform.translate(
              offset: Offset(0, 14 * (1.0 - animValue)),
              child: child,
            ),
          ),
          child: GameCardGrid(
            game: game,
            onTap: () => onGameTap(game),
            onLongPress: () => onGameLongPress(game),
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: paginatedGames.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final game = paginatedGames[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey('list_${game.id}_$index'),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 250 + ((index % 10) * 25)),
          curve: Curves.easeOutQuart,
          builder: (context, animValue, child) => Opacity(
            opacity: animValue,
            child: Transform.translate(
              offset: Offset(0, 10 * (1.0 - animValue)),
              child: child,
            ),
          ),
          child: GameCardList(
            game: game,
            onTap: () => onGameTap(game),
            onLongPress: () => onGameLongPress(game),
            onQuickAddHours: () => onQuickAddHours(game),
          ),
        );
      },
    );
  }
}

