class ActivityCategory {
  const ActivityCategory({
    required this.id,
    required this.slug,
    required this.name,
  });
  final String id;
  final String slug;
  final String name;
  factory ActivityCategory.fromJson(Map<String, dynamic> json) =>
      ActivityCategory(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
      );
}
