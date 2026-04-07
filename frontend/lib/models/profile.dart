class Profile {
  final String id;
  final String? steamId;
  final String? psnId;
  final String? xboxId;
  final DateTime? lastSyncAt;

  Profile({
    required this.id,
    this.steamId,
    this.psnId,
    this.xboxId,
    this.lastSyncAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      steamId: json['steam_id'],
      psnId: json['psn_id'],
      xboxId: json['xbox_id'],
      lastSyncAt: json['last_sync_at'] != null 
          ? DateTime.parse(json['last_sync_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'steam_id': steamId,
      'psn_id': psnId,
      'xbox_id': xboxId,
      'last_sync_at': lastSyncAt?.toIso8601String(),
    };
  }
}
