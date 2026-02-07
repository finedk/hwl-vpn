import 'dart:io';

import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/screens/account_screen.dart';
import 'package:hwl_vpn/screens/agreement_screen.dart';
import 'package:hwl_vpn/screens/app_selection_screen.dart';
import 'package:hwl_vpn/screens/logs_screen.dart';
import 'package:hwl_vpn/screens/personal_key_screen.dart';
import 'package:hwl_vpn/screens/faq_screen.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/services/secure_storage_service.dart';
import 'package:hwl_vpn/services/server_service.dart';
import 'package:provider/provider.dart';
import './screens/home_screen.dart';
import './screens/settings_screen.dart';
import './utils/colors.dart';
import 'package:hwl_vpn/screens/onboarding_screen.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:hwl_vpn/utils/route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final ByteData data = await rootBundle.load('assets/certificates/server.crt');
    final List<int> bytes = data.buffer.asUint8List();
    HttpOverrides.global = MyHttpOverrides(bytes);
  } catch (e) {
    debugPrint('Failed to load certificate: $e');
  }

  runApp(const BootstrapApp());
}

class MyHttpOverrides extends HttpOverrides {
  final List<int> certificate;
  MyHttpOverrides(this.certificate);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final SecurityContext secureContext = context ?? SecurityContext(withTrustedRoots: true);
    try {
      secureContext.setTrustedCertificatesBytes(certificate);
    } catch (e) {
      debugPrint("Error setting trusted certificate: $e");
    }
    return super.createHttpClient(secureContext);
  }
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _initialized = false;
  Locale? _locale;
  bool _onboardingComplete = false;
  bool _agreementsAccepted = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (Platform.isMacOS || Platform.isWindows) {
      await windowManager.ensureInitialized();
      // Set up launch at startup
      launchAtStartup.setup(
        appName: 'HWL VPN',
        appPath: Platform.resolvedExecutable,
      );
    }

    if (Platform.isWindows || Platform.isMacOS) {
      WindowOptions windowOptions = const WindowOptions(
        size: Size(450, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    if (Platform.isIOS) {
      DartPingIOS.register();
    }

    if (Platform.isAndroid || Platform.isIOS) {
      await MobileAds.initialize();
      await MobileAds.setUserConsent(true);
      await MobileAds.setAgeRestrictedUser(false);
    }
    final prefsService = PreferencesService();
    final secureStorageService = SecureStorageService();

    _locale = await prefsService.getLanguage();

    final clientSecret = await secureStorageService.getClientSecret();
    final isGuest = false; // await prefsService.getIsGuest();
    final isOfflineMode = await prefsService.getOfflineMode();
    _onboardingComplete = (clientSecret != null && clientSecret.isNotEmpty) || isGuest || isOfflineMode;

    _agreementsAccepted = (await prefsService.getPrivacyPolicyAccepted() && await prefsService.getTermsOfUseAccepted()) || isOfflineMode;

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: darkColor,
          body: const SizedBox(),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => ServerService(),
      child: MyApp(
        initialLocale: _locale,
        onboardingComplete: _onboardingComplete,
        agreementsAccepted: _agreementsAccepted,
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final Locale? initialLocale;
  final bool onboardingComplete;
  final bool agreementsAccepted;
  const MyApp({super.key, this.initialLocale, required this.onboardingComplete, required this.agreementsAccepted});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  final GlobalKey _globalKey = GlobalKey();
  Locale? _locale;
  bool _trayMenuInitialized = false;

  @override
  void initState() {
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _initTray();
      windowManager.setPreventClose(true);
    }
    super.initState();
    _locale = widget.initialLocale;
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _initTray() async {
    if (Platform.isWindows) {
      String iconPath = '${File(Platform.resolvedExecutable).parent.path}/app_icon.ico';
      await trayManager.setIcon(iconPath);
    } else {
      await trayManager.setIcon(
        'assets/icon/icon.png',
        isTemplate: Platform.isMacOS,
      );
    }
    await trayManager.setToolTip('HWL VPN');
  }

  Future<void> _buildAndSetTrayMenu(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: localizations.show,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: localizations.exit,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    if (Platform.isWindows || Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _globalKey.currentContext;
        if (context != null) {
          _buildAndSetTrayMenu(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        // Temporary fix for localization issue
        try {
          return AppLocalizations.of(context)!.appName;
        } catch (e) {
          return 'HWL VPN';
        }
      },
      locale: _locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [routeObserver],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: darkColor,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: darkColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: lightColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: lightColor),
        ),
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: primaryColor,
          onPrimary: lightColor,
          secondary: accentColor1,
          onSecondary: lightColor,
          error: Colors.redAccent,
          onError: lightColor,
          background: darkColor,
          onBackground: lightColor,
          surface: darkColor,
          onSurface: lightColor,
        ),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'NotoSansMono'),
      ),
      home: Builder(
        key: _globalKey,
        builder: (context) {
          if ((Platform.isWindows || Platform.isMacOS) && !_trayMenuInitialized) {
            _buildAndSetTrayMenu(context);
            _trayMenuInitialized = true;
          }
          if (!widget.onboardingComplete) {
            return const OnboardingScreen();
          } else if (!widget.agreementsAccepted) {
            return const AgreementScreen();
          } else {
            return const HomeScreen();
          }
        },
      ),
      routes: {
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        AgreementScreen.routeName: (context) => const AgreementScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        AppSelectionScreen.routeName: (context) => const AppSelectionScreen(),
        AccountScreen.routeName: (context) => const AccountScreen(),
        LogsScreen.routeName: (context) => const LogsScreen(),
        PersonalKeyScreen.routeName: (context) => const PersonalKeyScreen(),
        FaqScreen.routeName: (context) => const FaqScreen(),
      },
    );
  }

  // Tray Listener
  @override
  void onTrayIconMouseDown() async {
    // Show window on left-click
    await windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  // Window Listener
  @override
  Future<void> onWindowClose() async {
    final prefs = PreferencesService();
    final behavior = await prefs.getCloseBehavior();
    if (behavior == 'tray') {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }
}