import '../../dashboard/data/category.dart';

class ActivityRevision {
  ActivityRevision.fromJson(Map<String, dynamic> json)
    : title = json['title'] as String,
      description = json['description'] as String?,
      category = ActivityCategory.fromJson(
        Map<String, dynamic>.from(json['category'] as Map),
      ),
      targetQuantity = json['targetQuantity'] as String,
      unit = json['unit'] as String,
      targetCount = json['targetCount'] as int,
      endDate = json['endDate'] as String?,
      effectiveFrom = json['effectiveFrom'] as String,
      xpPerCompletion = json['xpPerCompletion'] as int;
  final String title, targetQuantity, unit, effectiveFrom;
  final String? description, endDate;
  final ActivityCategory category;
  final int targetCount, xpPerCompletion;
}

class Activity {
  Activity.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      frequency = json['frequency'] as String,
      startDate = json['startDate'] as String,
      scheduleTimeZone = json['scheduleTimeZone'] as String,
      projectId = json['projectId'] as String?,
      archived = json['archivedAt'] != null,
      currentRevision = ActivityRevision.fromJson(
        Map<String, dynamic>.from(json['currentRevision'] as Map),
      ),
      pendingRevision = json['pendingRevision'] == null
          ? null
          : ActivityRevision.fromJson(
              Map<String, dynamic>.from(json['pendingRevision'] as Map),
            );
  final String id, frequency, startDate, scheduleTimeZone;
  final String? projectId;
  final bool archived;
  final ActivityRevision currentRevision;
  final ActivityRevision? pendingRevision;
}

class OccurrenceUnit {
  OccurrenceUnit.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      position = json['position'] as int,
      progressQuantity = json['progressQuantity'] as String,
      targetQuantity = json['targetQuantity'] as String,
      remainingQuantity = json['remainingQuantity'] as String,
      completed = json['completionId'] != null;
  final String id, progressQuantity, targetQuantity, remainingQuantity;
  final int position;
  final bool completed;
}

class Occurrence {
  Occurrence.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      scheduledDate = json['scheduledDate'] as String,
      status = json['status'] as String,
      endsAt = DateTime.parse(json['endsAt'] as String),
      revision = ActivityRevision.fromJson(
        Map<String, dynamic>.from(json['revision'] as Map),
      ),
      units = (json['units'] as List)
          .map(
            (item) =>
                OccurrenceUnit.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
  final String id, scheduledDate, status;
  final DateTime endsAt;
  final ActivityRevision revision;
  final List<OccurrenceUnit> units;
}
