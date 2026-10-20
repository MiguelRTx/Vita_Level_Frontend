class HistoryItem {
  HistoryItem.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['activityTitle'] as String,
      categoryName = (json['category'] as Map)['name'] as String,
      activityId = json['activityId'] as String,
      localDate = json['localDate'] as String,
      timeZone = json['timeZone'] as String,
      xp = (json['xpAwarded'] ?? json['amount']) as int,
      position = json['position'] as int?,
      recordedAt = DateTime.parse(
        (json['completedAt'] ?? json['createdAt']) as String,
      );
  final String id, title, categoryName, activityId, localDate, timeZone;
  final int xp;
  final int? position;
  final DateTime recordedAt;
}
