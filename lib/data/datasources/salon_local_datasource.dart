library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/env_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/offline/local_sqlite.dart';
import '../../core/offline/sqlite_sync_queue_service.dart';
import 'local_auth_datasource.dart';
import '../models/salon_models.dart';

class SalonLocalDataSource {
  SalonLocalDataSource({
    LocalSqlite? sqlite,
    SqliteSyncQueueService? queueService,
  }) : _sqlite = sqlite ?? LocalSqlite.instance,
       _queueService = queueService ?? SqliteSyncQueueService(),
       _localAuth = LocalAuthDataSource(sqlite: sqlite ?? LocalSqlite.instance);

  final LocalSqlite _sqlite;
  final SqliteSyncQueueService _queueService;
  final LocalAuthDataSource _localAuth;
  final Uuid _uuid = const Uuid();

  int? _firstIntValue(
    List<Map<String, Object?>> rows, {
    String key = 'COUNT(*)',
  }) {
    if (rows.isEmpty) return null;
    final row = rows.first;
    final dynamic value =
        row[key] ?? (row.values.isNotEmpty ? row.values.first : null);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> ensureSeeded(String tenantId) async {
    final db = await _sqlite.database;
    await db.transaction((txn) async {
      // Suppression explicite des anciennes données de démonstration.
      await txn.delete(
        'salon_services',
        where: 'tenant_id = ? AND id IN (?, ?, ?, ?, ?, ?, ?, ?)',
        whereArgs: [
          tenantId,
          'svc_coupe_homme',
          'svc_tresse_simple',
          'svc_rasage',
          'svc_brushing',
          'svc_soin_capillaire',
          'svc_pose_vernis',
          'svc_pose_gel',
          'svc_makeup_jour',
        ],
      );
      await txn.delete(
        'salon_staff_users',
        where: 'tenant_id = ? AND id IN (?, ?, ?, ?)',
        whereArgs: [
          tenantId,
          'sty_joseph',
          'sty_diane',
          'sty_michel',
          'cash_sarah',
        ],
      );
    });
  }

  Future<List<SalonServiceModel>> getServices(String tenantId) async {
    final db = await _sqlite.database;
    final rows = await db.query(
      'salon_services',
      where: 'tenant_id = ? AND active = 1',
      whereArgs: [tenantId],
      orderBy: 'name ASC',
    );
    return rows
        .map(
          (row) => SalonServiceModel(
            id: row['id'] as String,
            code: row['code'] as String? ?? '',
            name: row['name'] as String,
            category: row['category'] as String? ?? 'coiffure',
            description: row['description'] as String? ?? '',
            imageUrl: row['image_url'] as String? ?? '',
            price: (row['price'] as num?)?.toDouble() ?? 0,
            durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 0,
            isPopular: (row['is_popular'] as num?)?.toInt() == 1,
            active: (row['active'] as num?)?.toInt() == 1,
          ),
        )
        .toList();
  }

  Future<List<SalonStylistModel>> getStylists(String tenantId) async {
    final db = await _sqlite.database;
    final rows = await db.query(
      'salon_staff_users',
      where: 'tenant_id = ? AND active = 1 AND role = ?',
      whereArgs: [tenantId, 'coiffeur'],
      orderBy: 'full_name ASC',
    );
    return rows
        .map(
          (row) => SalonStylistModel(
            id: row['id'] as String,
            fullName: row['full_name'] as String,
            active: (row['active'] as num?)?.toInt() == 1,
          ),
        )
        .toList();
  }

  Future<List<SalonStaffUserModel>> getStaffUsers(String tenantId) async {
    final db = await _sqlite.database;
    final rows = await db.query(
      'salon_staff_users',
      where: 'tenant_id = ? AND active = 1',
      whereArgs: [tenantId],
      orderBy: 'role ASC, full_name ASC',
    );
    return rows
        .map(
          (row) => SalonStaffUserModel(
            id: row['id'] as String,
            fullName: row['full_name'] as String? ?? '',
            username: row['username'] as String? ?? '',
            phone: row['phone'] as String? ?? '',
            role: row['role'] as String? ?? 'coiffeur',
            active: (row['active'] as num?)?.toInt() == 1,
          ),
        )
        .toList();
  }

  Future<SalonServiceModel> addService({
    required String tenantId,
    required String code,
    required String name,
    required String category,
    required String description,
    String imageUrl = '',
    required double price,
    required int durationMinutes,
    bool isPopular = false,
    bool active = true,
  }) async {
    final db = await _sqlite.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final payload = <String, dynamic>{
      'service_id': id,
      'code': code,
      'name': name,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'duration_minutes': durationMinutes,
      'is_popular': isPopular,
      'active': active,
    };
    await db.insert('salon_services', {
      'id': id,
      'tenant_id': tenantId,
      'code': code,
      'name': name,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'price': price,
      'duration_minutes': durationMinutes,
      'is_popular': isPopular ? 1 : 0,
      'active': active ? 1 : 0,
      'created_at': now,
    });
    await _queueService.enqueueRequest(
      tenantId: tenantId,
      request: RequestOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        path: ApiEndpoints.commerceSalonServices,
        method: 'POST',
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        data: payload,
      ),
    );
    return SalonServiceModel(
      id: id,
      code: code,
      name: name,
      category: category,
      description: description,
      imageUrl: imageUrl,
      price: price,
      durationMinutes: durationMinutes,
      isPopular: isPopular,
      active: active,
    );
  }

