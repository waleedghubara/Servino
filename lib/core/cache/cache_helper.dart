import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCacheHelper {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  //! Get Data as String
  Future<String?> getDataString({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  //! Save Data based on type (converted to String)
  Future<void> saveData({required String key, required dynamic value}) async {
    await _secureStorage.write(key: key, value: value.toString());
  }

  //! Get Data (always returns String)
  Future<String?> getData({required String key}) async {
    return await _secureStorage.read(key: key);
  }

  //! Remove Data
  Future<void> removeData({required String key}) async {
    await _secureStorage.delete(key: key);
  }

  //! Check if Key exists (if read returns null = doesn't exist)
  Future<bool> containsKey({required String key}) async {
    String? value = await _secureStorage.read(key: key);
    return value != null;
  }

  //! Clear All Data
  Future<void> clearData() async {
    await _secureStorage.deleteAll();
  }

  //! Put Data (alias for saveData)
  Future<void> put({required String key, required dynamic value}) async {
    await saveData(key: key, value: value);
  }
}
