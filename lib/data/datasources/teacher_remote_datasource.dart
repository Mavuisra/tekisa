/// Source de données enseignant (API REST)
library;

import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/network/dio_client.dart';

class TeacherRemoteDataSource {
  TeacherRemoteDataSource(this._client);

  final DioClient _client;

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.teacherDashboard,
      );
      return Map<String, dynamic>.from(res.data ?? const {});
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<List<Map<String, dynamic>>> getMyClasses() async {
    try {
      final res = await _client.get<List<dynamic>>(
        ApiEndpoints.teacherMyClasses,
      );
      final raw = res.data ?? const [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<Map<String, dynamic>> getClassStudents(int classroomId) async {
    try {
      final res = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.teacherClassStudents(classroomId),
      );
      return Map<String, dynamic>.from(res.data ?? const {});
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<List<Map<String, dynamic>>> getMyGrades() async {
    try {
      final res = await _client.get<List<dynamic>>(
        ApiEndpoints.teacherMyGrades,
      );
      final raw = res.data ?? const [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<List<Map<String, dynamic>>> getMyAttendance({
    String? month,
    int? classroomId,
  }) async {
    try {
      final qp = <String, dynamic>{
        if (month?.isNotEmpty ?? false) 'month': month,
        if (classroomId != null) 'classroom_id': classroomId,
      };
      final res = await _client.get<List<dynamic>>(
        ApiEndpoints.teacherMyAttendance,
        queryParameters: qp,
      );
      final raw = res.data ?? const [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<Map<String, dynamic>> saveAttendance({
    required int classroomId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.teacherMyAttendance,
        data: {'classroom_id': classroomId, 'date': date, 'records': records},
      );
      return Map<String, dynamic>.from(res.data ?? const {});
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<Map<String, dynamic>> saveGrades({
    required int assessmentId,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.teacherMyGrades,
        data: {'assessment_id': assessmentId, 'records': records},
      );
      return Map<String, dynamic>.from(res.data ?? const {});
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String type,
    required int classroomId,
    required String title,
    required String body,
    String? dueDate,
  }) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.teacherCreatePost,
        data: {
          'type': type,
          'classroom_id': classroomId,
          'title': title,
          'body': body,
          if (dueDate != null && dueDate.isNotEmpty) 'due_date': dueDate,
        },
      );
      return Map<String, dynamic>.from(res.data ?? const {});
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<List<Map<String, dynamic>>> getMyConversations() async {
    try {
      final res = await _client.get<List<dynamic>>(
        ApiEndpoints.teacherMyConversations,
      );
      final raw = res.data ?? const [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationMessages(
    int conversationId,
  ) async {
    try {
      final res = await _client.get<List<dynamic>>(
        ApiEndpoints.teacherConversationMessages(conversationId),
      );
      final raw = res.data ?? const [];
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    int conversationId,
    String body,
  ) async {
    try {
      final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.teacherSendMessage(conversationId),
        data: {'body': body},
      );
      return Map<String, dynamic>.from(res.data ?? const {});
    } on DioException catch (e) {
      throw e.error is AppException
          ? e.error as AppException
          : UnknownException(e.message ?? 'Erreur réseau');
    }
  }
}
