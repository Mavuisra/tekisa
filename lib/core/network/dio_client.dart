/// Client HTTP Dio configuré (interceptors, base URL, timeouts)
library;

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/app_constants.dart';
import '../errors/app_exceptions.dart';
import '../offline/sqlite_sync_queue_service.dart';
import '../offline/tenant_context.dart';

/// Fournit une instance Dio configurée pour l'API CisnetKids
class DioClient {
  DioClient({
    required this.baseUrl,
    String? accessToken,
    Future<String?> Function()? getRefreshToken,
    Future<void> Function(String)? saveAccessToken,
  }) : _accessToken = accessToken {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      _AuthInterceptor(() => _accessToken),
      _OfflineQueueInterceptor(SqliteSyncQueueService()),
      if (getRefreshToken != null && saveAccessToken != null)
        _RefreshInterceptor(
          _dio,
          getRefreshToken,
          saveAccessToken,
          (t) => _accessToken = t,
        ),
      _ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    ]);
  }

  final String baseUrl;
  String? _accessToken;
  late final Dio _dio;

  Dio get dio => _dio;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  bool get hasRemoteAuthToken {
    final token = _accessToken;
    if (token == null || token.isEmpty) return false;
    return !_isLocalOfflineToken(token);
  }

  /// GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      _rethrowAppExceptionIfAny(e);
    }
  }

  /// POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withQueueOptions(options, queueIfOffline: queueIfOffline),
      );
    } on DioException catch (e) {
      _rethrowAppExceptionIfAny(e);
    }
  }

  /// PUT
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
    bool queueIfOffline = true,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        options: _withQueueOptions(options, queueIfOffline: queueIfOffline),
      );
    } on DioException catch (e) {
      _rethrowAppExceptionIfAny(e);
    }
  }

  /// DELETE
  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
    bool queueIfOffline = true,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        options: _withQueueOptions(options, queueIfOffline: queueIfOffline),
      );
    } on DioException catch (e) {
      _rethrowAppExceptionIfAny(e);
    }
  }

  Options _withQueueOptions(Options? options, {required bool queueIfOffline}) {
    final mergedExtra = <String, dynamic>{
      ...(options?.extra ?? const <String, dynamic>{}),
      'queueIfOffline': queueIfOffline,
    };
    if (options == null) {
      return Options(extra: mergedExtra);
    }
    return options.copyWith(extra: mergedExtra);
  }

  Never _rethrowAppExceptionIfAny(DioException exception) {
    final error = exception.error;
    if (error is AppException) {
      throw error;
    }
    final type = exception.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.badCertificate) {
      throw NetworkException(
        message:
            'Connexion impossible au serveur. Verifiez internet ou continuez en mode hors ligne.',
        statusCode: exception.response?.statusCode,
      );
    }
    final statusCode = exception.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      throw AuthException(
        message: 'Session invalide ou expirée. Reconnectez-vous.',
        code: '$statusCode',
      );
    }
    if (statusCode != null && statusCode >= 500) {
      throw ServerException(
        message: 'Serveur indisponible. Réessayez dans un instant.',
        statusCode: statusCode,
      );
    }
    throw UnknownException(
      'Erreur de connexion inattendue. Veuillez réessayer.',
    );
  }
}

/// Intercepteur : ajout du token Bearer (lecture à jour via getter)
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._getToken);

  final String? Function() _getToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _getToken();
    if (token != null && token.isNotEmpty && !_isLocalOfflineToken(token)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Si hors ligne, stocke les requêtes d'écriture dans une file locale.
class _OfflineQueueInterceptor extends Interceptor {
  _OfflineQueueInterceptor(this._service);

  final SqliteSyncQueueService _service;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_shouldQueue(options)) {
      handler.next(options);
      return;
    }
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        handler.next(options);
        return;
      }
      final tenant = TenantContext.current();
      if (tenant == null) {
        handler.next(options);
        return;
      }
      await _service.enqueueRequest(
        tenantId: tenant.tenantId,
        request: options,
      );
      options.extra['queued_offline'] = true;
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: QueuedForSyncException(),
        ),
      );
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: UnknownException('Echec de mise en file offline: $e'),
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (!_shouldQueue(options)) {
      handler.next(err);
      return;
    }

    // Déjà traité en mode offline lors de onRequest.
    if (options.extra['queued_offline'] == true ||
        err.error is QueuedForSyncException) {
      handler.next(err);
      return;
    }

    // Cas courant sur mobile: internet actif mais DNS/host lookup KO.
    // IMPORTANT: si un transport réseau est actif (Wi-Fi, mobile, ethernet),
    // on ne doit pas classer cette erreur comme "offline".
    final canFallbackToQueue =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;
    if (!canFallbackToQueue) {
      handler.next(err);
      return;
    }

    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasTransport = connectivity.any(
        (r) => r != ConnectivityResult.none,
      );
      if (hasTransport) {
        // Wi-Fi/mobile détecté -> garder l'erreur réseau normale,
        // ne pas basculer en file offline.
        handler.next(err);
        return;
      }
      final tenant = TenantContext.current();
      if (tenant == null) {
        handler.next(err);
        return;
      }
      await _service.enqueueRequest(
        tenantId: tenant.tenantId,
        request: options,
      );
      options.extra['queued_offline'] = true;
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: QueuedForSyncException(),
        ),
      );
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldQueue(RequestOptions options) {
    final method = options.method.toUpperCase();
    const mutatingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};
    if (!mutatingMethods.contains(method)) {
      return false;
    }
    if (options.extra['skipOfflineQueue'] == true) {
      return false;
    }
    final path = options.path.toLowerCase();
    if (path.contains('login') ||
        path.contains('register') ||
        path.contains('refresh')) {
      return false;
    }
    final queueIfOffline = options.extra['queueIfOffline'];
    return queueIfOffline != false;
  }
}

