import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/dashboard_controller.dart';
import '../../models/game.dart';
import '../../services/secure_storage_service.dart';
import '../widgets/dashboard/dashboard_app_bar.dart';
import '../widgets/dashboard/dashboard_filter_bar.dart';
import '../widgets/dashboard/dashboard_game_view.dart';
import '../widgets/dashboard/dashboard_view_header.dart';
import '../widgets/dashboard/hero_spotlight_card.dart';
import '../widgets/dashboard/pagination_control_bar.dart';
import '../widgets/dashboard/quick_action_bottom_sheet.dart';
import '../widgets/dashboard/steam_sync_dialog.dart';
import '../widgets/fluid_page_route.dart';
import 'analytics_screen.dart';
import 'game_detail_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final DashboardController? controller;

  const DashboardScreen({super.key, this.controller});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final DashboardController _controller;
  final _searchController = TextEditingController();
  late final AnimationController _pulseController;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DashboardController();
    _controller.addListener(_onControllerUpdate);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    unawaited(_controller.initialize());
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() => _isSearchActive = false);
    _searchController.clear();
    unawaited(_controller.clearFilters());
  }

  Future<void> _syncWithSteam() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = await SecureStorageService.instance.getSteamApiKey() ?? '';
    final steamId = prefs.getString('steam_user_id') ?? '';
    if (apiKey.isEmpty || steamId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Configura tu Steam API Key y Steam ID en Ajustes.'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ajustes',
            textColor: Colors.white,
            onPressed: () => Navigator.push<void>(
              context,
              fluidPageRoute(const SettingsScreen()),
            ).then((_) => _controller.refresh()),
          ),
        ));
      }
      return;
    }
    final result = await SteamSyncDialog.show(
      context: context,
      apiKey: apiKey,
      steamId: steamId,
    );
    if (mounted && result != null) {
      await _controller.refresh();
    }
  }

  Future<void> _quickAddHours(Game game, num delta) async {
    await _controller.quickAddHours(game, delta);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('+${delta}h registradas en ${game.title}'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _quickChangeStatus(Game game, String newStatus) async {
    await _controller.updateGameStatus(game, newStatus);
  }

  Future<void> _openDetail(Game game) async {
    final res = await Navigator.push<bool>(
      context,
      fluidPageRoute(GameDetailScreen(game: game)),
    );
    if (mounted && res == true) {
      await _controller.refresh();
    }
  }

  Future<void> _openSearch() async {
    final res = await Navigator.push<bool>(
      context,
      fluidPageRoute(const SearchScreen()),
    );
    if (mounted && res == true) {
      await _controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DashboardAppBar(
        isSearchActive: _isSearchActive,
        searchController: _searchController,
        searchQuery: _controller.searchQuery,
        isRefreshing: _controller.isRefreshing,
        onSearchQueryChanged: (val) => unawaited(_controller.setSearchQuery(val)),
        onSearchToggle: () {
          setState(() => _isSearchActive = !_isSearchActive);
          if (!_isSearchActive) {
            _searchController.clear();
            unawaited(_controller.setSearchQuery(''));
          }
        },
        onClearSearch: () {
          _searchController.clear();
          unawaited(_controller.setSearchQuery(''));
        },
        onSteamSync: () => unawaited(_syncWithSteam()),
        onRefresh: () => unawaited(_controller.refresh()),
        onOpenAnalytics: () => Navigator.push<void>(
          context,
          fluidPageRoute(const AnalyticsScreen()),
        ),
        onOpenSettings: () async {
          final res = await Navigator.push<bool>(
            context,
            fluidPageRoute(const SettingsScreen()),
          );
          if (mounted && res == true) {
            await _controller.refresh();
          }
        },
      ),
      body: Column(
        children: [
          if (!_isSearchActive && _controller.heroGame != null && !_controller.isLoading)
            HeroSpotlightCard(
              game: _controller.heroGame!,
              pulseAnimation: _pulseController,
              onTap: () => _openDetail(_controller.heroGame!),
              onQuickAddHours: () => unawaited(_quickAddHours(_controller.heroGame!, 1)),
            ),
          DashboardFilterBar(
            selectedStatus: _controller.statusFilter,
            selectedPlatform: _controller.platformFilter,
            selectedGenre: _controller.genreFilter,
            selectedSort: _controller.sortOption,
            platformOptions: _controller.platformOptions,
            genreOptions: _controller.genreOptions,
            activeFiltersCount: _controller.activeFiltersCount,
            onStatusSelected: (v) => unawaited(_controller.setStatusFilter(v)),
            onPlatformSelected: (v) => unawaited(_controller.setPlatformFilter(v)),
            onGenreSelected: (v) => unawaited(_controller.setGenreFilter(v)),
            onSortSelected: (v) => unawaited(_controller.setSortOption(v)),
            onClearFilters: _clearAllFilters,
          ),
          DashboardViewHeader(
            filteredGamesCount: _controller.filteredGamesCount,
            totalGamesCount: _controller.totalGamesCount,
            searchQuery: _controller.searchQuery,
            isGridView: _controller.isGridView,
            gridCardExtent: _controller.gridCardExtent,
            onToggleViewMode: () => unawaited(_controller.toggleViewMode()),
            onGridCardExtentChanged: (v) => unawaited(_controller.setGridCardExtent(v)),
          ),
          Expanded(
            child: DashboardGameView(
              isLoading: _controller.isLoading,
              isGridView: _controller.isGridView,
              paginatedGames: _controller.paginatedGames,
              gridCardExtent: _controller.gridCardExtent,
              searchQuery: _controller.searchQuery,
              isAnyFilterActive: _controller.activeFiltersCount > 0,
              onRefresh: () => _controller.refresh(),
              onClearFilters: _clearAllFilters,
              onGameTap: _openDetail,
              onGameLongPress: (game) => QuickActionBottomSheet.show(
                context: context,
                game: game,
                onAddHours: (delta) => unawaited(_quickAddHours(game, delta)),
                onStatusChange: (status) => unawaited(_quickChangeStatus(game, status)),
                onEditDetails: () => _openDetail(game),
              ),
              onQuickAddHours: (game) => unawaited(_quickAddHours(game, 1)),
              onGridCardExtentChanged: (v) => unawaited(_controller.setGridCardExtent(v)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: PaginationControlBar(
        totalItems: _controller.filteredGamesCount,
        currentPage: _controller.currentPage,
        pageSize: _controller.pageSize,
        totalPages: _controller.totalPages,
        onPageChanged: (page) => _controller.setPage(page),
        onPageSizeChanged: (size) => unawaited(_controller.setPageSize(size)),
        onAddGame: _openSearch,
      ),
    );
  }
}
