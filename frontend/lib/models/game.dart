class Game {
  final String id;
  final String title;
  final String? coverUrl;
  final String? status;
  final String? platform;
  final num? hoursPlayed;
  final String? genre;
  final String? tags;
  final num? hltbMain;
  final num? hltbCompletionist;
  final DateTime? firstCompletedAt;
  final DateTime? lastPlayedAt;
  final String? provider;
  final bool isManual;

  Game({
    required this.id,
    required this.title,
    this.coverUrl,
    this.status,
    this.platform,
    this.hoursPlayed,
    this.genre,
    this.tags,
    this.hltbMain,
    this.hltbCompletionist,
    this.firstCompletedAt,
    this.lastPlayedAt,
    this.provider,
    this.isManual = false,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'].toString(),
      title: json['title'] ?? 'Desconocido',
      coverUrl: json['cover_url'],
      status: json['status'],
      platform: json['platform'],
      hoursPlayed: json['hours_played'],
      genre: json['genre'],
      tags: json['tags'],
      hltbMain: json['hltb_main'],
      hltbCompletionist: json['hltb_completionist'],
      firstCompletedAt: json['first_completed_at'] != null 
          ? DateTime.parse(json['first_completed_at']) 
          : null,
      lastPlayedAt: json['last_played_at'] != null 
          ? DateTime.parse(json['last_played_at']) 
          : null,
      provider: json['provider'],
      isManual: json['is_manual'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cover_url': coverUrl,
      'status': status,
      'platform': platform,
      'hours_played': hoursPlayed,
      'genre': genre,
      'tags': tags,
      'hltb_main': hltbMain,
      'hltb_completionist': hltbCompletionist,
      'first_completed_at': firstCompletedAt?.toIso8601String(),
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'provider': provider,
      'is_manual': isManual,
    };
  }
}
