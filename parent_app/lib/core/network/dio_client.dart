import 'package:dio/dio.dart';
import '../config/env_config.dart';

class DioClient {
  DioClient({
    required this.baseUrl,
    String? accessToken,
    void Function(String)? onTokenRefreshed,
  })  : _onTokenRefreshed = onTokenRefreshed,
        _token = accessToken,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: EnvConfig.connectTimeout),
          receiveTimeout: const Duration(seconds: EnvConfig.receiveTimeout),
          headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        )) {
    if (accessToken != null && accessToken.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
    ));
  }

  final String baseUrl;
  final void Function(String)? _onTokenRefreshed;
  final Dio _dio;
  String? _token;

  void setToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Dio get dio => _dio;
}
