import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:hwl_vpn/services/device_info_service.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/services/secure_storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  final SecureStorageService _secureStorageService = SecureStorageService();
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final PreferencesService _prefsService = PreferencesService();

  http.Client? _client;

  Future<http.Client> _getClient() async {
    if (_client != null) {
      return _client!;
    }

    try {
      final SecurityContext context = SecurityContext(withTrustedRoots: true);
      try {
        final ByteData data = await rootBundle.load('assets/certificates/server.crt');
        context.setTrustedCertificatesBytes(data.buffer.asUint8List());
      } catch (e) {
        print("Error loading certificate: $e");
      }

      final HttpClient httpClient = HttpClient(context: context);
      _client = IOClient(httpClient);
    } catch (e) {
      print("Error initializing client: $e");
      _client = http.Client();
    }

    return _client!;
  }

  Future<String> _getBaseUrl() async {
    String url = await _prefsService.getServerUrl();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://' + url;
    }
    return url;
  }

  Future<Map<String, String>> _createHeaders({bool signed = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (signed) {
      final instanceId = await _secureStorageService.getOrCreateInstanceId();
      final clientSecret = await _secureStorageService.getClientSecret();
      final fingerprint = await _deviceInfoService.getFingerprint();
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

      if (clientSecret == null) {
        throw Exception("Client secret not found for signed request");
      }

      final payload = '$instanceId|$fingerprint|$timestamp';
      final hmacSha256 = Hmac(sha256, utf8.encode(clientSecret));
      final digest = hmacSha256.convert(utf8.encode(payload));
      final signature = digest.toString();

      headers['X-Instance-Id'] = instanceId;
      headers['X-Fingerprint'] = fingerprint;
      headers['X-Timestamp'] = timestamp;
      headers['X-Signature'] = signature;
    }
    return headers;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, {bool signed = false}) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _createHeaders(signed: signed);
    final client = await _getClient();
    final response = await client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    return response;
  }

  Future<http.Response> get(String endpoint, {bool signed = true}) async {
    final baseUrl = await _getBaseUrl();
    final headers = await _createHeaders(signed: signed);
    final uri = Uri.parse('$baseUrl$endpoint');
    final client = await _getClient();

    final response = await client.get(
      uri,
      headers: headers,
    ).timeout(const Duration(seconds: 10));
    return response;
  }
}
