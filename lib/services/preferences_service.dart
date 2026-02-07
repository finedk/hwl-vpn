import 'package:flutter/material.dart';
import 'package:hwl_vpn/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hwl_vpn/screens/settings_screen.dart'; // for DnsProvider enum

class PreferencesService {

  static const String _languageCodeKey = 'languageCode';
  static const String _mixedInboundEnabledKey = 'mixedInboundEnabled';
  static const String _mixedInboundPortKey = 'mixedInboundPort';
  static const String _dnsProviderKey = 'dnsProvider';
  static const String _perAppProxyModeKey = 'perAppProxyMode';
  static const String _selectedAppsKey = 'selectedApps';
  static const String _serverUrlKey = 'serverUrl';
  static const String _persistentNotificationKey = 'persistentNotification';
  static const String _disableMemoryLimitKey = 'disableMemoryLimit';
  static const String _isGuestKey = 'isGuest';
  static const String _useFreeServersKey = 'useFreeServers';
  static const String _hideSingboxConsoleKey = 'hideSingboxConsole';
  static const String _excludedDomainsKey = 'excludedDomains';
  static const String _excludedDomainSuffixesKey = 'excludedDomainSuffixes';
  static const String _closeBehaviorKey = 'closeBehavior';
  static const String _enableLoggingKey = 'enableLogging';
  static const String _personalKey = 'personalKey';
  static const String _serverCacheTimestampKey = 'serverCacheTimestamp';
  static const String _privacyPolicyAcceptedKey = 'privacyPolicyAccepted';
  static const String _termsOfUseAcceptedKey = 'termsOfUseAccepted';
  static const String _offlineModeKey = 'offlineMode';

  Future<void> saveOfflineMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, enabled);
  }

  Future<bool> getOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineModeKey) ?? false;
  }

  Future<void> savePrivacyPolicyAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyPolicyAcceptedKey, accepted);
  }

  Future<bool> getPrivacyPolicyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyPolicyAcceptedKey) ?? false;
  }

  Future<void> saveTermsOfUseAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsOfUseAcceptedKey, accepted);
  }

  Future<bool> getTermsOfUseAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsOfUseAcceptedKey) ?? false;
  }

  Future<void> savePersonalKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalKey, key);
  }

  Future<String?> getPersonalKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_personalKey);
  }

  Future<void> saveServerCacheTimestamp(int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_serverCacheTimestampKey, timestamp);
  }

  Future<int?> getServerCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_serverCacheTimestampKey);
  }

  Future<void> clearServerCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverCacheTimestampKey);
  }

  Future<void> saveEnableLogging(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableLoggingKey, isEnabled);
  }

  Future<bool> getEnableLogging() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enableLoggingKey) ?? false;
  }

  Future<void> saveCloseBehavior(String behavior) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_closeBehaviorKey, behavior);
  }

  Future<String> getCloseBehavior() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_closeBehaviorKey) ?? 'tray'; // Default to tray
  }

  Future<void> saveUseFreeServers(bool useFree) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useFreeServersKey, useFree);
  }

  Future<bool> getUseFreeServers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useFreeServersKey) ?? false;
  }

  Future<void> saveIsGuest(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, isGuest);
  }

  Future<bool> getIsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }

  Future<void> saveDisableMemoryLimit(bool isDisabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_disableMemoryLimitKey, isDisabled);
  }

  Future<bool> getDisableMemoryLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_disableMemoryLimitKey) ?? false; // Default to false (limit enabled)
  }

  Future<void> savePersistentNotification(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_persistentNotificationKey, isEnabled);
  }

  Future<bool> getPersistentNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_persistentNotificationKey) ?? false;
  }

  Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }

  Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey) ?? AppConstants.defaultServerUrl;
  }

  Future<void> saveLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
  }

  Future<Locale?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode != null) {
      return Locale(languageCode);
    }
    return null;
  }

  Future<void> saveMixedInboundEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mixedInboundEnabledKey, isEnabled);
  }

  Future<bool> getMixedInboundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mixedInboundEnabledKey) ?? false;
  }

  Future<void> saveMixedInboundPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mixedInboundPortKey, port);
  }

  Future<int> getMixedInboundPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_mixedInboundPortKey) ?? 10808;
  }

  Future<void> saveDnsProvider(DnsProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dnsProviderKey, provider.toString());
  }

  Future<DnsProvider> getDnsProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerString = prefs.getString(_dnsProviderKey);
    if (providerString != null) {
      return DnsProvider.values.firstWhere(
        (e) => e.toString() == providerString,
        orElse: () => DnsProvider.google,
      );
    }
    return DnsProvider.google;
  }

  Future<void> savePerAppProxyMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_perAppProxyModeKey, mode);
  }

  Future<String> getPerAppProxyMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_perAppProxyModeKey) ?? 'all_except';
  }

  Future<void> saveSelectedApps(List<String> packageNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedAppsKey, packageNames);
  }

  Future<List<String>> getSelectedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedAppsKey) ?? [];
  }

  Future<void> saveHideSingboxConsole(bool hide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideSingboxConsoleKey, hide);
  }

  Future<bool> getHideSingboxConsole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideSingboxConsoleKey) ?? true;
  }

  Future<void> saveExcludedDomains(List<String> domains) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_excludedDomainsKey, domains);
  }

  Future<List<String>> getExcludedDomains() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_excludedDomainsKey) ?? [];
  }

  Future<void> saveExcludedDomainSuffixes(List<String> suffixes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_excludedDomainSuffixesKey, suffixes);
  }

  Future<List<String>> getExcludedDomainSuffixes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_excludedDomainSuffixesKey) ?? ['.ru', '.рф'];
  }

  static const String _authTokenKey = 'authToken';

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageCodeKey);
    await prefs.remove(_mixedInboundEnabledKey);
    await prefs.remove(_mixedInboundPortKey);
    await prefs.remove(_dnsProviderKey);
    await prefs.remove(_perAppProxyModeKey);
    await prefs.remove(_selectedAppsKey);
    await prefs.remove(_serverUrlKey);
    await prefs.remove(_persistentNotificationKey);
    await prefs.remove(_disableMemoryLimitKey);
    await prefs.remove(_isGuestKey);
    await prefs.remove(_useFreeServersKey);
    await prefs.remove(_hideSingboxConsoleKey);
    await prefs.remove(_excludedDomainsKey);
    await prefs.remove(_excludedDomainSuffixesKey);
    await prefs.remove(_closeBehaviorKey);
    await prefs.remove(_personalKey);
    await prefs.remove(_serverCacheTimestampKey);
    await prefs.remove(_privacyPolicyAcceptedKey);
    await prefs.remove(_termsOfUseAcceptedKey);
    await prefs.remove(_offlineModeKey);
  }
}
