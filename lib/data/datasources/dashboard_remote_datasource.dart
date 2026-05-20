/// Appel API dashboard parent (enfants + stats)
library;

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/dashboard_model.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);

  final DioClient _client;

  /// GET /users/dashboard/ → DashboardModel
  Future<DashboardModel> getDashboard() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.dashboard,
    );
    final data = response.data;
    if (data == null) throw UnknownException('Réponse vide');
    return DashboardModel.fromJson(data);
  }
}
