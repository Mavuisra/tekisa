library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final box = Hive.box<Map>(StorageKeys.syncQueueBox);
  return SyncQueueService(box: box);
});

class SyncQueueService {
  SyncQueueService({required Box<Map> box}) : _box = box;

  final Box<Map> _box;
  final Uuid _uuid = const Uuid();

  Future<String> enqueueRequest(
    RequestOptions request, {
    String status = 'pending',
  }) async {
    final id = _uuid.v4();
    final item = <String, dynamic>{
      'id': id,
      'baseUrl': request.baseUrl,
      'path': request.path,
      'method': request.method.toUpperCase(),
      'queryParameters': _jsonSafeMap(request.queryParameters),
      'data': _jsonSafeValue(request.data),
      'headers': _jsonSafeMap(request.headers),
      'attempts': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'status': status,
    };
    await _box.put(id, item);
    return id;
  }

  List<Map<String, dynamic>> listPending() {
    return _box.values
        .map((raw) => Map<String, dynamic>.from(raw))
        .where((item) => item['status'] == 'pending')
        .toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['createdAt']?.toString() ?? '');
        return (aDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          bDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      });
  }

  Future<void> markSynced(String id) async {
    final current = _box.get(id);
    if (current == null) {
      return;
    }
    final updated = Map<String, dynamic>.from(current)
      ..['status'] = 'synced'
      ..['syncedAt'] = DateTime.now().toIso8601String();
    await _box.put(id, updated);
  }

  Future<void> markFailed(String id, Object error) async {
    final current = _box.get(id);
    if (current == null) {
      return;
    }
    final updated = Map<String, dynamic>.from(current)
      ..['status'] = 'failed'
      ..['error'] = error.toString()
      ..['attempts'] = ((updatedOrZero(current['attempts'])) + 1);
    await _box.put(id, updated);
  }

  Future<void> markPending(String id) async {
    final current = _box.get(id);
    if (current == null) {
      return;
    }
    final updated = Map<String, dynamic>.from(current)..['status'] = 'pending';
    await _box.put(id, updated);
  }

  Future<void> remove(String id) => _box.delete(id);

  String debugJson() {
    final pending = listPending();
    return const JsonEncoder.withIndent('  ').convert(pending);
  }

  int updatedOrZero(dynamic value) => value is int ? value : 0;

  Map<String, dynamic> _jsonSafeMap(Map<dynamic, dynamic>? source) {
    if (source == null) {
      return const <String, dynamic>{};
    }
    final result = <String, dynamic>{};
    for (final entry in source.entries) {
      result[entry.key.toString()] = _jsonSafeValue(entry.value);
    }
    return result;
  }

  dynamic _jsonSafeValue(dynamic value) {
    if (value == null || value is num || value is bool || value is String) {
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
