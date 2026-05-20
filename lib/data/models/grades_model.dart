library;

class TermResultModel {
  const TermResultModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.termId,
    required this.termName,
    this.schoolName = '',
    required this.averageScore,
    this.rankInClass,
  });

  final int id;
  final int studentId;
  final String studentName;
  final int termId;
  final String termName;
  final String schoolName;
  final double averageScore;
  final int? rankInClass;

  factory TermResultModel.fromJson(Map<String, dynamic> json) {
    return TermResultModel(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String? ?? '',
      termId: json['term_id'] as int,
      termName: json['term_name'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      averageScore: (json['average_score'] as num).toDouble(),
      rankInClass: json['rank_in_class'] as int?,
    );
  }
}

class GradeModel {
  const GradeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subjectName,
    required this.title,
    required this.score,
    required this.maxScore,
    this.date,
    this.remarks = '',
  });

  final int id;
  final int studentId;
  final String studentName;
  final String subjectName;
  final String title;
  final double score;
  final double maxScore;
  final String? date;
  final String remarks;

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    return GradeModel(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      score: (json['score'] as num).toDouble(),
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0,
      date: json['date'] as String?,
      remarks: json['remarks'] as String? ?? '',
    );
  }
}
