class Project {
  Project.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      title = json['title'] as String,
      description = json['description'] as String?,
      startDate = json['startDate'] as String,
      endDate = json['endDate'] as String?,
      archived = json['archivedAt'] != null,
      totalTasks = json['totalTasks'] as int,
      completedTasks = json['completedTasks'] as int,
      progressPercentage = (json['progressPercentage'] as num).toDouble();
  final String id, title, startDate;
  final String? description, endDate;
  final bool archived;
  final int totalTasks, completedTasks;
  final double progressPercentage;
}
