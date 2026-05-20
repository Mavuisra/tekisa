/// Modèles pour les suggestions de cours en ligne (basées sur les notes par matière).
library;

class LearningSuggestionsResponse {
  const LearningSuggestionsResponse({
    required this.studentId,
    required this.studentName,
    required this.suggestions,
  });

  final int studentId;
  final String studentName;
  final List<LearningSuggestionItem> suggestions;

  factory LearningSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    final suggestionsJson = json['suggestions'] as List<dynamic>? ?? [];
    return LearningSuggestionsResponse(
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String? ?? '',
      suggestions: suggestionsJson
          .map(
            (e) => LearningSuggestionItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class LearningSuggestionItem {
  const LearningSuggestionItem({
    required this.subjectName,
    required this.average,
    required this.suggestedCourseTitle,
    required this.reason,
  });

  final String subjectName;
  final double average;
  final String suggestedCourseTitle;
  final String reason;

  factory LearningSuggestionItem.fromJson(Map<String, dynamic> json) {
    return LearningSuggestionItem(
      subjectName: json['subject_name'] as String? ?? '',
      average: (json['average'] as num?)?.toDouble() ?? 0,
      suggestedCourseTitle: json['suggested_course_title'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}
