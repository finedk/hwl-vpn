import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  static const _instanceIdKey = 'instance_id';
  static const _clientSecretKey = 'client_secret';

  Future<String> getOrCreateInstanceId() async {
    String? instanceId = await _storage.read(key: _instanceIdKey);
    if (instanceId == null) {
      instanceId = _uuid.v4();
      await _storage.write(key: _instanceIdKey, value: instanceId);
    }
    return instanceId;
  }

  Future<String?> getInstanceId() async {
    return await _storage.read(key: _instanceIdKey);
  }

  Future<String?> getClientSecret() async {
    return await _storage.read(key: _clientSecretKey);
  }

  Future<void> saveClientSecret(String secret) async {
    await _storage.write(key: _clientSecretKey, value: secret);
  }

  Future<void> deleteClientSecret() async {
    await _storage.delete(key: _clientSecretKey);
  }

  Future<void> deleteInstanceId() async {
    await _storage.delete(key: _instanceIdKey);
  }

  static const _countriesWithServersKey = 'countries_with_servers';

  Future<void> saveCountriesWithServers(String jsonString) async {
    await _storage.write(key: _countriesWithServersKey, value: jsonString);
  }

  Future<String?> getSavedCountriesWithServers() async {
    return await _storage.read(key: _countriesWithServersKey);
  }
}