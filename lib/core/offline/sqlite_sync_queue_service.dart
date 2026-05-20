library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'local_sqlite.dart';

class SqliteSyncQueueService {
  final Uuid _uuid = const Uuid();

  Future<String> enqueueRequest({
    required String tenantId,
    required RequestOptions request,
  }) async {
    final db = await LocalSqlite.instance.database;
    final id = _uuid.v4();
    await db.insert('sync_queue', {
      'id': id,
      'tenant_id': tenantId,
      'base_url': request.baseUrl,
      'path': request.path,
      'method': request.method.toUpperCase(),
      'headers_json': jsonEncode(_jsonSafeMap(request.headers)),
      'query_json': jsonEncode(_jsonSafeMap(request.queryParameters)),
      'body_json': request.data == null
          ? null
          : jsonEncode(_jsonSafeValue(request.data)),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
      'last_error': null,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> listPendingByTenant(
    String tenantId,
  ) async {
    final db = await LocalSqlite.instance.database;
    final rows = await db.query(
      'sync_queue',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
      orderBy: 'created_at ASC',
    );
    return rows.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> remove(String id) async {
    final db = await LocalSqlite.instance.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markFailed(String id, Object error) async {
    final db = await LocalSqlite.instance.database;
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [error.toString(), id],
    );
  }

  Map<String, dynamic> _jsonSafeMap(Map<dynamic, dynamic>? source) {
    if (source == null) return const <String, dynamic>{};
    final result = <String, dynamic>{};
    for (final entry in source.entries) {
      result[entry.key.toString()] = _jsonSafeValue(entry.value);
    }
    return result;
  }

  dynamic _jsonSafeValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is List) {
      return value.map(_jsonSafeValue).toList();
    }
    if (value is Map) {
      return _jsonSafeMap(Map<dynamic, dynamic>.from(value));
    }
    return value.toString();
  }
}
