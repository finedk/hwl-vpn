// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HWL VPN';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get language => 'Language';

  @override
  String get vlessProtocol => 'VLESS';

  @override
  String get hysteria2Protocol => 'Hysteria 2';

  @override
  String get alternativeProtocol => 'Alternative';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get selectCountryAndServer => 'Select Country and Server';

  @override
  String get servers => 'Servers';

  @override
  String get noServersForCountry => 'No servers for this country yet.';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get mixedInbound => 'Mixed Inbound';

  @override
  String get enableMixedInbound => 'Enable Mixed Inbound Proxy';

  @override
  String get listenPort => 'Port';

  @override
  String get dnsProvider => 'DNS Provider';

  @override
  String get google => 'Google';

  @override
  String get cloudflare => 'Cloudflare';

  @override
  String get adguard => 'AdGuard';

  @override
  String get perAppProxy => 'Per-app proxy';

  @override
  String get perAppProxyMode => 'Mode';

  @override
  String get allExcept => 'All except';

  @override
  String get onlySelected => 'Only selected';

  @override
  String get selectApps => 'Select apps';

  @override
  String get account => 'Account';

  @override
  String get linkDevice => 'Link Device';

  @override
  String get unlinkDevice => 'Unlink Device';

  @override
  String get selfCheck => 'Self-Check';

  @override
  String get enterCode => 'Enter your code';

  @override
  String get deviceIsLinked => 'Device is linked';

  @override
  String get deviceNotLinked => 'Device not linked';

  @override
  String get checking => 'Checking...';

  @override
  String get unlinking => 'Unlinking...';

  @override
  String get linkSuccess => 'Device linked successfully';

  @override
  String get linkFailed => 'Failed to link device';

  @override
  String get unlinkSuccess => 'Device unlinked successfully';

  @override
  String get unlinkFailed => 'Failed to unlink device';

  @override
  String get checkSuccess => 'Device is linked correctly';

  @override
  String get checkFailed => 'Device is not linked or token is invalid';

  @override
  String get serverAddress => 'Server Address';

  @override
  String get enterServerAddress => 'Enter server address (URL or IP:Port)';

  @override
  String get resetValues => 'Reset Values';

  @override
  String get resetWarningTitle => 'Reset values?';

  @override
  String get resetWarningContent => 'This will unlink your device and generate a new identity. This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get resetSuccess => 'Values have been reset.';

  @override
  String get deviceNameOptional => 'Device Name (Optional)';

  @override
  String get selectServerFirst => 'Please select a server first.';

  @override
  String get connectingStatus => 'Connecting...';

  @override
  String get vpnKeyReceivedTitle => 'VPN Key Received';

  @override
  String get failedToGetKey => 'Failed to get VPN key.';

  @override
  String get servicesOnline => 'All services are online';

  @override
  String get servicesOffline => 'Services are temporarily unavailable';

  @override
  String get welcomeMessage => 'Welcome to HWL VPN';

  @override
  String get onboardingDescription => 'Log in to access all features, or continue as a guest.';

  @override
  String get authorize => 'Log In';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get continueButton => 'Continue';

  @override
  String get unlinkDeviceWarningTitle => 'Unlink device?';

  @override
  String get unlinkDeviceWarningContent => 'This action will unlink your device. Are you sure?';

  @override
  String get changeDeviceName => 'Change Device Name';

  @override
  String get save => 'Save';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetSettingsWarningTitle => 'Reset settings?';

  @override
  String get resetSettingsWarningContent => 'This will reset all application settings to their default values. This action cannot be undone.';

  @override
  String get guestModeActive => 'You are currently in guest mode';

  @override
  String get updateFailed => 'Failed to update';

  @override
  String get persistentNotification => 'Persistent Notification';

  @override
  String get enableMemoryLimit => 'Enable Memory Limit';

  @override
  String get notRecommended => 'Not recommended';

  @override
  String get enableMemoryLimitWarningTitle => 'Enable Memory Limit?';

  @override
  String get enableMemoryLimitWarningContent => 'Enabling the memory limit can cause VPN instability and is generally not recommended. Proceed?';

  @override
  String get enable => 'Enable';

  @override
  String get ok => 'OK';

  @override
  String get showSystemApps => 'Show System Apps';

  @override
  String get couldNotVerifyStatus => 'Could not verify status, check network connection.';

  @override
  String get checkFailedCouldNotConnect => 'Check failed: Could not connect to server.';

  @override
  String get pingNA => 'N/A';

  @override
  String get freeTag => 'Free';

  @override
  String get premiumTag => 'Premium';

  @override
  String get mixedInboundDescription => 'Enables a local proxy server that can accept both HTTP and SOCKS5 connections on a single port. This allows other devices on your local network to use the VPN connection through this device (e.g., in tethering mode), provided you configure them to use this device as a proxy.';

  @override
  String get perAppProxyDescription => 'Allows you to select which apps should use the VPN connection. You can either include only selected apps or exclude selected apps.';

  @override
  String get hideConsoleWindow => 'Hide Console Window';

  @override
  String get hideConsoleWindowDescription => 'For sing-box process on Windows';

  @override
  String get excludedDomains => 'Excluded Domains';

  @override
  String get excludedDomainsDescription => 'Comma-separated list of domains to exclude from VPN.';

  @override
  String get excludedDomainSuffixes => 'Excluded Domain Suffixes';

  @override
  String get excludedDomainSuffixesDescription => 'Domain suffixes to exclude from VPN, e.g., .local, .lan';

  @override
  String get closeBehavior => 'Close Button Behavior';

  @override
  String get minimizeToTray => 'Minimize to Tray';

  @override
  String get exitOnClose => 'Exit Application';

  @override
  String get show => 'Show';

  @override
  String get exit => 'Exit';

  @override
  String get enableLogging => 'Enable Logging';

  @override
  String get enableLoggingWarningTitle => 'Enable Logging?';

  @override
  String get enableLoggingWarningContent => 'Enabling logging can consume disk space and slightly reduce performance. This feature is primarily for developers or for troubleshooting issues with technical support. Are you sure you want to enable it?';

  @override
  String get showLogs => 'Show Logs';

  @override
  String get logsTitle => 'Logs';

  @override
  String get clearLogsTooltip => 'Clear logs';

  @override
  String get noLogsToShow => 'No logs to display.';

  @override
  String get launchOnStartup => 'Launch on Startup';

  @override
  String get faqTelegramChannel => 'Telegram Channel';

  @override
  String get faqTelegramChannelLink => 'https://t.me/hwlab_official_en';

  @override
  String get faqWebsite => 'Our Website';

  @override
  String get faqWebsiteLink => 'https://hinaworklab.tech/#/vpn';

  @override
  String get faqSupportEmail => 'Support Email';

  @override
  String get faqSupportEmailAddress => 'hinaworklab@yandex.com';

  @override
  String get faqQ6 => 'What to do if there are errors during application operation?';

  @override
  String get faqA6 => 'If you encounter persistent issues, try resetting the application values. This will unlink your device and generate a new identity, effectively resetting the app to its initial state. This action is irreversible and can be found in the Settings screen under \'Reset Values\'.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get iAccept => 'I accept the';

  @override
  String get and => 'and';

  @override
  String get youMustAccept => 'You must accept the terms to continue';

  @override
  String get privacyPolicyLink => 'https://hinaworklab.tech/#/privacy-hwl-vpn';

  @override
  String get termsOfUseLink => 'https://hinaworklab.tech/#/terms-hwl-vpn';

  @override
  String get personalKeysExplanationHysteria2 => '• Hysteria 2 (hysteria2://password@host:port?params...)';

  @override
  String get legal => 'Legal';

  @override
  String get updateTermsMessage => 'Please review and accept our updated terms to continue.';

  @override
  String get subscriptionExpired => 'Subscription expired. Only free servers are available.';

  @override
  String get renewSubscription => 'Renew';

  @override
  String get personalKeys => 'Personal Keys';

  @override
  String get personalKeysEnterLink => 'Enter connection link - vless://4721231d-aae1-...';

  @override
  String get personalKeysClear => 'Clear';

  @override
  String get personalKeysWarningTitle => 'Warning:';

  @override
  String get personalKeysWarningBody => ' This section is for experienced users only.';

  @override
  String get personalKeysExplanation1 => 'You can paste and use your own key here.';

  @override
  String get personalKeysExplanation2 => 'Supported configurations:';

  @override
  String get personalKeysExplanationVless => '• vless (TCP) + reality (vless without reality doesn\'t work)';

  @override
  String get personalKeysExplanationSsh => '• ssh format user:private_key@ip:port (Private key must be Base64 encoded)';

  @override
  String get personalKeysExplanation3 => 'After pasting the key, return to the main screen and press the connect button. If the key field is filled, the app will use it, ignoring the server selected from the list. Important: use your key only if you understand VPN configurations and have one.';

  @override
  String get faqAndContacts => 'FAQ & Tech Support';

  @override
  String get faqSupport => 'Tech Support';

  @override
  String get faqBot => 'Our Bot';

  @override
  String get faqTitle => 'Frequently Asked Questions';

  @override
  String get faqQ1 => 'What is a \'Personal Key\'?';

  @override
  String get faqA1 => 'This is a feature that allows you to use your own configuration key (link) to connect, instead of selecting a server from the general list. This provides more flexibility and control over your VPN connection.';

  @override
  String get faqQ2 => 'Which protocol should I choose?';

  @override
  String get faqA2 => 'VLESS is the preferred option for most users. Hysteria 2 provides better speeds on poor networks but might be less stable. Use \'Alternative\' (SSH) if others don\'t work.';

  @override
  String get faqQ3 => 'Why is my connection speed slow?';

  @override
  String get faqA3 => 'Speed depends on many factors: server load, distance to it, the quality of your internet connection, and your provider\'s restrictions. Try choosing a different server or connecting at a different time.';

  @override
  String get faqQ4 => 'The app won\'t connect, what should I do?';

  @override
  String get faqA4 => '1. Check your internet connection.\n2. Make sure you have selected a server.\n3. Try a different server or protocol.\n4. If you are using a personal key, ensure it is correct and active.\n5. Contact our tech support.';

  @override
  String get faqQ5 => 'How to check connection to servers?';

  @override
  String get faqA5 => 'On the main screen, pull down to refresh the list of available servers.';

  @override
  String get mixedInboundIpWarning => 'Your device IP is currently unavailable. Using 0.0.0.0. Some features might not work as expected.';

  @override
  String get mixedInboundIpUnavailable => 'Device IP Unavailable';

  @override
  String get mixedInboundIosMacWarning => 'On iOS & macOS, this may not work in hotspot mode.';

  @override
  String get offlineMode => 'Autonomous Mode';

  @override
  String get offlineModeDescription => 'Disables server connection and API requirements. Use only with Personal Keys.';

  @override
  String get offlineModeWarningTitle => 'Enable Autonomous Mode?';

  @override
  String get offlineModeWarningContent => 'This will disable access to public servers and account features. You will need a Personal Key to connect. Proceed?';
}
