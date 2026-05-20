library;

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'local_sqlite.dart';

class SqliteCacheService {
  Future<void> save({
    required String tenantId,
    required String resourceKey,
    required Object payload,
  }) async {
    final db = await LocalSqlite.instance.database;
    await db.insert('local_cache', {
      'tenant_id': tenantId,
      'resource_key': resourceKey,
      'payload_json': jsonEncode(payload),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<dynamic> read({
    required String tenantId,
    required String resourceKey,
  }) async {
    final db = await LocalSqlite.instance.database;
    final rows = await db.query(
      'local_cache',
      where: 'tenant_id = ? AND resource_key = ?',
      whereArgs: [tenantId, resourceKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final raw = rows.first['payload_json'] as String?;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return jsonDecode(raw);
  }
}
