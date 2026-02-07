import 'dart:convert';
import 'package:hwl_vpn/api/api_client.dart';
import 'package:hwl_vpn/services/device_info_service.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/services/secure_storage_service.dart';

class ApiService {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  Future<Map<String, dynamic>> registerInstance(String accountCode, [String? customDeviceName]) async {
    try {
      final instanceId = await _secureStorageService.getOrCreateInstanceId();
      final deviceName = (customDeviceName != null && customDeviceName.isNotEmpty)
          ? customDeviceName
          : await _deviceInfoService.getDeviceName();
      final fingerprint = await _deviceInfoService.getFingerprint();
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final signature = '';

      final response = await _apiClient.post('/register_instance', {
        'account_code': accountCode,
        'instance_id': instanceId,
        'fingerprint': fingerprint,
        'signature': signature,
        'device_name': deviceName,
        'timestamp': timestamp,
      }, signed: false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiKey = data['api_key'];
        if (apiKey != null) {
          await _secureStorageService.saveClientSecret(apiKey);
          return {'success': true};
        }
        return {'success': false, 'message': 'API key was null'};
      } else {
        String errorMessage = 'Request failed with status: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['detail'] != null) {
            errorMessage = errorBody['detail'];
          }
        } catch (e) {
          // Body is not JSON or doesn't contain detail. Use default message.
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> registerGuestInstance() async {
    try {
      final instanceId = await _secureStorageService.getOrCreateInstanceId();
      final deviceName = await _deviceInfoService.getDeviceName();
      final fingerprint = await _deviceInfoService.getFingerprint();

      final response = await _apiClient.post('/guest/register_guest_instance', {
        'instance_id': instanceId,
        'fingerprint': fingerprint,
        'device_name': deviceName,
      }, signed: false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientSecret = data['client_secret'];
        if (clientSecret != null) {
          await _secureStorageService.saveClientSecret(clientSecret);
          return {'success': true};
        }
        return {'success': false, 'message': 'Client secret was null'};
      } else {
        String errorMessage = 'Request failed with status: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['detail'] != null) {
            errorMessage = errorBody['detail'];
          }
        } catch (e) {
          // Body is not JSON or doesn't contain detail. Use default message.
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> performUnlink() async {
    final clientSecret = await _secureStorageService.getClientSecret();
    if (clientSecret != null) {
      try {
        await _apiClient.post('/unregister_device', {}, signed: true);
      } catch (e) {
        print('Failed to send unregister request to server, proceeding with local deletion: $e');
      }
    }
    await _secureStorageService.deleteClientSecret();
    await _secureStorageService.deleteInstanceId();
  }

  Future<void> resetDevice() async {
    await performUnlink();
    await _secureStorageService.deleteInstanceId();
  }

  Future<Map<String, dynamic>> getDeviceStatus() async {
    final prefs = PreferencesService();
    final useFree = await prefs.getUseFreeServers();
    final endpoint = useFree ? '/guest/status' : '/status';
    try {
      final response = await _apiClient.post(endpoint, {}, signed: true);
      if (response.statusCode == 200) {
        try {
          return {'success': true, ...jsonDecode(response.body)};
        } catch (e) {
          print('Error decoding status JSON: $e');
          return {'success': false, 'error': 'json'};
        }
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return {'success': false, 'error': 'auth'};
      }
      return {'success': false, 'error': 'server'};
    } catch (e) {
      print('Error getting device status: $e');
      return {'success': false, 'error': 'network'};
    }
  }

  Future<List<dynamic>?> getCountriesWithServers() async {
    final prefs = PreferencesService();
    final useFree = await prefs.getUseFreeServers();
    final endpoint = useFree ? '/guest/countries_with_servers' : '/countries_with_servers';
    try {
      final response = await _apiClient.get(endpoint);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting countries with servers: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateDeviceName(String newName) async {
    try {
      final response = await _apiClient.post('/update_device_name', {'new_device_name': newName}, signed: true);
      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        String errorMessage = 'Request failed with status: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody['detail'] != null) {
            errorMessage = errorBody['detail'];
          }
        } catch (e) {
          // Body is not JSON or doesn't contain detail. Use default message.
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
