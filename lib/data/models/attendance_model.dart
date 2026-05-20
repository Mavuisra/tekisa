library;

class AttendanceRecordModel {
  const AttendanceRecordModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    this.reason = '',
    this.classroomName = '',
  });

  final int id;
  final int studentId;
  final String studentName;
  final String date;
  final String status;
  final String reason;
  final String classroomName;

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'present',
      reason: json['reason'] as String? ?? '',
      classroomName: json['classroom_name'] as String? ?? '',
    );
  }
}
