library;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class LocalSqlite {
  LocalSqlite._();

  static final LocalSqlite instance = LocalSqlite._();
  Database? _db;
  bool _factoryConfigured = false;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _open();
    return _db!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _open() async {
    _configureFactoryForPlatform();
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'cisnetkids_offline.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createAllTables(db);
      },
      onOpen: (db) async {
        // Migration defensive: certains appareils gardent une DB déjà en v6
        // sans relancer onUpgrade. On garantit ici les nouvelles colonnes.
        await _createAllTables(db);
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_cache (
        tenant_id TEXT NOT NULL,
        resource_key TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (tenant_id, resource_key)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        base_url TEXT NOT NULL,
        path TEXT NOT NULL,
        method TEXT NOT NULL,
        headers_json TEXT NOT NULL,
        query_json TEXT NOT NULL,
        body_json TEXT,
        created_at INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_tenant_created ON sync_queue(tenant_id, created_at)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS restaurant_orders (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        order_number TEXT NOT NULL,
        service_type TEXT NOT NULL,
        table_ref TEXT,
        status TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payload_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pharmacy_prescriptions (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        patient_name TEXT NOT NULL,
        prescription_ref TEXT,
        doctor_name TEXT,
        total_amount REAL NOT NULL,
        payload_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS boutique_sales (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        sale_ref TEXT NOT NULL,
        customer_name TEXT,
        payment_method TEXT NOT NULL,
        total_amount REAL NOT NULL,
        payload_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS salon_appointments (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        client_name TEXT NOT NULL,
        stylist_name TEXT,
        start_at TEXT NOT NULL,
        status TEXT NOT NULL,
        estimated_total REAL,
        payload_json TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_restaurant_orders_tenant ON restaurant_orders(tenant_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pharmacy_prescriptions_tenant ON pharmacy_prescriptions(tenant_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_boutique_sales_tenant ON boutique_sales(tenant_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_salon_appointments_tenant ON salon_appointments(tenant_id, created_at)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS salon_services (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        code TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'coiffure',
        description TEXT NOT NULL DEFAULT '',
        image_url TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL,
        duration_minutes INTEGER NOT NULL,
        is_popular INTEGER NOT NULL DEFAULT 0,
        active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
    await _ensureColumnExists(
      db,
      tableName: 'salon_services',
      columnName: 'code',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumnExists(
      db,
      tableName: 'salon_services',
      columnName: 'category',
      definition: "TEXT NOT NULL DEFAULT 'coiffure'",
    );
    await _ensureColumnExists(
      db,
      tableName: 'salon_services',
      columnName: 'description',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumnExists(
      db,
      tableName: 'salon_services',
      columnName: 'image_url',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumnExists(
      db,
      tableName: 'salon_services',
      columnName: 'is_popular',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS salon_staff_users (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        username TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL,
        pin_code TEXT NOT NULL DEFAULT '',
        active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_auth_users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        business_category TEXT NOT NULL DEFAULT 'boutique',
        company_name TEXT NOT NULL DEFAULT '',
        display_name TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS salon_sales (
        id TEXT PRIMARY KEY,
        tenant_id TEXT NOT NULL,
        service_id TEXT NOT NULL,
        service_name TEXT NOT NULL,
        stylist_id TEXT NOT NULL,
        stylist_name TEXT NOT NULL,
        client_name TEXT,
        payment_method TEXT NOT NULL,
        amount REAL NOT NULL,
        started_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        payload_json TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_salon_services_tenant ON salon_services(tenant_id, active)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_salon_staff_tenant ON salon_staff_users(tenant_id, role, active)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_salon_sales_tenant_created ON salon_sales(tenant_id, created_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_local_auth_username ON local_auth_users(username, active)',
    );
    await _ensureColumnExists(
      db,
      tableName: 'local_auth_users',
      columnName: 'company_name',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumnExists(
      db,
      tableName: 'local_auth_users',
      columnName: 'profile_json',
      definition: "TEXT NOT NULL DEFAULT '{}'",
    );
  }

  Future<void> _ensureColumnExists(
    Database db, {
    required String tableName,
    required String columnName,
    required String definition,
  }) async {
    final info = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = info.any((row) => row['name']?.toString() == columnName);
    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $definition',
      );
    }
  }

  void _configureFactoryForPlatform() {
    if (_factoryConfigured) {
      return;
    }
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      _factoryConfigured = true;
      return;
    }

    final platform = defaultTargetPlatform;
    final isDesktop =
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
    if (isDesktop) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _factoryConfigured = true;
  }
}
