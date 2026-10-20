class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.rule,
    required this.threshold,
    required this.unlockedAt,
    required this.kind,
  });
  final String id;
  final String name;
  final String description;
  final String rule;
  final int threshold;
  final DateTime? unlockedAt;
  final String? kind;
  factory Achievement.fromJson(Map<String, dynamic> json) {
    final date = json['earnedAt'] ?? json['unlockedAt'];
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      rule: json['rule'] as String,
      threshold: json['threshold'] as int,
      unlockedAt: date == null ? null : DateTime.parse(date as String),
      kind: json['kind'] as String?,
    );
  }
}
