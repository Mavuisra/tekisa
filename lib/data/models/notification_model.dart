/// Modèle pour les notifications parent (annonces / devoirs des enseignants).
library;

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.payloadJson,
    this.createdAt,
  });

  final int id;
  final String type;
  final Map<String, dynamic> payloadJson;
  final String? createdAt;

  /// Pour type teacher_post : titre de l'annonce / devoir
  String get title => payloadJson['title'] as String? ?? '';

  /// Pour type teacher_post : description
  String get body => payloadJson['body'] as String? ?? '';

  /// Pour type teacher_post : date limite (YYYY-MM-DD)
  String get dueDate => payloadJson['due_date'] as String? ?? '';

  /// Pour type teacher_post : nom de la classe
  String get classroomName => payloadJson['classroom_name'] as String? ?? '';

  /// Pour type teacher_post : nom de l'élève concerné
  String get studentName => payloadJson['student_name'] as String? ?? '';

  /// Pour type teacher_post : nom du professeur
  String get teacherName => payloadJson['teacher_name'] as String? ?? '';

  /// Pour type teacher_post : assignment | exercise | announcement
  String get postType => payloadJson['post_type'] as String? ?? '';

  String get postTypeLabel {
    switch (postType) {
      case 'assignment':
        return 'Devoir';
      case 'exercise':
        return 'Exercice';
      case 'announcement':
        return 'Annonce';
      default:
        return postType.isNotEmpty ? postType : 'Publication';
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final payload = json['payload_json'];
    return NotificationModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      payloadJson: payload is Map ? Map<String, dynamic>.from(payload) : {},
      createdAt: json['created_at'] as String?,
    );
  }
}
