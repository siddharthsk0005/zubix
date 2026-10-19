import 'storage_stub.dart'
    if (dart.library.html) 'storage_web.dart';

class LocalStorageService {
  static String? getString(String key) => PlatformStorage.getItem(key);

  static void setString(String key, String value) => PlatformStorage.setItem(key, value);

  static void remove(String key) => PlatformStorage.removeItem(key);
}