/// En cas de 401, tente un refresh JWT puis réessaie la requête une fois.
class _RefreshInterceptor extends Interceptor {
  _RefreshInterceptor(
    this._dio,
    this._getRefreshToken,
    this._saveAccessToken,
    this._setAccessToken,
  );

  final Dio _dio;
  final Future<String?> Function() _getRefreshToken;
  final Future<void> Function(String) _saveAccessToken;
  final void Function(String?) _setAccessToken;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    final path = err.requestOptions.path;
    if (path.contains('refresh') || path.contains('login')) {
      handler.next(err);
      return;
    }
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null ||
        refreshToken.isEmpty ||
        _isLocalOfflineToken(refreshToken)) {
      handler.next(err);
      return;
    }
    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refresh': refreshToken},
      );
      final access = resp.data?['access'] as String?;
      if (access == null || access.isEmpty) {
        handler.next(err);
        return;
      }
      await _saveAccessToken(access);
      _setAccessToken(access);
      final opts = err.requestOptions;
      final retry = await _dio.fetch(
        opts..headers['Authorization'] = 'Bearer $access',
      );
      handler.resolve(retry);
    } catch (_) {
      handler.next(err);
    }
  }
}

bool _isLocalOfflineToken(String token) {
  final value = token.trim().toLowerCase();
  return value.startsWith('local_offline_');
}

/// Intercepteur : mapping des erreurs Dio vers AppException
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appException,
        response: err.response,
        type: err.type,
      ),
    );
  }

  AppException _mapDioError(DioException err) {
    if (err.error is AppException) {
      return err.error as AppException;
    }
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    String message = err.message ?? 'Erreur réseau';

    if (data is Map) {
      final detail = data['detail'] ?? data['message'];
      if (detail != null && detail is String) message = detail;
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        final rawMessage = (err.message ?? '').toLowerCase();
        if (rawMessage.contains('xmlhttprequest onerror')) {
          return NetworkException(
            message:
                'Erreur réseau navigateur (XHR). Vérifiez que le backend Django tourne sur le port 8000, que l\'URL API est correcte, et que CORS est activé en debug.',
            statusCode: statusCode,
          );
        }
        return NetworkException(
          message: message.isEmpty || message == 'Erreur réseau'
              ? 'Impossible de joindre le backend. Vérifiez que Django tourne (python manage.py runserver 0.0.0.0:8000) et que l\'app utilise une URL API valide (localhost/IP), pas 0.0.0.0.'
              : message,
          statusCode: statusCode,
        );
      default:
        break;
    }

    if (statusCode != null) {
      if (statusCode == 404) {
        return UnknownException(
          'Backend introuvable (404). Vérifiez que c\'est bien Django qui tourne sur le port 8000 et que l\'URL de l\'app pointe vers ce serveur.',
        );
      }
      if (statusCode == 401 || statusCode == 403) {
        return AuthException(message: message, code: statusCode.toString());
      }
      if (statusCode >= 500) {
        return ServerException(message: message, statusCode: statusCode);
      }
      if (statusCode == 422) {
        return ValidationException(
          message: message,
          errors: data is Map ? _parseErrors(data['errors']) : null,
        );
      }
    }

    return UnknownException(message);
  }

  Map<String, List<String>>? _parseErrors(dynamic errors) {
    if (errors is! Map) return null;
    final result = <String, List<String>>{};
    for (final e in errors.entries) {
      if (e.value is List) {
        result[e.key.toString()] = (e.value as List)
            .map((x) => x.toString())
            .toList();
      }
    }
    return result.isEmpty ? null : result;
  }
}
