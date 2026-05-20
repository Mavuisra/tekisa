import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/env_config.dart';
import '../../core/network/dio_client.dart';
import 'auth_provider.dart';

final childrenProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authNotifierProvider);
  if (!auth.isAuthenticated || auth.accessToken == null) return [];
  final dio = ref.read(dioClientProvider).dio;
  dio.options.headers['X-School-ID'] = auth.schoolId;
  final res = await dio.get('${EnvConfig.apiBaseUrl}/parent/children/');
  final list = res.data as List<dynamic>? ?? [];
  return list.map((e) => e as Map<String, dynamic>).toList();
});
