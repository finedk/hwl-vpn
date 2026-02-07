import 'dart:typed_data';

class IconCache {
  // Singleton pattern
  static final IconCache _instance = IconCache._internal();
  factory IconCache() {
    return _instance;
  }
  IconCache._internal();

  final Map<String, Uint8List> _cache = {};

  Uint8List? get(String packageName) {
    return _cache[packageName];
  }

  void set(String packageName, Uint8List iconData) {
    _cache[packageName] = iconData;
  }

  bool has(String packageName) {
    return _cache.containsKey(packageName);
  }
}