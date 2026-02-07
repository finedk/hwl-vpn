import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hwl_vpn/api/api_service.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/screens/app_selection_screen.dart';
import 'package:hwl_vpn/screens/logs_screen.dart';
import 'package:hwl_vpn/screens/personal_key_screen.dart';
import 'package:hwl_vpn/screens/faq_screen.dart';
import 'package:hwl_vpn/screens/onboarding_screen.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/services/secure_storage_service.dart';
import 'package:hwl_vpn/services/vpn_service.dart';
import 'package:hwl_vpn/services/ad_service.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import '../main.dart';
import '../utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum DnsProvider { google, cloudflare, adguard }
enum PerAppProxyMode { allExcept, onlySelected }

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefsService = PreferencesService();
  final ApiService _apiService = ApiService();
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isMixedInboundEnabled = false;
  final TextEditingController _mixedInboundPortController =
      TextEditingController();
  DnsProvider _selectedDnsProvider = DnsProvider.google;
  PerAppProxyMode _perAppProxyMode = PerAppProxyMode.allExcept;
  bool _minimizeToTrayOnClose = true;
  bool _launchOnStartup = false;
  List<String> _selectedApps = [];
  bool _persistentNotification = false;
  bool _isMemoryLimitEnabled = false;
  bool _isLoggingEnabled = false;
  bool _hideSingboxConsole = true;
  bool _offlineMode = false;
  final TextEditingController _excludedDomainsController = TextEditingController();
  final TextEditingController _excludedDomainSuffixesController = TextEditingController();
  String? _deviceIp;

  final AdService _adService = AdService();
  BannerAd? _banner;
  bool _isBannerLoaded = false;

  static const _iosChannel = MethodChannel('com.hwl.hwl-vpn/control');

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getDeviceIp();
    _mixedInboundPortController.addListener(() {
      _prefsService.saveMixedInboundPort(int.tryParse(_mixedInboundPortController.text) ?? 10808);
    });
    _serverUrlController.addListener(() {
      _prefsService.saveServerUrl(_serverUrlController.text);
    });
    _excludedDomainsController.addListener(() {
      _prefsService.saveExcludedDomains(_excludedDomainsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList());
    });
    _excludedDomainSuffixesController.addListener(() {
      _prefsService.saveExcludedDomainSuffixes(_excludedDomainSuffixesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBanner();
  }

  void _loadBanner() async {
    if (!_isBannerLoaded) {
      _isBannerLoaded = true;
      final prefs = PreferencesService();
      final api = ApiService();

      final isGuest = await prefs.getUseFreeServers();
      bool isExpired = false;
      if (!isGuest) {
        final statusResult = await api.getDeviceStatus();
        if (statusResult['success'] == true && statusResult['status'] == 'expired') {
          isExpired = true;
        }
      }

      if ((isGuest || isExpired) && mounted && (Platform.isAndroid || Platform.isIOS)) {
        setState(() {
          _banner = _adService.createStickyBanner(context, 'R-M-17417280-8');
        });
      }
    }
  }

  void _loadSettings() async {
    _serverUrlController.text = await _prefsService.getServerUrl();
    _isMixedInboundEnabled = await _prefsService.getMixedInboundEnabled();
    _mixedInboundPortController.text = (await _prefsService.getMixedInboundPort()).toString();
    _selectedDnsProvider = await _prefsService.getDnsProvider();
    _perAppProxyMode = (await _prefsService.getPerAppProxyMode()) == 'only_selected'
        ? PerAppProxyMode.onlySelected
        : PerAppProxyMode.allExcept;
    _selectedApps = await _prefsService.getSelectedApps();
    _persistentNotification = await _prefsService.getPersistentNotification();
    _isMemoryLimitEnabled = !(await _prefsService.getDisableMemoryLimit());
    _isLoggingEnabled = await _prefsService.getEnableLogging();
    _hideSingboxConsole = await _prefsService.getHideSingboxConsole();
    _offlineMode = await _prefsService.getOfflineMode();
    _excludedDomainsController.text = (await _prefsService.getExcludedDomains()).join(', ');
    _excludedDomainSuffixesController.text = (await _prefsService.getExcludedDomainSuffixes()).join(', ');
    _minimizeToTrayOnClose = (await _prefsService.getCloseBehavior()) == 'tray';
    //_launchOnStartup = await launchAtStartup.isEnabled();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _mixedInboundPortController.dispose();
    _serverUrlController.dispose();
    _excludedDomainsController.dispose();
    _excludedDomainSuffixesController.dispose();
    _banner?.destroy();
    super.dispose();
  }

  Future<void> _getDeviceIp() async {
    String? ip;
    try {
      if (Platform.isAndroid) {
        ip = await VpnService.platform.invokeMethod('getWifiIpAddress');
      } else if (Platform.isIOS) {
        ip = await _iosChannel.invokeMethod('getIpAddress');
      } else if (Platform.isWindows) {
        ip = await VpnService.platform.invokeMethod('getIpAddress');
      } else if (Platform.isMacOS) {
        ip = await VpnService.platform.invokeMethod('getIpAddress');
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to get IP: '${e.message}'.");
      }
    }

    if (mounted) {
      setState(() {
        if (ip == null || ip.isEmpty || ip == '?.?.?.?') {
          _deviceIp = null;
        } else {
          _deviceIp = ip;
        }
      });
    }
  }

  void _resetSettings() async {
    await _prefsService.resetToDefaults();
    if (mounted) {
      MyApp.setLocale(context, const Locale('en')); 
    }
    _loadSettings(); 
  }

  void _showResetSettingsConfirmationDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.resetSettingsWarningTitle),
        content: Text(localizations.resetSettingsWarningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetSettings();
            },
            child: Text(localizations.reset, style: const TextStyle(color: accentColor1)),
          ),
        ],
      ),
    );
  }

  void _resetValues() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;

    await _apiService.resetDevice();
    if (!mounted) return;

    await _prefsService.saveIsGuest(false);
    if (!mounted) return;

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(localizations.resetSuccess)),
    );

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      (_) => false,
    );
  }

  void _showResetValuesConfirmationDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.resetWarningTitle),
        content: Text(localizations.resetWarningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetValues();
            },
            child: Text(localizations.reset, style: const TextStyle(color: accentColor1)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
      ),
      body: Stack(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme.copyWith(
                    titleMedium: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 12.0, color: lightColor),
                    bodyMedium: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 10.0, color: lightColor),
                  ),
            ),
            child: ListView(
              padding: EdgeInsets.only(bottom: _banner != null ? 100 : 24),
              children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: lightColor),
                title: Text(localizations.about, style: const TextStyle(color: lightColor)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final textTheme = Theme.of(context).textTheme;
                      return AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            Text(localizations.appName, style: textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            const Text('Version 1.0.5'),
                            const SizedBox(height: 8),
                            const Text('sing-box: 1.12.14'),
                            const SizedBox(height: 24),
                            const Text('© 2026 HWL'),
                            const SizedBox(height: 24),
                            const Text('Powered by sing-box library.'),
                            const SizedBox(height: 12),
                            const Text('Made with ❤️'),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const Divider(color: lightGrayColor),
              ListTile(
                leading: const Icon(Icons.gavel_outlined, color: lightColor),
                title: Text(localizations.privacyPolicy, style: const TextStyle(color: lightColor)),
                onTap: () => _launchURL(localizations.privacyPolicyLink),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: lightColor),
                title: Text(localizations.termsOfUse, style: const TextStyle(color: lightColor)),
                onTap: () => _launchURL(localizations.termsOfUseLink),
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key_outlined, color: lightColor),
                title: Text(localizations.personalKeys, style: const TextStyle(color: lightColor)),
                onTap: () {
                  Navigator.pushNamed(context, PersonalKeyScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.quiz_outlined, color: lightColor),
                title: Text(localizations.faqAndContacts, style: const TextStyle(color: lightColor)),
                onTap: () {
                  Navigator.pushNamed(context, FaqScreen.routeName);
                },
              ),
              const Divider(color: lightGrayColor),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.serverAddress,
                      style: TextStyle(
                        color: lightColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _serverUrlController,
                      style: const TextStyle(color: lightColor),
                      decoration: InputDecoration(
                        hintText: localizations.enterServerAddress,
                        hintStyle: TextStyle(color: lightColor.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: lightGrayColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: lightGrayColor),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.language,
                      style: TextStyle(
                        color: lightColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<Locale>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<Locale>>[
                        ButtonSegment<Locale>(
                          value: const Locale('en'),
                          label: const Text('English'),
                        ),
                        ButtonSegment<Locale>(
                          value: const Locale('ru'),
                          label: const Text('Russian'),
                        ),
                      ],
                      selected: <Locale>{Locale(localizations.localeName)},
                      onSelectionChanged: (Set<Locale> newSelection) {
                        _prefsService.saveLanguage(newSelection.first);
                        MyApp.setLocale(context, newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: lightGrayColor,
                        foregroundColor: lightColor.withOpacity(0.7),
                        selectedForegroundColor: lightColor,
                        selectedBackgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: lightGrayColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        localizations.mixedInbound,
                        style: TextStyle(
                          color: lightColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.help_outline, size: 16, color: lightColor.withOpacity(0.7)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(localizations.mixedInbound),
                              content: Text(localizations.mixedInboundDescription),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(localizations.ok),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SwitchListTile(
                      title: Text(
                        localizations.enableMixedInbound,
                        style: const TextStyle(color: lightColor),
                      ),
                       subtitle: (Platform.isIOS || Platform.isMacOS)
                          ? Text(
                              localizations.mixedInboundIosMacWarning,
                              style: TextStyle(color: lightColor.withOpacity(0.5), fontSize: 12),
                            )
                          : null,
                      value: _isMixedInboundEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _isMixedInboundEnabled = value;
                        });
                        _prefsService.saveMixedInboundEnabled(value);
                        _getDeviceIp(); // Call _getDeviceIp to update IP status dynamically
                      },
                      activeColor: primaryColor,
                      inactiveTrackColor: lightGrayColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_isMixedInboundEnabled && (_deviceIp == null || _deviceIp!.isEmpty))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          localizations.mixedInboundIpWarning,
                          style: TextStyle(color: lightColor.withOpacity(0.5), fontSize: 12),
                        ),
                      ),
                    if (_isMixedInboundEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                final textToCopy = "${_deviceIp ?? '0.0.0.0'}:${_mixedInboundPortController.text}";
                                Clipboard.setData(ClipboardData(text: textToCopy));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "'$textToCopy' copied to clipboard",
                                          style: const TextStyle(color: accentColor2)
                                      )
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _deviceIp ?? '0.0.0.0',
                                      style: const TextStyle(color: lightColor, fontSize: 16),
                                    ),
                                    const Text(
                                      ":",
                                      style: TextStyle(color: lightColor, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _mixedInboundPortController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: lightColor),
                                decoration: InputDecoration(
                                  labelText: localizations.listenPort,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: lightGrayColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: primaryColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: lightGrayColor),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.dnsProvider,
                      style: TextStyle(
                        color: lightColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<DnsProvider>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<DnsProvider>>[
                        ButtonSegment<DnsProvider>(
                          value: DnsProvider.google,
                          label: Text(localizations.google),
                        ),
                        ButtonSegment<DnsProvider>(
                          value: DnsProvider.cloudflare,
                          label: Text(localizations.cloudflare),
                        ),
                        ButtonSegment<DnsProvider>(
                          value: DnsProvider.adguard,
                          label: Text(localizations.adguard),
                        ),
                      ],
                      selected: <DnsProvider>{_selectedDnsProvider},
                      onSelectionChanged: (Set<DnsProvider> newSelection) {
                        setState(() {
                          _selectedDnsProvider = newSelection.first;
                        });
                        _prefsService.saveDnsProvider(newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: lightGrayColor,
                        foregroundColor: lightColor.withOpacity(0.7),
                        selectedForegroundColor: lightColor,
                        selectedBackgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: lightGrayColor),
              if (Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        localizations.perAppProxy,
                        style: TextStyle(
                          color: lightColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.help_outline, size: 16, color: lightColor.withOpacity(0.7)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(localizations.perAppProxy),
                              content: Text(localizations.perAppProxyDescription),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(localizations.ok),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SegmentedButton<PerAppProxyMode>(
                      showSelectedIcon: false,
                      segments: <ButtonSegment<PerAppProxyMode>>[
                        ButtonSegment<PerAppProxyMode>(
                          value: PerAppProxyMode.allExcept,
                          label: Text(localizations.allExcept),
                        ),
                        ButtonSegment<PerAppProxyMode>(
                          value: PerAppProxyMode.onlySelected,
                          label: Text(localizations.onlySelected),
                        ),
                      ],
                      selected: <PerAppProxyMode>{_perAppProxyMode},
                      onSelectionChanged: (Set<PerAppProxyMode> newSelection) {
                        setState(() {
                          _perAppProxyMode = newSelection.first;
                        });
                        _prefsService.savePerAppProxyMode(
                            newSelection.first == PerAppProxyMode.onlySelected ? 'only_selected' : 'all_except');
                      },
                      style: SegmentedButton.styleFrom(
                        backgroundColor: lightGrayColor,
                        foregroundColor: lightColor.withOpacity(0.7),
                        selectedForegroundColor: lightColor,
                        selectedBackgroundColor: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.apps, color: lightColor),
                      title: Text(localizations.selectApps, style: const TextStyle(color: lightColor)),
                      subtitle: Text('${_selectedApps.length} apps selected', style: TextStyle(color: lightColor.withOpacity(0.7))),
                      onTap: () async {
                        final selectedApps = await Navigator.pushNamed(
                          context,
                          AppSelectionScreen.routeName,
                          arguments: _selectedApps,
                        );
                        if (selectedApps != null) {
                          setState(() {
                            _selectedApps = selectedApps as List<String>;
                          });
                          _prefsService.saveSelectedApps(_selectedApps);
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (Platform.isAndroid)
              if (Platform.isAndroid || Platform.isIOS)
              SwitchListTile(
                title: Text(localizations.persistentNotification, style: const TextStyle(color: lightColor)),
                value: _persistentNotification,
                onChanged: (bool value) {
                  setState(() {
                    _persistentNotification = value;
                  });
                  _prefsService.savePersistentNotification(value);
                  VpnService().setPersistentNotification(value);
                },
                activeColor: primaryColor,
                inactiveTrackColor: lightGrayColor,
              ),
              if (Platform.isAndroid || Platform.isIOS)
              const Divider(color: lightGrayColor),
              if (Platform.isAndroid || Platform.isIOS)
              SwitchListTile(
                title: Text(localizations.enableMemoryLimit, style: const TextStyle(color: lightColor)),
                value: _isMemoryLimitEnabled,
                onChanged: (bool value) {
                  if (value) {
                    setState(() {
                      _isMemoryLimitEnabled = true;
                    });
                    _prefsService.saveDisableMemoryLimit(false);
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Отключить лимит памяти?"),
                        content: const Text("Отключение лимита памяти не рекомендуется, так как это может привести к нестабильности VPN."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(localizations.cancel),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(() {
                                _isMemoryLimitEnabled = false;
                              });
                              _prefsService.saveDisableMemoryLimit(true);
                            },
                            child: Text("Отключить", style: const TextStyle(color: accentColor1)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                activeColor: primaryColor,
                inactiveTrackColor: lightGrayColor,
              ),
              if (Platform.isWindows)
                SwitchListTile(
                  title: Text(localizations.hideConsoleWindow, style: const TextStyle(color: lightColor)),
                  subtitle: Text(localizations.hideConsoleWindowDescription, style: TextStyle(color: lightColor.withOpacity(0.7))),
                  value: _hideSingboxConsole,
                  onChanged: (bool value) {
                    setState(() {
                      _hideSingboxConsole = value;
                    });
                    _prefsService.saveHideSingboxConsole(value);
                  },
                  activeColor: primaryColor,
                  inactiveTrackColor: lightGrayColor,
                ),
              if (Platform.isWindows || Platform.isMacOS)
                SwitchListTile(
                  title: Text(localizations.minimizeToTray, style: const TextStyle(color: lightColor)),
                  subtitle: Text(localizations.closeBehavior, style: TextStyle(color: lightColor.withOpacity(0.7))),
                  value: _minimizeToTrayOnClose,
                  onChanged: (bool value) {
                    setState(() {
                      _minimizeToTrayOnClose = value;
                    });
                    _prefsService.saveCloseBehavior(value ? 'tray' : 'exit');
                  },
                  activeColor: primaryColor,
                  inactiveTrackColor: lightGrayColor,
                ),
              // if (Platform.isWindows || Platform.isMacOS)
              //   SwitchListTile(
              //     title: Text(localizations.launchOnStartup, style: const TextStyle(color: lightColor)),
              //     value: _launchOnStartup,
              //     onChanged: (bool value) async {
              //       setState(() {
              //         _launchOnStartup = value;
              //       });
              //       if (value) {
              //         await launchAtStartup.enable();
              //       } else {
              //         await launchAtStartup.disable();
              //       }
              //     },
              //     activeColor: primaryColor,
              //     inactiveTrackColor: lightGrayColor,
              //   ),
              const Divider(color: lightGrayColor),
              SwitchListTile(
                title: Text(localizations.enableLogging, style: const TextStyle(color: lightColor)),
                value: _isLoggingEnabled,
                onChanged: (bool value) {
                  if (value) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(localizations.enableLoggingWarningTitle),
                        content: Text(localizations.enableLoggingWarningContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(localizations.cancel),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(() {
                                _isLoggingEnabled = true;
                              });
                              _prefsService.saveEnableLogging(true);
                            },
                            child: Text(localizations.enable, style: const TextStyle(color: accentColor1)),
                          ),
                        ],
                      ),
                    );
                  } else {
                    setState(() {
                      _isLoggingEnabled = false;
                    });
                    _prefsService.saveEnableLogging(false);
                  }
                },
                activeColor: primaryColor,
                inactiveTrackColor: lightGrayColor,
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined, color: lightColor),
                title: Text(localizations.showLogs, style: const TextStyle(color: lightColor)),
                onTap: () {
                  Navigator.pushNamed(context, LogsScreen.routeName);
                },
              ),
              const Divider(color: lightGrayColor),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(

                      localizations.excludedDomains,

                      style: TextStyle(

                        color: lightColor.withOpacity(0.7),

                        fontSize: 12,

                      ),

                    ),                    const SizedBox(height: 10),
                    TextField(
                      controller: _excludedDomainsController,
                      style: const TextStyle(color: lightColor),
                      decoration: InputDecoration(
                        hintText: localizations.excludedDomainsDescription,
                        hintStyle: TextStyle(color: lightColor.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: lightGrayColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      localizations.excludedDomainSuffixes,
                      style: TextStyle(
                        color: lightColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _excludedDomainSuffixesController,
                      style: const TextStyle(color: lightColor),
                      decoration: InputDecoration(
                        hintText: localizations.excludedDomainSuffixesDescription,
                        hintStyle: TextStyle(color: lightColor.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: lightGrayColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: primaryColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: lightGrayColor),
              SwitchListTile(
                title: Text(localizations.offlineMode, style: const TextStyle(color: lightColor)),
                subtitle: Text(localizations.offlineModeDescription, style: TextStyle(color: lightColor.withOpacity(0.7))),
                value: _offlineMode,
                onChanged: (bool value) {
                  if (value) {
                     showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(localizations.offlineModeWarningTitle),
                        content: Text(localizations.offlineModeWarningContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(localizations.cancel),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _prefsService.saveOfflineMode(true);
                              setState(() {
                                _offlineMode = true;
                              });
                              // Trigger update in ServerService to refresh logic immediately
                              // We can do this by just reloading the app or letting the user navigate back
                              // Ideally, we should notify ServerService
                              // For now, next app start or navigation will pick it up, 
                              // but let's try to make it smoother. 
                              // Actually, HomeScreen init will check it, but we are already in the app.
                              // We should probably restart the app or force a refresh.
                              // Simple way:
                              if (mounted) {
                                // Reload settings logic implies we might need to reset some state
                                // But since we are in settings, user will likely go back to Home.
                                // HomeScreen calls checkSubscriptionStatus and fetchDataInBackground on init.
                                // We might want to trigger a refresh in ServerService if possible.
                              }
                            },
                            child: Text(localizations.enable, style: const TextStyle(color: accentColor1)),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _prefsService.saveOfflineMode(false);
                    setState(() {
                      _offlineMode = false;
                    });
                    // Check if we need to show onboarding
                    final secureStorage = SecureStorageService();
                    secureStorage.getClientSecret().then((secret) {
                      if ((secret == null || secret.isEmpty) && mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                          (_) => false,
                        );
                      }
                    });
                  }
                },
                activeColor: accentColor1,
                inactiveTrackColor: lightGrayColor,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                child: ElevatedButton(
                  onPressed: _showResetSettingsConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor1.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    localizations.resetSettings,
                    style: const TextStyle(color: lightColor, fontSize: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: ElevatedButton(
                  onPressed: _showResetValuesConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF383838),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    localizations.resetValues,
                    style: const TextStyle(color: lightColor, fontSize: 16),
                  ),
                ),
              ),
            ],
            ),
          ),
          if (_banner != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: AdWidget(bannerAd: _banner!),
            ),
        ],
      ),
    );
  }
}
