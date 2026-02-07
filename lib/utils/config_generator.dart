import 'dart:convert';
import 'dart:io';

class ConfigGenerator {
  String generateSingboxConfigJson(Map<String, dynamic> settings, {String? customVlessLink}) {
    final link = (customVlessLink ?? settings['vless_link'] as String).replaceAll(' ', '');
    final uri = Uri.parse(link);

    final Map<String, dynamic> outbound;
    if (uri.scheme == 'vless') {
      outbound = {
        "type": "vless",
        "tag": "proxy",
        "server": uri.host,
        "server_port": uri.port,
        "uuid": uri.userInfo,
        "flow": uri.queryParameters['flow'],
        "tls": {
          "enabled": uri.queryParameters['security'] == 'reality',
          "server_name": uri.queryParameters['sni'],
          "reality": {
            "enabled": uri.queryParameters['security'] == 'reality',
            "public_key": uri.queryParameters['pbk'],
            "short_id": uri.queryParameters['sid'],
          },
          "utls": {
            "enabled": true,
            "fingerprint": uri.queryParameters['fp'],
          }
        }
      };
    } else if (uri.scheme == 'ssh') {
      final userInfoParts = uri.userInfo.split(':');
      String username = '';
      String? privateKeyBase64;
      String? privateKeyPassphrase; // Assuming no passphrase for now based on the request

      if (userInfoParts.isNotEmpty) {
        username = userInfoParts[0];
        if (userInfoParts.length > 1) {
          privateKeyBase64 = userInfoParts.sublist(1).join(':');
        }
      }

      String? privateKey;
      if (privateKeyBase64 != null && privateKeyBase64.isNotEmpty) {
        try {
          privateKey = utf8.decode(base64Decode(privateKeyBase64));
        } catch (e) {
          throw FormatException('Failed to decode Base64 private key: $e');
        }
      }

      outbound = {
        "type": "ssh",
        "tag": "proxy",
        "server": uri.host,
        "server_port": uri.port,
        "user": username,
        if (privateKey != null) "private_key": privateKey,
        if (privateKeyPassphrase != null) "private_key_passphrase": privateKeyPassphrase,
      };
    } else if (uri.scheme == 'hysteria2') {
      final password = uri.userInfo;
      final obfsType = uri.queryParameters['obfs'];
      final obfsPassword = uri.queryParameters['obfspassword'];
      final upMbps = int.tryParse(uri.queryParameters['up_mbps'] ?? '100') ?? 50;
      final downMbps = int.tryParse(uri.queryParameters['down_mbps'] ?? '100') ?? 50;
      final network = uri.queryParameters['network'] ?? 'tcp';
      final tlsSni = uri.queryParameters['tls_sni'];
      final tlsFingerprint = uri.queryParameters['tls_fingerprint'];

      outbound = {
        "type": "hysteria2",
        "tag": "proxy",
        "server": uri.host,
        "server_port": uri.port,
        "password": password,
        //"up_mbps": upMbps,
        //"down_mbps": downMbps,
        //"network": network,
        if (obfsType != null && obfsPassword != null)
          "obfs": {
            "type": obfsType,
            "password": obfsPassword,
          },
        "tls": {
          "enabled": true,
          if (tlsSni != null) "server_name": tlsSni,
        }
      };
    } else {
      throw UnsupportedError('Unsupported protocol scheme: ${uri.scheme}');
    }

    final dnsProvider = settings['dns_provider'] as String;

    final dns = {
      "servers": [
        {
          "type": "tcp",
          "tag": "dns-proxy",
          "server": dnsProvider == 'cloudflare' ? '1.1.1.1' : (dnsProvider == 'adguard' ? '94.140.14.14' : '8.8.8.8'),
        }
      ],
      "strategy": "prefer_ipv4",
      "rules": [
        {"server": "dns-proxy"}
      ]
    };

    final directOutbound = {
      "type": "direct",
      "tag": "direct",
    };

    final List<Map<String, dynamic>> rules = [
      {"action": "sniff"},
      //{"network": "icmp", "action": "reject", "method": "reply", "outbound": "direct"},
      {"protocol": "dns", "action": "hijack-dns"}
    ];

    final List<String> excludedDomains = List<String>.from(settings['excluded_domains'] ?? []);
    if (excludedDomains.isNotEmpty) {
      rules.insert(0, {
        "domain_keyword": excludedDomains,
        "action": "route",
        "outbound": "direct",
      });
    }

    final List<String> excludedDomainSuffixes = List<String>.from(settings['excluded_domain_suffixes'] ?? []);
    if (excludedDomainSuffixes.isNotEmpty) {
      rules.insert(0, {
        "domain_suffix": excludedDomainSuffixes,
        "action": "route",
        "outbound": "direct",
      });
    }

    final Map<String, dynamic> tunInbound;
    final Map<String, dynamic> routeConfig;

    if (Platform.isAndroid) {
      tunInbound = <String, dynamic>{
        "type": "tun",
        "tag": "tun-in",
        "address": ["172.20.10.1/24"],
        "mtu": 1500,
        "route_address": ["0.0.0.0/1", "128.0.0.0/1"],
        "auto_route": false,
        "strict_route": true,
        "stack": "gvisor",
        "sniff": true,
      };

      if (settings['per_app_proxy_enabled'] as bool) {
        if (settings['per_app_proxy_mode'] as String == 'only_selected') {
          tunInbound['include_package'] = settings['per_app_proxy_list'] as List<String>;
        } else {
          tunInbound['exclude_package'] = ["com.hwl.hwl_vpn", ...(settings['per_app_proxy_list'] as List<String>)];
        }
      } else {
        tunInbound['exclude_package'] = ["com.hwl.hwl_vpn"];
      }

      routeConfig = {"rules": rules};
    } else if (Platform.isWindows) {
      tunInbound = <String, dynamic>{
        "type": "tun",
        "tag": "tun-in",
        "address": ["172.20.10.1/24"],
        "mtu": 1500,
        "route_address": ["0.0.0.0/1", "128.0.0.0/1"],
        "auto_route": true,
        "strict_route": true,
        "stack": "gvisor",
        "sniff": true,
      };
      routeConfig = {"rules": rules, "auto_detect_interface": true};
    } else if (Platform.isMacOS || Platform.isIOS) {
      tunInbound = <String, dynamic>{
        "type": "tun",
        "tag": "tun-in",
        "address": ["172.20.10.1/24"],
        "mtu": 1500,
        "route_address": ["0.0.0.0/1", "128.0.0.0/1"],
        "auto_route": true,
        "strict_route": true,
        "stack": "gvisor", 
        "sniff": true,
      };
      routeConfig = {"rules": rules, "auto_detect_interface": true};
    } else {
      throw UnsupportedError('Platform not supported for Singbox config generation.');
    }

    final inbounds = [tunInbound];
    if (settings['use_mixed_inbound'] as bool) {
      inbounds.add({
        "type": "mixed",
        "tag": "mixed-in",
        "listen": settings['mixed_inbound_listen_address'],
        "listen_port": settings['mixed_inbound_listen_port']
      });
    }

    final config = {
      "log": {"level": settings['enable_logging'] as bool ? "debug" : "error", "timestamp": true},
      "dns": dns,
      "inbounds": inbounds,
      "outbounds": [outbound, directOutbound],
      "route": routeConfig,
    };

    return jsonEncode(config);
  }
}