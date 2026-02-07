import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hwl_vpn/api/api_service.dart';
import 'package:hwl_vpn/models/server_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:dart_ping/dart_ping.dart';
import 'package:hwl_vpn/screens/home_screen.dart';
import 'package:hwl_vpn/services/secure_storage_service.dart';
import 'package:collection/collection.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:uuid/uuid.dart'; // Import Uuid package
import 'package:hwl_vpn/services/vpn_service.dart';

enum SubscriptionStatus { unknown, active, expired, guest }

class ServerService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final PreferencesService _prefs = PreferencesService();

  List<Country> _countries = [];
  List<Country> get countries => _countries;

  Country? _selectedCountry;
  Country? get selectedCountry => _selectedCountry;

  Server? _selectedServer;
  Server? get selectedServer => _selectedServer;

  Protocol _selectedProtocol = Protocol.vless;
  Protocol get selectedProtocol => _selectedProtocol;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, int?> _serverPings = {};
  Map<String, int?> get serverPings => _serverPings;

  SubscriptionStatus _subscriptionStatus = SubscriptionStatus.unknown;
  SubscriptionStatus get subscriptionStatus => _subscriptionStatus;

  DateTime? _subscriptionEndDate;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;

  bool get shouldShowAds {
    if (_subscriptionStatus == SubscriptionStatus.active) {
       // Check if it's actually offline mode "active"
       // Ideally we should have a separate status, but for now we rely on the checkSubscriptionStatus logic
       // Since checkSubscriptionStatus sets active for offline, we need to be careful.
       // However, offline mode implies no server connection, so no ads logic should run ideally.
       // But wait, shouldShowAds is used for UI banners.
       // If offline mode, we don't want ads.
       return false; 
    }
    return _subscriptionStatus == SubscriptionStatus.guest ||
      _subscriptionStatus == SubscriptionStatus.expired;
  }
  
  // We need to override the getter to check preferences if we want to be strictly safe, 
  // but since checkSubscriptionStatus is async and this is a getter, we can't await.
  // We rely on checkSubscriptionStatus setting a state that we can distinguish or we accept that 'active' means no ads.
  // In checkSubscriptionStatus for offline mode, I set it to 'active'. 
  // 'active' normally means paid/premium, so no ads. This works for offline mode too.
  
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  ConnectionStatus get connectionStatus => _connectionStatus;

  void setConnectionStatus(ConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      notifyListeners();
    }
  }

  static const _logChannel = EventChannel('com.hwl.hwl-vpn/logs');
  StreamSubscription? _logSubscription;
  final StringBuffer _logBuffer = StringBuffer();
  String get logs => _logBuffer.toString();

  final Map<String, String> _countryCodes = {
    'USA': 'US', 'Canada': 'CA', 'Germany': 'DE', 'Japan': 'JP',
    'Australia': 'AU', 'UK': 'GB', 'France': 'FR', 'Netherlands': 'NL',
    'Singapore': 'SG', 'India': 'IN', 'Brazil': 'BR', 'South Korea': 'KR',
    'Argentina': 'AR',
    'Austria': 'AT',
    'Belgium': 'BE',
    'Switzerland': 'CH',
    'China': 'CN',
    'Spain': 'ES',
    'Finland': 'FI',
    'Hong Kong': 'HK',
    'Indonesia': 'ID',
    'Ireland': 'IE',
    'Israel': 'IL',
    'Italy': 'IT',
    'Kazakhstan': 'KZ',
    'Malaysia': 'MY',
    'New Zealand': 'NZ',
    'Poland': 'PL',
    'Sweden': 'SE',
    'Turkey': 'TR',
    'Taiwan': 'TW',
    'Ukraine': 'UA',
    'Russia': 'RU',
    'Norway': 'NO',
    'Denmark': 'DK',
    'Czechia': 'CZ',
    'Romania': 'RO',
    'Mexico': 'MX',
    'South Africa': 'ZA',
    'United Arab Emirates': 'AE',
  };

  ServerService() {
    // Initialization is now handled by the UI by calling initialize().
  }

  void initLogListener() {
    if (_logSubscription != null) return; // Already initialized
    _logSubscription = _logChannel.receiveBroadcastStream().listen(
      (log) {
        if (log == "__CLEAR_LOGS__\n") {
          _logBuffer.clear();
        } else {
          _logBuffer.write(log);
        }
        notifyListeners();
      },
      onError: (error) {
        _logBuffer.writeln('❌ [Flutter] Log stream error: $error');
        notifyListeners();
      },
    );
  }

  void clearLogs() {
    _logBuffer.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    await _loadSelectionFromPrefs();
    await checkSubscriptionStatus(); // Check status on init
    notifyListeners();
    fetchDataInBackground();
  }

  Future<void> checkSubscriptionStatus() async {
    final isOffline = await _prefs.getOfflineMode();
    if (isOffline) {
      _subscriptionStatus = SubscriptionStatus.active; // Treat as active for UI purposes
      notifyListeners();
      return;
    }

    final isGuest = await _prefs.getUseFreeServers();
    if (isGuest) {
      _subscriptionStatus = SubscriptionStatus.guest;
      notifyListeners();
      return;
    }

    final result = await _apiService.getDeviceStatus();
    if (result['success'] == true) {
      final status = result['status'];
      if (status == 'expired') {
        _subscriptionStatus = SubscriptionStatus.expired;
      } else {
        _subscriptionStatus = SubscriptionStatus.active;
      }
      if (result['subscription_end'] != null) {
        _subscriptionEndDate = DateTime.tryParse(result['subscription_end']);
      }
    } else {
      _subscriptionStatus = SubscriptionStatus.unknown;
    }
    notifyListeners();
  }

  Future<void> _loadSelectionFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final countryName = prefs.getString('selected_country_name');
    final serverJson = prefs.getString('selected_server_json');
    final protocolName = prefs.getString('selected_protocol');

    if (protocolName != null) {
      _selectedProtocol = Protocol.values.firstWhere((p) => p.name == protocolName, orElse: () => Protocol.vless);
    }

    if (serverJson != null) {
      _selectedServer = Server.fromJson(jsonDecode(serverJson));
    }

    if (countryName != null && _selectedServer != null) {
      _selectedCountry = Country(name: countryName, code: _countryCodes[countryName] ?? '', servers: [_selectedServer!]);
    }
  }

  Future<void> refreshCountries() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (await _prefs.getOfflineMode()) {
        _countries = [];
        _selectedCountry = null;
        _selectedServer = null;
        return;
      }

      var countriesJson = await _apiService.getCountriesWithServers();
      if (countriesJson != null) {
        // --- FAKE SERVER INJECTION FOR TESTING ---
        // var netherlandsData = countriesJson.firstWhere(
        //   (c) => c['name'] == 'Netherlands',
        //   orElse: () {
        //     final newCountry = {'name': 'Netherlands', 'servers': []};
        //     countriesJson.add(newCountry);
        //     return newCountry as Map<String, dynamic>;
        //   },
        // );

        // var fakeServers = List<Map<String, dynamic>>.from(netherlandsData['servers']);
        // for (int i = 0; i < 50; i++) {
        //   fakeServers.add({
        //     'name': 'Fake Server #${i + 1}',
        //     'uuid': Uuid().v4(),
        //     'ip': '8.8.8.8',
        //     'status': 'subscribe',
        //     'has_vless': true,
        //     'has_ssh': false,
        //     'vless_link': 'vless://fake-uuid@fake-server:443?flow=xtls-rprx-vision&security=reality&sni=example.com&fp=chrome&pbk=fake_pbk&sid=fake_sid',
        //     'ssh_link': 'ssh://user:pass@fake-server:22',
        //   });
        // }
        // netherlandsData['servers'] = fakeServers;
        // --- END OF FAKE SERVER INJECTION ---

        _countries = countriesJson.map((c) => Country.fromJson(c, _countryCodes)).toList();
        
        // New: Save to secure storage after successful fetch
        final jsonToCache = jsonEncode(_countries.map((c) => c.toJson()).toList());
        await _secureStorage.saveCountriesWithServers(jsonToCache);
        
        final now = DateTime.now().millisecondsSinceEpoch;
        await _prefs.saveServerCacheTimestamp(now);
        await VpnService.saveCacheTimestamp(now);
        
        _syncSelection();
      } else {
        // This is a valid failure case where we should check cache.
        throw Exception('Failed to fetch countries: response was null.');
      }
    } catch (e) {
      if (kDebugMode) {
        print("Could not fetch server data from API: $e. Trying cache.");
      }
      final timestamp = await _prefs.getServerCacheTimestamp();
      const cacheValidityHours = 168;
      final isCacheStale = timestamp == null ||
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp)).inHours > cacheValidityHours;

      if (isCacheStale) {
        if (kDebugMode) {
          print("Cache is stale or missing. Clearing local server data.");
        }
        await _secureStorage.saveCountriesWithServers('[]'); // Clear storage
        await _prefs.clearServerCacheTimestamp(); // Clear timestamp
        _countries = [];
        _selectedCountry = null;
        _selectedServer = null;
      } else {
        if (kDebugMode) {
          print("Loading from non-stale cache.");
        }
        final cachedJsonString = await _secureStorage.getSavedCountriesWithServers();
        if (cachedJsonString != null && cachedJsonString.isNotEmpty) {
          try {
            final List<dynamic> decodedList = jsonDecode(cachedJsonString);
            _countries = decodedList.map((json) => Country.fromCacheJson(json)).toList();
            if (kDebugMode) {
              print("Loaded ${_countries.length} countries from cache.");
            }
            _syncSelection();
          } catch (cacheError) {
            if (kDebugMode) {
              print("Error parsing cached country data: $cacheError");
            }
            _countries = [];
          }
        } else {
          if (kDebugMode) {
            print("No cached country data found.");
          }
          _countries = [];
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _syncSelection() {
    if (_selectedCountry != null) {
      final currentSelectedCountry = _countries.firstWhereOrNull((c) => c.name == _selectedCountry!.name);
      if (currentSelectedCountry != null) {
        _selectedCountry = currentSelectedCountry;
        if (_selectedServer != null) {
          final currentSelectedServer = _selectedCountry!.servers.firstWhereOrNull((s) => s.uuid == _selectedServer!.uuid);
          _selectedServer = currentSelectedServer ?? (_selectedCountry!.servers.isNotEmpty ? _selectedCountry!.servers.first : null);
        } else {
           _selectedServer = _selectedCountry!.servers.isNotEmpty ? _selectedCountry!.servers.first : null;
        }
      } else {
        _selectedCountry = _countries.isNotEmpty ? _countries.first : null;
        _selectedServer = _selectedCountry?.servers.isNotEmpty ?? false ? _selectedCountry!.servers.first : null;
      }
    } else if (_countries.isNotEmpty) {
        _selectedCountry = _countries.first;
        _selectedServer = _selectedCountry!.servers.isNotEmpty ? _selectedCountry!.servers.first : null;
    }
  }

  Future<void> fetchDataInBackground() async {
    await refreshCountries();
    if (_selectedCountry != null) {
      await pingServersForCountry(_selectedCountry!);
    }
  }

  void selectCountry(Country country) {
    _selectedCountry = country;
    _selectedServer = country.servers.isNotEmpty ? country.servers.first : null;
    if (_selectedServer != null) {
      _updateProtocolForServer(_selectedServer!);
    }
    _saveSelection();
    notifyListeners();
    pingServersForCountry(country);
  }

  void selectServer(Server server) {
    if (_selectedServer?.uuid == server.uuid) {
      return;
    }
    _selectedServer = server;
    _updateProtocolForServer(server);
    _saveSelection();
    notifyListeners();
  }

  void selectProtocol(Protocol protocol) {
    if (_selectedProtocol == protocol) return;
    _selectedProtocol = protocol;
    _saveSelection();
    notifyListeners();
  }

  void clearPings() {
    _serverPings.clear();
  }

  Future<void> pingServersForCountry(Country country) async {
    final List<Future> pingFutures = [];
    bool needsUiUpdate = false;

    for (var server in country.servers) {
      if (!_serverPings.containsKey(server.uuid)) {
        _serverPings[server.uuid] = -1; // Mark as pinging
        needsUiUpdate = true;
        pingFutures.add(_getIcmpPing(server.ip).then((ping) {
          _serverPings[server.uuid] = ping;
        }));
      }
    }

    if (needsUiUpdate) {
      notifyListeners(); // Show "pinging..." for new servers
    }

    if (pingFutures.isNotEmpty) {
      await Future.wait(pingFutures);
      notifyListeners(); // Update UI with new ping values
    }
  }

  Future<int?> _getIcmpPing(String? host) async {
    if (host == null || host.isEmpty) {
      return null;
    }
    try {
      final ping = Ping(
        host,
        count: 4,
        timeout: 2,
        encoding: Platform.isWindows ? const SystemEncoding() : utf8,
        forceCodepage: Platform.isWindows,
      );
      final responses = await ping.stream.toList();
      final List<int> successfulPings = [];

      for (final res in responses) {
        final time = res.response?.time?.inMilliseconds;
        if (time != null) {
          successfulPings.add(time);
        }
      }

      if (successfulPings.isEmpty) {
        return null;
      }

      final minPing = successfulPings.reduce(min);
      return minPing;
    } catch (e) {
      if (kDebugMode) {
        print('Exception during ICMP ping for $host: $e');
      }
      return null;
    }
  }

  void _updateProtocolForServer(Server server) {
    if (_selectedProtocol == Protocol.vless && !server.hasVless) {
      if (server.hasSsh) {
        _selectedProtocol = Protocol.ssh;
      } else if (server.hasHysteria2) {
        _selectedProtocol = Protocol.hysteria2;
      }
    } else if (_selectedProtocol == Protocol.ssh && !server.hasSsh) {
      if (server.hasVless) {
        _selectedProtocol = Protocol.vless;
      } else if (server.hasHysteria2) {
        _selectedProtocol = Protocol.hysteria2;
      }
    } else if (_selectedProtocol == Protocol.hysteria2 && !server.hasHysteria2) {
      if (server.hasVless) {
        _selectedProtocol = Protocol.vless;
      } else if (server.hasSsh) {
        _selectedProtocol = Protocol.ssh;
      }
    }
  }

  Future<void> _saveSelection() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedCountry != null) {
      await prefs.setString('selected_country_name', _selectedCountry!.name);
    }
    if (_selectedServer != null) {
      await prefs.setString('selected_server_json', jsonEncode(_selectedServer!.toJson()));
    } else {
      await prefs.remove('selected_server_json');
    }
    await prefs.setString('selected_protocol', _selectedProtocol.name);
  }
}