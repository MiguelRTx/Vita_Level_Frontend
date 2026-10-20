class GamificationSummary {
  const GamificationSummary({
    required this.totalXp,
    required this.level,
    required this.xpInLevel,
    required this.xpRequiredForNextLevel,
    required this.xpToNextLevel,
    required this.nextLevel,
    required this.levelProgress,
    required this.currentStreak,
    required this.bestStreak,
  });
  final int totalXp;
  final int level;
  final int xpInLevel;
  final int? xpRequiredForNextLevel;
  final int? xpToNextLevel;
  final int? nextLevel;
  final double levelProgress;
  final int currentStreak;
  final int bestStreak;
  factory GamificationSummary.fromJson(Map<String, dynamic> json) =>
      GamificationSummary(
        totalXp: json['totalXp'] as int,
        level: json['level'] as int,
        xpInLevel: json['xpInLevel'] as int,
        xpRequiredForNextLevel: json['xpRequiredForNextLevel'] as int?,
        xpToNextLevel: json['xpToNextLevel'] as int?,
        nextLevel: json['nextLevel'] as int?,
        levelProgress: (json['levelProgress'] as num).toDouble(),
        currentStreak: json['currentStreak'] as int,
        bestStreak: json['bestStreak'] as int,
      );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.timeZone,
    required this.gamification,
    required this.badgeCount,
  });
  final String id;
  final String email;
  final String displayName;
  final String timeZone;
  final GamificationSummary gamification;
  final int badgeCount;
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    timeZone: json['timeZone'] as String,
    gamification: GamificationSummary.fromJson(
      Map<String, dynamic>.from(json['gamification'] as Map),
    ),
    badgeCount: (json['badges'] as List).length,
  );
}
