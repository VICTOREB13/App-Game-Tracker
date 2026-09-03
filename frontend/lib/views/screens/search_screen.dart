import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/game_search_controller.dart';
import '../../models/game_details_result.dart';
import '../../services/theme_manager.dart';
import '../widgets/search/game_details_prompt_dialog.dart';
import '../widgets/search/search_bar_input.dart';
import '../widgets/search/search_empty_state.dart';
import '../widgets/search/search_result_card.dart';

class SearchScreen extends StatefulWidget {
  final GameSearchController? controller;

  const SearchScreen({super.key, this.controller});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final GameSearchController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GameSearchController();
    _controller.addListener(_onControllerChanged);
    unawaited(_controller.loadRawgKey());
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_controller.errorMessage != null && _controller.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!, style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _searchGames(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _controller.clearSearch();
      return;
    }
    await _controller.searchGames(trimmed);
  }

  Future<void> _promptGameDetails(Map<String, dynamic> rawgGame) async {
    final result = await GameDetailsPromptDialog.show(
      context: context,
      rawgGame: rawgGame,
    );
    if (result != null) {
      await _addGameToLibrary(rawgGame: rawgGame, details: result);
    }
  }

  Future<void> _addGameToLibrary({
    required Map<String, dynamic> rawgGame,
    required GameDetailsResult details,
  }) async {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
      ),
    );

    try {
      final newGame = await _controller.addGameToLibrary(
        rawgGame: rawgGame,
        params: AddGameParams(
          status: details.status,
          platform: details.platform,
          hoursPlayed: details.hoursPlayed,
          genres: details.genres,
          startDate: details.startDate,
        ),
      );

      if (mounted) {
        Navigator.pop(context); // Cierra loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡"${newGame.title}" añadido a tu biblioteca!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Regresa al dashboard refrescando
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cierra loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          'Buscar y Añadir Juegos',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SearchBarInput(
                controller: _searchController,
                onSubmitted: _searchGames,
                onClear: () {
                  _searchController.clear();
                  _controller.clearSearch();
                },
                isSearching: _controller.isSearching,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _controller.isSearching
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFDC2626)),
                      )
                    : _controller.results.isEmpty
                        ? SearchEmptyState(
                            query: _searchController.text,
                            hasSearched: _searchController.text.trim().isNotEmpty,
                          )
                        : ListView.builder(
                            itemCount: _controller.results.length,
                            itemBuilder: (context, index) {
                              final game = _controller.results[index];
                              return SearchResultCard(
                                game: game,
                                onAdd: () => _promptGameDetails(game),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
