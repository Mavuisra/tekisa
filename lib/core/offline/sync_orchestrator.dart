library;

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'sqlite_sync_queue_service.dart';
import 'tenant_context.dart';

/// Orchestrateur global de synchronisation des écritures offline.
class SyncOrchestrator {
  SyncOrchestrator._();

  static final SyncOrchestrator instance = SyncOrchestrator._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isRunning = false;
  bool _isSyncing = false;
  final SqliteSyncQueueService _queueService = SqliteSyncQueueService();

  Future<void> start() async {
    if (_isRunning) {
      return;
    }
    _isRunning = true;

    final initial = await _connectivity.checkConnectivity();
    if (_hasConnection(initial)) {
      unawaited(flushQueue());
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      if (_hasConnection(results)) {
        unawaited(flushQueue());
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _isRunning = false;
  }

  Future<void> flushQueue() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;

    try {
      final tenant = TenantContext.current();
      if (tenant == null) {
        return;
      }
      final pending = await _queueService.listPendingByTenant(tenant.tenantId);
      if (pending.isEmpty) {
        return;
      }

      for (final item in pending) {
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) {
          continue;
        }

        final method = item['method']?.toString() ?? 'POST';
        final path = item['path']?.toString() ?? '';
        final baseUrl = item['base_url']?.toString() ?? '';
        final headers = _decodeMap(item['headers_json']);
        final query = _decodeMap(item['query_json']);
        final data = _decodeJson(item['body_json']);

        if (path.isEmpty || baseUrl.isEmpty) {
          await _queueService.markFailed(
            id,
            'Requete invalide: path/baseUrl manquant.',
          );
          continue;
        }

        try {
          final dio = Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
              sendTimeout: ApiConstants.sendTimeout,
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                ...headers,
              },
            ),
          );
          await dio.request<dynamic>(
            path,
            data: data,
            queryParameters: query.isEmpty ? null : query,
            options: Options(method: method),
          );
          await _queueService.remove(id);
        } on DioException catch (e) {
          if (_isTemporaryNetworkError(e)) {
            // On stoppe la boucle et on retentera au prochain retour réseau.
            break;
          }
          await _queueService.markFailed(
            id,
            e.message ?? 'Echec de synchronisation',
          );
        } catch (e) {
          await _queueService.markFailed(id, e);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  bool _isTemporaryNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }

  Map<String, dynamic> _decodeMap(dynamic raw) {
    if (raw is! String || raw.isEmpty) {
      return const <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return const <String, dynamic>{};
  }

  dynamic _decodeJson(dynamic raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return jsonDecode(raw);
  }
}
