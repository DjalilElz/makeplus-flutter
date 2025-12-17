/// Announcement Model
/// Represents event announcements with role-based targeting
class AnnouncementModel {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final String
      target; // 'all', 'participants', 'exposants', 'controlleurs', 'gestionnaires'
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional creator details
  final String? creatorName;

  AnnouncementModel({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.target,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id']?.toString() ?? '',
      eventId: json['event']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      target: json['target'] ?? 'all',
      createdBy: json['created_by'] is int
          ? json['created_by']
          : int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      creatorName: json['creator_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': eventId,
      'title': title,
      'description': description,
      'target': target,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'creator_name': creatorName,
    };
  }

  String get targetLabel {
    switch (target) {
      case 'all':
        return 'Tous';
      case 'participants':
        return 'Participants';
      case 'exposants':
        return 'Exposants';
      case 'controlleurs':
        return 'Contrôleurs';
      case 'gestionnaires':
        return 'Gestionnaires';
      default:
        return target;
    }
  }
}
