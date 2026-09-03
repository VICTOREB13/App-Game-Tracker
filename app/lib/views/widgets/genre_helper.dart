import 'package:flutter/material.dart';

class GenreHelper {
  /// Catálogo estándar de géneros soportados en la aplicación
  static const List<String> allGenres = [
    'Acción',
    'Aventura',
    'Acción-aventura',
    'RPG',
    'Rol',
    'Rol de acción',
    'Disparos',
    'Shooter',
    'Estrategia',
    'Simulador',
    'Simulación',
    'Plataformas',
    'Lucha',
    'Puzle',
    'Arcade',
    'Casual',
    'Indie',
    'MMORPG',
    'Massively Multiplayer',
    'Hack and Slash',
    'Souls',
    'Soulslike',
    'Metroidvania',
    'Roguelike',
    'Terror y supervivencia',
    'Carreras',
    'Anime',
    'Gacha',
    'Sigilo',
    'Zombies',
  ];

  // Mapeo canónico para unificar términos bilingües de Notion y RAWG
  static final Map<String, String> _canonicalMap = {
    'action': 'Acción',
    'acción': 'Acción',
    'adventure': 'Aventura',
    'aventura': 'Aventura',
    'shooter': 'Shooter',
    'disparos': 'Shooter',
    'role-playing (rpg)': 'Rol / RPG',
    'rpg': 'Rol / RPG',
    'rol': 'Rol / RPG',
    'racing': 'Carreras',
    'carreras': 'Carreras',
    'fighting': 'Lucha',
    'lucha': 'Lucha',
    'peleas': 'Lucha',
    'platformer': 'Plataformas',
    'plataformas': 'Plataformas',
    'strategy': 'Estrategia',
    'estrategia': 'Estrategia',
    'simulation': 'Simulación',
    'simulación': 'Simulación',
    'puzzle': 'Puzles',
    'puzles': 'Puzles',
    'puzzles': 'Puzles',
    'horror': 'Terror y supervivencia',
    'survival horror': 'Terror y supervivencia',
    'terror y supervivencia': 'Terror y supervivencia',
    'terror': 'Terror y supervivencia',
    'hack and slash': 'Hack and Slash',
    'hack & slash': 'Hack and Slash',
    'soulslike': 'Soulslike',
    'souls-like': 'Soulslike',
    'metroidvania': 'Metroidvania',
    'casual': 'Casual',
    'indie': 'Indie',
    'anime': 'Anime',
    'gacha': 'Gacha',
    'massively multiplayer': 'MMO / Multijugador',
    'mmo': 'MMO / Multijugador',
    'mmorpg': 'MMO / Multijugador',
    'sports': 'Deportes',
    'deportes': 'Deportes',
    'roguelike': 'Roguelike',
    'roguelite': 'Roguelike',
    'card game': 'Cartas',
    'cartas': 'Cartas',
  };

  /// Normaliza un género a su nombre canónico en español
  static String normalize(String genre) {
    final trimmed = genre.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    return _canonicalMap[lower] ?? trimmed;
  }

  /// Evalúa si una lista de géneros de un juego coincide con el género seleccionado
  static bool matches(List<String> gameGenres, String selectedGenre) {
    if (selectedGenre == 'Todos' || selectedGenre.isEmpty) return true;
    final normalizedSelected = normalize(selectedGenre).toLowerCase();

    for (final raw in gameGenres) {
      if (raw.isEmpty) continue;
      final normalizedRaw = normalize(raw).toLowerCase();
      if (normalizedRaw == normalizedSelected) return true;
      if (raw.toLowerCase() == selectedGenre.toLowerCase()) return true;
    }
    return false;
  }

  /// Retorna un icono distintivo y temático para cada género
  static IconData getIcon(String genre) {
    final norm = normalize(genre).toLowerCase();

    if (norm.contains('shooter')) return Icons.gps_fixed_rounded;
    if (norm.contains('acción')) return Icons.sports_esports_rounded;
    if (norm.contains('aventura')) return Icons.explore_rounded;
    if (norm.contains('rpg') || norm.contains('rol')) return Icons.shield_rounded;
    if (norm.contains('carreras')) return Icons.sports_motorsports_rounded;
    if (norm.contains('lucha')) return Icons.flash_on_rounded;
    if (norm.contains('plataforma')) return Icons.stairs_rounded;
    if (norm.contains('terror')) return Icons.warning_amber_rounded;
    if (norm.contains('hack and slash')) return Icons.hardware_rounded;
    if (norm.contains('soulslike')) return Icons.local_fire_department_rounded;
    if (norm.contains('metroidvania')) return Icons.alt_route_rounded;
    if (norm.contains('indie')) return Icons.auto_awesome_rounded;
    if (norm.contains('casual')) return Icons.coffee_rounded;
    if (norm.contains('estrategia')) return Icons.grid_view_rounded;
    if (norm.contains('simulación')) return Icons.architecture_rounded;
    if (norm.contains('gacha')) return Icons.casino_rounded;
    if (norm.contains('anime')) return Icons.face_rounded;
    if (norm.contains('mmo') || norm.contains('multi')) return Icons.groups_rounded;
    if (norm.contains('deporte')) return Icons.sports_soccer_rounded;
    if (norm.contains('puzle')) return Icons.extension_rounded;
    if (norm.contains('rogue')) return Icons.refresh_rounded;
    if (norm.contains('carta')) return Icons.style_rounded;

    return Icons.category_rounded;
  }

  /// Retorna un color de acento armónico para el género
  static Color getColor(String genre) {
    final norm = normalize(genre).toLowerCase();

    if (norm.contains('shooter')) return const Color(0xFFEF4444);
    if (norm.contains('acción')) return const Color(0xFFF97316);
    if (norm.contains('aventura')) return const Color(0xFF10B981);
    if (norm.contains('rpg') || norm.contains('rol')) return const Color(0xFF8B5CF6);
    if (norm.contains('carreras')) return const Color(0xFFF59E0B);
    if (norm.contains('lucha')) return const Color(0xFFE11D48);
    if (norm.contains('plataforma')) return const Color(0xFF06B6D4);
    if (norm.contains('terror')) return const Color(0xFFA855F7);
    if (norm.contains('hack and slash')) return const Color(0xFFDC2626);
    if (norm.contains('soulslike')) return const Color(0xFFEA580C);
    if (norm.contains('metroidvania')) return const Color(0xFF6366F1);
    if (norm.contains('indie')) return const Color(0xFFEC4899);
    if (norm.contains('casual')) return const Color(0xFF14B8A6);
    if (norm.contains('estrategia')) return const Color(0xFF3B82F6);
    if (norm.contains('simulación')) return const Color(0xFF64748B);
    if (norm.contains('gacha')) return const Color(0xFFD946EF);
    if (norm.contains('anime')) return const Color(0xFFF43F5E);
    if (norm.contains('mmo') || norm.contains('multi')) return const Color(0xFF0284C7);

    return const Color(0xFFDC2626);
  }
}