  Future<SalonStaffUserModel> createStaffUser({
    required String tenantId,
    required String fullName,
    required String username,
    required String phone,
    required String role,
    String pinCode = '',
    bool active = true,
  }) async {
    final db = await _sqlite.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final payload = <String, dynamic>{
      'staff_id': id,
      'full_name': fullName,
      'username': username,
      'phone': phone,
      'role': role,
      'pin_code': pinCode,
      'active': active,
    };
    await db.insert('salon_staff_users', {
      'id': id,
      'tenant_id': tenantId,
      'full_name': fullName,
      'username': username,
      'phone': phone,
      'role': role,
      'pin_code': pinCode,
      'active': active ? 1 : 0,
      'created_at': now,
    });
    await _queueService.enqueueRequest(
      tenantId: tenantId,
      request: RequestOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        path: ApiEndpoints.commerceSalonStaff,
        method: 'POST',
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        data: payload,
      ),
    );
    final effectivePassword = pinCode.trim().isEmpty ? '0000' : pinCode.trim();
    await _localAuth.createOrUpdateUser(
      username: username,
      password: effectivePassword,
      role: role,
      businessCategory: 'salon_coiffure',
      displayName: fullName,
      phone: phone,
    );
    return SalonStaffUserModel(
      id: id,
      fullName: fullName,
      username: username,
      phone: phone,
      role: role,
      active: active,
    );
  }

  Future<SalonSaleModel> recordSale({
    required String tenantId,
    required SalonServiceModel service,
    required SalonStylistModel stylist,
    required String paymentMethod,
    String clientName = '',
  }) async {
    final db = await _sqlite.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final saleId = _uuid.v4();
    final salePayload = <String, dynamic>{
      'sale_id': saleId,
      'service_id': service.id,
      'service_name': service.name,
      'stylist_id': stylist.id,
      'stylist_name': stylist.fullName,
      'client_name': clientName.trim(),
      'payment_method': paymentMethod,
      'amount': service.price,
      'started_at': now,
    };

    await db.insert('salon_sales', {
      'id': saleId,
      'tenant_id': tenantId,
      'service_id': service.id,
      'service_name': service.name,
      'stylist_id': stylist.id,
      'stylist_name': stylist.fullName,
      'client_name': clientName.trim(),
      'payment_method': paymentMethod,
      'amount': service.price,
      'started_at': now,
      'created_at': now,
      'payload_json': jsonEncode(salePayload),
    });

    await _queueService.enqueueRequest(
      tenantId: tenantId,
      request: RequestOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        path: ApiEndpoints.commerceSalonSales,
        method: 'POST',
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        data: salePayload,
      ),
    );

    return SalonSaleModel(
      id: saleId,
      serviceName: service.name,
      stylistName: stylist.fullName,
      clientName: clientName.trim(),
      paymentMethod: paymentMethod,
      amount: service.price,
      createdAtMs: now,
    );
  }

  Future<List<SalonSaleModel>> listRecentSales(
    String tenantId, {
    int limit = 10,
  }) async {
    final db = await _sqlite.database;
    final rows = await db.query(
      'salon_sales',
      where: 'tenant_id = ?',
      whereArgs: [tenantId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows
        .map(
          (row) => SalonSaleModel(
            id: row['id'] as String,
            serviceName: row['service_name'] as String? ?? '',
            stylistName: row['stylist_name'] as String? ?? '',
            clientName: row['client_name'] as String? ?? '',
            paymentMethod: row['payment_method'] as String? ?? 'cash',
            amount: (row['amount'] as num?)?.toDouble() ?? 0,
            createdAtMs: (row['created_at'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  Future<SalonTodayStats> getTodayStats(String tenantId) async {
    final db = await _sqlite.database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;

    final summaryRows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS sales_count,
        COALESCE(SUM(amount), 0) AS total_revenue
      FROM salon_sales
      WHERE tenant_id = ? AND created_at BETWEEN ? AND ?
      ''',
      [tenantId, start, end],
    );
    final salesCount = _firstIntValue(summaryRows, key: 'sales_count') ?? 0;
    final totalRevenue =
        (summaryRows.first['total_revenue'] as num?)?.toDouble() ?? 0;

    final topRows = await db.rawQuery(
      '''
      SELECT stylist_name, COALESCE(SUM(amount), 0) AS stylist_revenue
      FROM salon_sales
      WHERE tenant_id = ? AND created_at BETWEEN ? AND ?
      GROUP BY stylist_name
      ORDER BY stylist_revenue DESC
      LIMIT 1
      ''',
      [tenantId, start, end],
    );

    final topStylist = topRows.isEmpty
        ? '—'
        : (topRows.first['stylist_name'] as String? ?? '—');
    final topRevenue = topRows.isEmpty
        ? 0.0
        : (topRows.first['stylist_revenue'] as num?)?.toDouble() ?? 0;

    return SalonTodayStats(
      totalRevenue: totalRevenue,
      totalSales: salesCount,
      averageTicket: salesCount == 0 ? 0 : (totalRevenue / salesCount),
      topStylist: topStylist,
      topStylistRevenue: topRevenue,
    );
  }
}
