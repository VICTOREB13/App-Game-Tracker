/// Modelo inmutable que transporta los detalles configurados por el usuario
/// para incorporar un juego desde el buscador RAWG hacia la biblioteca SQLite.
class GameDetailsResult {
  final String status;
  final String platform;
  final DateTime? startDate;
  final num hoursPlayed;
  final List<String> genres;

  const GameDetailsResult({
    required this.status,
    required this.platform,
    required this.startDate,
    required this.hoursPlayed,
    required this.genres,
  });
}
