import 'package:hive_flutter/hive_flutter.dart';

class LocalDB {
  static const String boxName = 'parent_app_cache';
  static Box<String>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  static Box<String> get box {
    if (_box == null) throw StateError('Call LocalDB.init() first');
    return _box!;
  }

  static Future<void> set(String key, String value) => box.put(key, value);
  static String? get(String key) => box.get(key);
  static Future<void> remove(String key) => box.delete(key);
  static Future<void> clear() => box.clear();
}
