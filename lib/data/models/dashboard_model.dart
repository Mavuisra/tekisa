/// Modèle réponse API dashboard parent : parent + enfants avec stats
library;

class DashboardModel {
  const DashboardModel({required this.parent, required this.children});

  final DashboardParent? parent;
  final List<DashboardChild> children;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final parentJson = json['parent'];
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return DashboardModel(
      parent: parentJson != null
          ? DashboardParent.fromJson(
              Map<String, dynamic>.from(parentJson as Map),
            )
          : null,
      children: childrenJson
          .map(
            (e) => DashboardChild.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}

class DashboardParent {
  const DashboardParent({required this.fullName, this.id});

  final String fullName;
  final int? id;

  factory DashboardParent.fromJson(Map<String, dynamic> json) {
    return DashboardParent(
      fullName: json['full_name'] as String? ?? '',
      id: json['id'] as int?,
    );
  }
}

class DashboardChild {
  const DashboardChild({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.schoolName = '',
    this.classroomName = '',
    this.attendanceDaysThisMonth = 0,
    this.average,
    this.unpaidInvoicesCount = 0,
    this.pendingAmount = 0,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String schoolName;
  final String classroomName;
  final int attendanceDaysThisMonth;
  final double? average;
  final int unpaidInvoicesCount;
  final double pendingAmount;

  String get displayName => '$firstName $lastName'.trim();

  factory DashboardChild.fromJson(Map<String, dynamic> json) {
    return DashboardChild(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      classroomName: json['classroom_name'] as String? ?? '',
      attendanceDaysThisMonth: json['attendance_days_this_month'] as int? ?? 0,
      average: (json['average'] as num?)?.toDouble(),
      unpaidInvoicesCount: json['unpaid_invoices_count'] as int? ?? 0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
