library;

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    this.currency = 'CDF',
    required this.dueDate,
    required this.status,
    this.description = '',
  });

  final int id;
  final int studentId;
  final String studentName;
  final double amount;
  final String currency;
  final String dueDate;
  final String status;
  final String description;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      studentName: json['student_name'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'CDF',
      dueDate: json['due_date'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      description: json['description'] as String? ?? '',
    );
  }
}
