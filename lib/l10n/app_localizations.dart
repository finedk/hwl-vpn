import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HWL VPN'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @vlessProtocol.
  ///
  /// In en, this message translates to:
  /// **'VLESS'**
  String get vlessProtocol;

  /// No description provided for @hysteria2Protocol.
  ///
  /// In en, this message translates to:
  /// **'Hysteria2'**
  String get hysteria2Protocol;

  /// No description provided for @alternativeProtocol.
  ///
  /// In en, this message translates to:
  /// **'Alternative'**
  String get alternativeProtocol;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @selectCountryAndServer.
  ///
  /// In en, this message translates to:
  /// **'Select Country and Server'**
  String get selectCountryAndServer;

  /// No description provided for @servers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get servers;

  /// No description provided for @noServersForCountry.
  ///
  /// In en, this message translates to:
  /// **'No servers for this country yet.'**
  String get noServersForCountry;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// No description provided for @mixedInbound.
  ///
  /// In en, this message translates to:
  /// **'Mixed Inbound'**
  String get mixedInbound;

  /// No description provided for @enableMixedInbound.
  ///
  /// In en, this message translates to:
  /// **'Enable Mixed Inbound Proxy'**
  String get enableMixedInbound;

  /// No description provided for @listenPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get listenPort;

  /// No description provided for @dnsProvider.
  ///
  /// In en, this message translates to:
  /// **'DNS Provider'**
  String get dnsProvider;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @cloudflare.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare'**
  String get cloudflare;

  /// No description provided for @adguard.
  ///
  /// In en, this message translates to:
  /// **'AdGuard'**
  String get adguard;

  /// No description provided for @perAppProxy.
  ///
  /// In en, this message translates to:
  /// **'Per-app proxy'**
  String get perAppProxy;

  /// No description provided for @perAppProxyMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get perAppProxyMode;

  /// No description provided for @allExcept.
  ///
  /// In en, this message translates to:
  /// **'All except'**
  String get allExcept;

  /// No description provided for @onlySelected.
  ///
  /// In en, this message translates to:
  /// **'Only selected'**
  String get onlySelected;

  /// No description provided for @selectApps.
  ///
  /// In en, this message translates to:
  /// **'Select apps'**
  String get selectApps;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @linkDevice.
  ///
  /// In en, this message translates to:
  /// **'Link Device'**
  String get linkDevice;

  /// No description provided for @unlinkDevice.
  ///
  /// In en, this message translates to:
  /// **'Unlink Device'**
  String get unlinkDevice;

  /// No description provided for @selfCheck.
  ///
  /// In en, this message translates to:
  /// **'Self-Check'**
  String get selfCheck;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get enterCode;

  /// No description provided for @deviceIsLinked.
  ///
  /// In en, this message translates to:
  /// **'Device is linked'**
  String get deviceIsLinked;

  /// No description provided for @deviceNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Device not linked'**
  String get deviceNotLinked;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @unlinking.
  ///
  /// In en, this message translates to:
  /// **'Unlinking...'**
  String get unlinking;

  /// No description provided for @linkSuccess.
  ///
  /// In en, this message translates to:
  /// **'Device linked successfully'**
  String get linkSuccess;

  /// No description provided for @linkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to link device'**
  String get linkFailed;

  /// No description provided for @unlinkSuccess.
  ///
  /// In en, this message translates to:
  /// **'Device unlinked successfully'**
  String get unlinkSuccess;

  /// No description provided for @unlinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unlink device'**
  String get unlinkFailed;

  /// No description provided for @checkSuccess.
  ///
  /// In en, this message translates to:
  /// **'Device is linked correctly'**
  String get checkSuccess;

  /// No description provided for @checkFailed.
  ///
  /// In en, this message translates to:
  /// **'Device is not linked or token is invalid'**
  String get checkFailed;

  /// No description provided for @serverAddress.
  ///
  /// In en, this message translates to:
  /// **'Server Address'**
  String get serverAddress;

  /// No description provided for @enterServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter server address (URL or IP:Port)'**
  String get enterServerAddress;

  /// No description provided for @resetValues.
  ///
  /// In en, this message translates to:
  /// **'Reset Values'**
  String get resetValues;

  /// No description provided for @resetWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset values?'**
  String get resetWarningTitle;

  /// No description provided for @resetWarningContent.
  ///
  /// In en, this message translates to:
  /// **'This will unlink your device and generate a new identity. This action cannot be undone.'**
  String get resetWarningContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Values have been reset.'**
  String get resetSuccess;

  /// No description provided for @deviceNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Device Name (Optional)'**
  String get deviceNameOptional;

  /// No description provided for @selectServerFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a server first.'**
  String get selectServerFirst;

  /// No description provided for @connectingStatus.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connectingStatus;

  /// No description provided for @vpnKeyReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'VPN Key Received'**
  String get vpnKeyReceivedTitle;

  /// No description provided for @failedToGetKey.
  ///
  /// In en, this message translates to:
  /// **'Failed to get VPN key.'**
  String get failedToGetKey;

  /// No description provided for @servicesOnline.
  ///
  /// In en, this message translates to:
  /// **'All services are online'**
  String get servicesOnline;

  /// No description provided for @servicesOffline.
  ///
  /// In en, this message translates to:
  /// **'Services are temporarily unavailable'**
  String get servicesOffline;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HWL VPN'**
  String get welcomeMessage;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Log in to access all features, or continue as a guest.'**
  String get onboardingDescription;

  /// No description provided for @authorize.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authorize;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @unlinkDeviceWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink device?'**
  String get unlinkDeviceWarningTitle;

  /// No description provided for @unlinkDeviceWarningContent.
  ///
  /// In en, this message translates to:
  /// **'This action will unlink your device. Are you sure?'**
  String get unlinkDeviceWarningContent;

  /// No description provided for @changeDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Change Device Name'**
  String get changeDeviceName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @resetSettingsWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset settings?'**
  String get resetSettingsWarningTitle;

  /// No description provided for @resetSettingsWarningContent.
  ///
  /// In en, this message translates to:
  /// **'This will reset all application settings to their default values. This action cannot be undone.'**
  String get resetSettingsWarningContent;

  /// No description provided for @guestModeActive.
  ///
  /// In en, this message translates to:
  /// **'You are currently in guest mode'**
  String get guestModeActive;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get updateFailed;

  /// No description provided for @persistentNotification.
  ///
  /// In en, this message translates to:
  /// **'Persistent Notification'**
  String get persistentNotification;

  /// No description provided for @enableMemoryLimit.
  ///
  /// In en, this message translates to:
  /// **'Enable Memory Limit'**
  String get enableMemoryLimit;

  /// No description provided for @notRecommended.
  ///
  /// In en, this message translates to:
  /// **'Not recommended'**
  String get notRecommended;

  /// No description provided for @enableMemoryLimitWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Memory Limit?'**
  String get enableMemoryLimitWarningTitle;

  /// No description provided for @enableMemoryLimitWarningContent.
  ///
  /// In en, this message translates to:
  /// **'Enabling the memory limit can cause VPN instability and is generally not recommended. Proceed?'**
  String get enableMemoryLimitWarningContent;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @showSystemApps.
  ///
  /// In en, this message translates to:
  /// **'Show System Apps'**
  String get showSystemApps;

  /// No description provided for @couldNotVerifyStatus.
  ///
  /// In en, this message translates to:
  /// **'Could not verify status, check network connection.'**
  String get couldNotVerifyStatus;

  /// No description provided for @checkFailedCouldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Check failed: Could not connect to server.'**
  String get checkFailedCouldNotConnect;

  /// No description provided for @pingNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get pingNA;

  /// No description provided for @freeTag.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeTag;

  /// No description provided for @premiumTag.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumTag;

  /// No description provided for @mixedInboundDescription.
  ///
  /// In en, this message translates to:
  /// **'Enables a local proxy server that can accept both HTTP and SOCKS5 connections on a single port. This allows other devices on your local network to use the VPN connection through this device (e.g., in tethering mode), provided you configure them to use this device as a proxy.'**
  String get mixedInboundDescription;

  /// No description provided for @perAppProxyDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows you to select which apps should use the VPN connection. You can either include only selected apps or exclude selected apps.'**
  String get perAppProxyDescription;

  /// No description provided for @hideConsoleWindow.
  ///
  /// In en, this message translates to:
  /// **'Hide Console Window'**
  String get hideConsoleWindow;

  /// No description provided for @hideConsoleWindowDescription.
  ///
  /// In en, this message translates to:
  /// **'For sing-box process on Windows'**
  String get hideConsoleWindowDescription;

  /// No description provided for @excludedDomains.
  ///
  /// In en, this message translates to:
  /// **'Excluded Domains'**
  String get excludedDomains;

  /// No description provided for @excludedDomainsDescription.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated list of domains to exclude from VPN.'**
  String get excludedDomainsDescription;

  /// No description provided for @excludedDomainSuffixes.
  ///
  /// In en, this message translates to:
  /// **'Excluded Domain Suffixes'**
  String get excludedDomainSuffixes;

  /// No description provided for @excludedDomainSuffixesDescription.
  ///
  /// In en, this message translates to:
  /// **'Domain suffixes to exclude from VPN, e.g., .local, .lan'**
  String get excludedDomainSuffixesDescription;

  /// No description provided for @closeBehavior.
  ///
  /// In en, this message translates to:
  /// **'Close Button Behavior'**
  String get closeBehavior;

  /// No description provided for @minimizeToTray.
  ///
  /// In en, this message translates to:
  /// **'Minimize to Tray'**
  String get minimizeToTray;

  /// No description provided for @exitOnClose.
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get exitOnClose;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @enableLogging.
  ///
  /// In en, this message translates to:
  /// **'Enable Logging'**
  String get enableLogging;

  /// No description provided for @enableLoggingWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Logging?'**
  String get enableLoggingWarningTitle;

  /// No description provided for @enableLoggingWarningContent.
  ///
  /// In en, this message translates to:
  /// **'Enabling logging can consume disk space and slightly reduce performance. This feature is primarily for developers or for troubleshooting issues with technical support. Are you sure you want to enable it?'**
  String get enableLoggingWarningContent;

  /// No description provided for @showLogs.
  ///
  /// In en, this message translates to:
  /// **'Show Logs'**
  String get showLogs;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsTitle;

  /// No description provided for @clearLogsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogsTooltip;

  /// No description provided for @noLogsToShow.
  ///
  /// In en, this message translates to:
  /// **'No logs to display.'**
  String get noLogsToShow;

  /// No description provided for @launchOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Launch on Startup'**
  String get launchOnStartup;

  /// No description provided for @faqTelegramChannel.
  ///
  /// In en, this message translates to:
  /// **'Telegram Channel'**
  String get faqTelegramChannel;

  /// No description provided for @faqTelegramChannelLink.
  ///
  /// In en, this message translates to:
  /// **'https://t.me/hwlab_official_en'**
  String get faqTelegramChannelLink;

  /// No description provided for @faqWebsite.
  ///
  /// In en, this message translates to:
  /// **'Our Website'**
  String get faqWebsite;

  /// No description provided for @faqWebsiteLink.
  ///
  /// In en, this message translates to:
  /// **'https://hinaworklab.tech/#/vpn'**
  String get faqWebsiteLink;

  /// No description provided for @faqSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get faqSupportEmail;

  /// No description provided for @faqSupportEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'hinaworklab@yandex.com'**
  String get faqSupportEmailAddress;

  /// No description provided for @faqQ6.
  ///
  /// In en, this message translates to:
  /// **'What to do if there are errors during application operation?'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In en, this message translates to:
  /// **'If you encounter persistent issues, try resetting the application values. This will unlink your device and generate a new identity, effectively resetting the app to its initial state. This action is irreversible and can be found in the Settings screen under \'Reset Values\'.'**
  String get faqA6;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @iAccept.
  ///
  /// In en, this message translates to:
  /// **'I accept the'**
  String get iAccept;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @youMustAccept.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms to continue'**
  String get youMustAccept;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'https://hinaworklab.tech/#/privacy-hwl-vpn'**
  String get privacyPolicyLink;

  /// No description provided for @termsOfUseLink.
  ///
  /// In en, this message translates to:
  /// **'https://hinaworklab.tech/#/terms-hwl-vpn'**
  String get termsOfUseLink;

  /// No description provided for @personalKeysExplanationHysteria2.
  ///
  /// In en, this message translates to:
  /// **'• hysteria2 (hysteria2://password@host:port?params...)'**
  String get personalKeysExplanationHysteria2;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @updateTermsMessage.
  ///
  /// In en, this message translates to:
  /// **'Please review and accept our updated terms to continue.'**
  String get updateTermsMessage;

  /// No description provided for @subscriptionExpired.
  ///
  /// In en, this message translates to:
  /// **'Subscription expired. Only free servers are available.'**
  String get subscriptionExpired;

  /// No description provided for @renewSubscription.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renewSubscription;

  /// No description provided for @personalKeys.
  ///
  /// In en, this message translates to:
  /// **'Personal Keys'**
  String get personalKeys;

  /// No description provided for @personalKeysEnterLink.
  ///
  /// In en, this message translates to:
  /// **'Enter connection link - vless://4721231d-aae1-...'**
  String get personalKeysEnterLink;

  /// No description provided for @personalKeysClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get personalKeysClear;

  /// No description provided for @personalKeysWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning:'**
  String get personalKeysWarningTitle;

  /// No description provided for @personalKeysWarningBody.
  ///
  /// In en, this message translates to:
  /// **' This section is for experienced users only.'**
  String get personalKeysWarningBody;

  /// No description provided for @personalKeysExplanation1.
  ///
  /// In en, this message translates to:
  /// **'You can paste and use your own key here.'**
  String get personalKeysExplanation1;

  /// No description provided for @personalKeysExplanation2.
  ///
  /// In en, this message translates to:
  /// **'Supported configurations:'**
  String get personalKeysExplanation2;

  /// No description provided for @personalKeysExplanationVless.
  ///
  /// In en, this message translates to:
  /// **'• vless (TCP) + reality (vless without reality doesn\'t work)'**
  String get personalKeysExplanationVless;

  /// No description provided for @personalKeysExplanationSsh.
  ///
  /// In en, this message translates to:
  /// **'• ssh format user:private_key@ip:port (Private key must be Base64 encoded)'**
  String get personalKeysExplanationSsh;

  /// No description provided for @personalKeysExplanation3.
  ///
  /// In en, this message translates to:
  /// **'After pasting the key, return to the main screen and press the connect button. If the key field is filled, the app will use it, ignoring the server selected from the list. Important: use your key only if you understand VPN configurations and have one.'**
  String get personalKeysExplanation3;

  /// No description provided for @faqAndContacts.
  ///
  /// In en, this message translates to:
  /// **'FAQ & Tech Support'**
  String get faqAndContacts;

  /// No description provided for @faqSupport.
  ///
  /// In en, this message translates to:
  /// **'Tech Support'**
  String get faqSupport;

  /// No description provided for @faqBot.
  ///
  /// In en, this message translates to:
  /// **'Our Bot'**
  String get faqBot;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faqTitle;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'What is a \'Personal Key\'?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'This is a feature that allows you to use your own configuration key (link) to connect, instead of selecting a server from the general list. This provides more flexibility and control over your VPN connection.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'Which protocol should I choose?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'VLESS is the preferred option for most users as it provides better performance and traffic obfuscation. Use \'Alternative\' (SSH) if VLESS is not working for some reason.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'Why is my connection speed slow?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'Speed depends on many factors: server load, distance to it, the quality of your internet connection, and your provider\'s restrictions. Try choosing a different server or connecting at a different time.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'The app won\'t connect, what should I do?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'1. Check your internet connection.\n2. Make sure you have selected a server.\n3. Try a different server or protocol.\n4. If you are using a personal key, ensure it is correct and active.\n5. Contact our tech support.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In en, this message translates to:
  /// **'How to check connection to servers?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In en, this message translates to:
  /// **'On the main screen, pull down to refresh the list of available servers.'**
  String get faqA5;

  /// No description provided for @mixedInboundIpWarning.
  ///
  /// In en, this message translates to:
  /// **'Your device IP is currently unavailable. Using 0.0.0.0. Some features might not work as expected.'**
  String get mixedInboundIpWarning;

  /// No description provided for @mixedInboundIpUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device IP Unavailable'**
  String get mixedInboundIpUnavailable;

  /// No description provided for @mixedInboundIosMacWarning.
  ///
  /// In en, this message translates to:
  /// **'On iOS & macOS, this may not work in hotspot mode.'**
  String get mixedInboundIosMacWarning;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Autonomous Mode'**
  String get offlineMode;

  /// No description provided for @offlineModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Disables server connection and API requirements. Use only with Personal Keys.'**
  String get offlineModeDescription;

  /// No description provided for @offlineModeWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Autonomous Mode?'**
  String get offlineModeWarningTitle;

  /// No description provided for @offlineModeWarningContent.
  ///
  /// In en, this message translates to:
  /// **'This will disable access to public servers and account features. You will need a Personal Key to connect. Proceed?'**
  String get offlineModeWarningContent;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
