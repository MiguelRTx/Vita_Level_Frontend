import '../../profile/data/profile.dart';

typedef StatisticsFilter = ({
  String from,
  String to,
  String? categoryId,
  String interval,
});
Map<String, dynamic> statisticsQuery(StatisticsFilter filter) => {
  'from': filter.from,
  'to': filter.to,
  if (filter.categoryId != null) 'categoryId': filter.categoryId,
  'interval': filter.interval,
};

class XpPoint {
  XpPoint.fromJson(Map<String, dynamic> json)
    : startDate = json['startDate'] as String,
      endDate = json['endDate'] as String,
      earnedXp = json['earnedXp'] as int,
      cumulativeXp = json['cumulativeXp'] as int;
  final String startDate, endDate;
  final int earnedXp, cumulativeXp;
}

class CategoryBar {
  CategoryBar.fromJson(Map<String, dynamic> json)
    : name = json['categoryName'] as String,
      planned = json['planned'] as int,
      completed = json['completed'] as int;
  final String name;
  final int planned, completed;
}

class StatusSlice {
  StatusSlice.fromJson(Map<String, dynamic> json)
    : status = json['status'] as String,
      count = json['count'] as int,
      percentage = (json['percentage'] as num).toDouble();
  final String status;
  final int count;
  final double percentage;
}

class HeatDay {
  HeatDay.fromJson(Map<String, dynamic> json)
    : date = json['date'] as String,
      count = json['count'] as int;
  final String date;
  final int count;
}

class DashboardData {
  DashboardData.fromJson(Map<String, dynamic> json)
    : profile = GamificationSummary.fromJson(
        Map<String, dynamic>.from(json['profile'] as Map),
      ),
      timeZone = json['timeZone'] as String {
    final planning = json['planning'] as Map, earned = json['earned'] as Map;
    completionPercentage = (planning['completionPercentage'] as num).toDouble();
    plannedOccurrences = planning['plannedOccurrences'] as int;
    goalsReached = earned['goalsReached'] as int;
    completionCount = earned['completionCount'] as int;
    xpEarned = earned['xpEarned'] as int;
    openingXp = earned['openingXp'] as int;
    bars = (planning['byCategory'] as List)
        .map(
          (row) => CategoryBar.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    slices = (planning['statusDistribution'] as List)
        .map(
          (row) => StatusSlice.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
    xpSeries = (earned['xpSeries'] as List)
        .map((row) => XpPoint.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
    heatmap = (earned['heatmap'] as List)
        .map((row) => HeatDay.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
  final GamificationSummary profile;
  final String timeZone;
  late final int plannedOccurrences,
      goalsReached,
      completionCount,
      xpEarned,
      openingXp;
  late final double completionPercentage;
  late final List<CategoryBar> bars;
  late final List<StatusSlice> slices;
  late final List<XpPoint> xpSeries;
  late final List<HeatDay> heatmap;
}
