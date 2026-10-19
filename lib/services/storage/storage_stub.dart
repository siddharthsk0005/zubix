// Stub implementation for non-web platforms
class PlatformStorage {
  static final Map<String, String> _memoryStorage = {};

  static String? getItem(String key) {
    return _memoryStorage[key];
  }

  static void setItem(String key, String value) {
    _memoryStorage[key] = value;
  }

  static void removeItem(String key) {
    _memoryStorage.remove(key);
  }
}
