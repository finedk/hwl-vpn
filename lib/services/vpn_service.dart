import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/services/secure_storage_service.dart';
import 'package:hwl_vpn/utils/config_generator.dart';

class VpnService {
  VpnService._privateConstructor();
  static final VpnService _instance = VpnService._privateConstructor();
  factory VpnService() {
    return _instance;
  }

  static const platform = MethodChannel('com.hwl_vpn.app/channel');
  static const _iosChannel = MethodChannel('com.hwl.hwl-vpn/control');
  final _prefsService = PreferencesService();
  final _secureStorage = SecureStorageService();
  final _configGenerator = ConfigGenerator();

  Future<String?> startVpn({String? customVlessLink}) async {
    try {
      final settings = {
        'vless_link': '', // This is now handled by the customVlessLink parameter
        'dns_provider': (await _prefsService.getDnsProvider()).name,
        'use_mixed_inbound': await _prefsService.getMixedInboundEnabled(),
        'mixed_inbound_listen_address': '0.0.0.0',
        'mixed_inbound_listen_port': await _prefsService.getMixedInboundPort(),
        'per_app_proxy_enabled':
            (await _prefsService.getPerAppProxyMode()) != 'disabled',
        'per_app_proxy_mode': await _prefsService.getPerAppProxyMode(),
        'per_app_proxy_list': await _prefsService.getSelectedApps(),
        'excluded_domains': await _prefsService.getExcludedDomains(),
        'excluded_domain_suffixes':
            await _prefsService.getExcludedDomainSuffixes(),
        'enable_logging': await _prefsService.getEnableLogging(),
      };

      final config = _configGenerator.generateSingboxConfigJson(settings,
          customVlessLink: customVlessLink);
      final disableMemoryLimit = await _prefsService.getDisableMemoryLimit();

      if (Platform.isIOS) {
        return await _iosChannel.invokeMethod('connect', {
          'config': config,
          'disableMemoryLimit': disableMemoryLimit,
        });
      } else {
        final dnsProviderName = (await _prefsService.getDnsProvider()).name;
        final dnsServer = dnsProviderName == 'cloudflare'
            ? '1.1.1.1'
            : (dnsProviderName == 'adguard' ? '94.140.14.14' : '8.8.8.8');
        final persistentNotification =
            await _prefsService.getPersistentNotification();
        final hideSingboxConsole = await _prefsService.getHideSingboxConsole();

        await platform.invokeMethod('startService', {
          'config': config,
          'dns': dnsServer,
          'disableMemoryLimit': disableMemoryLimit,
          'perAppProxyEnabled': settings['per_app_proxy_enabled'],
          'perAppProxyMode': settings['per_app_proxy_mode'],
          'perAppProxyList': settings['per_app_proxy_list'],
          'persistentNotification': persistentNotification,
          'hideSingboxConsole': hideSingboxConsole,
        });
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to start service: '${e.message}'.");
      }
      return e.message;
    }
    return null;
  }

  Future<String?> stopVpn() async {
    try {
      if (Platform.isIOS) {
        return await _iosChannel.invokeMethod('disconnect');
      } else if (Platform.isMacOS) {
        return await platform.invokeMethod('disconnect');
      } else {
        await platform.invokeMethod('stopService');
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to stop service: '${e.message}'.");
      }
      return e.message;
    }
    return null;
  }

  Future<void> setPersistentNotification(bool enabled) async {
    if (Platform.isIOS) {
      return; // This is not applicable to iOS in the current implementation
    }
    try {
      await platform
          .invokeMethod('setPersistentNotification', {'enabled': enabled});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to set persistent notification: '${e.message}'.");
      }
    }
  }

  static Future<void> saveCacheTimestamp(int timestamp) async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return;
    }
    try {
      if (Platform.isIOS) {
        await _iosChannel.invokeMethod('saveCacheTimestamp', {'timestamp': timestamp});
      } else if (Platform.isMacOS) {
        await platform.invokeMethod('saveCacheTimestamp', {'timestamp': timestamp});
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to save cache timestamp: '${e.message}'.");
      }
    }
  }
}