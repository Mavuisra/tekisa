library;

import '../../core/constants/app_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/attendance_model.dart';
import '../models/conversation_model.dart';
import '../models/grades_model.dart';
import '../models/invoice_model.dart';
import '../models/learning_suggestion_model.dart';
import '../models/notification_model.dart';

class ParentDataRemoteDataSource {
  ParentDataRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<TermResultModel>> getMyTermResults() async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.myTermResults,
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map(
          (e) => TermResultModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<GradeModel>> getMyGrades() async {
    final response = await _client.get<List<dynamic>>(ApiEndpoints.myGrades);
    final data = response.data;
    if (data == null) return [];
    return data
        .map((e) => GradeModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<AttendanceRecordModel>> getMyAttendance({String? month}) async {
    final path = month != null
        ? '${ApiEndpoints.myAttendance}?month=$month'
        : ApiEndpoints.myAttendance;
    final response = await _client.get<List<dynamic>>(path);
    final data = response.data;
    if (data == null) return [];
    return data
        .map(
          (e) => AttendanceRecordModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<InvoiceModel>> getMyInvoices() async {
    final response = await _client.get<List<dynamic>>(ApiEndpoints.myInvoices);
    final data = response.data;
    if (data == null) return [];
    return data
        .map((e) => InvoiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<LearningSuggestionsResponse>> getLearningSuggestions() async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.myLearningSuggestions,
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map(
          (e) => LearningSuggestionsResponse.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<List<NotificationModel>> getMyNotifications() async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.myNotifications,
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map(
          (e) =>
              NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<ConversationModel>> getMyConversations() async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.myConversations,
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map(
          (e) =>
              ConversationModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<ConversationMessageModel>> getConversationMessages(
    int conversationId,
  ) async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.myConversationMessages(conversationId),
    );
    final data = response.data;
    if (data == null) return [];
    return data
        .map(
          (e) => ConversationMessageModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }
}
