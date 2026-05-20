library;

class ConversationModel {
  const ConversationModel({
    required this.id,
    this.title = '',
    this.schoolName = '',
    this.lastMessageAt,
    this.lastPreview = '',
  });

  final int id;
  final String title;
  final String schoolName;
  final String? lastMessageAt;
  final String lastPreview;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      lastMessageAt: json['last_message_at'] as String?,
      lastPreview: json['last_preview'] as String? ?? '',
    );
  }
}

class ConversationMessageModel {
  const ConversationMessageModel({
    required this.id,
    required this.body,
    required this.isMine,
    required this.createdAt,
  });

  final int id;
  final String body;
  final bool isMine;
  final String createdAt;

  factory ConversationMessageModel.fromJson(Map<String, dynamic> json) {
    return ConversationMessageModel(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      isMine: json['is_mine'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
