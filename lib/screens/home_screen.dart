import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hwl_vpn/api/api_service.dart';
import 'package:country_flags/country_flags.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/screens/account_screen.dart';
import 'package:hwl_vpn/services/ad_service.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/services/server_service.dart';
import 'package:hwl_vpn/services/vpn_service.dart';
import 'package:provider/provider.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hwl_vpn/utils/route_observer.dart';

import '../utils/colors.dart';
import './settings_screen.dart';

enum Protocol { vless, ssh, hysteria2 }

enum ConnectionStatus { connected, disconnected, connecting, disconnecting }

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  AnimationController? _animationController;
  Animation<Color?>? _colorAnimation;
  Animation<double>? _glowAnimation;

  Widget? _notificationContent;
  bool _showNotification = false;
  Timer? _notificationTimer;

  final VpnService _vpnService = VpnService();
  double _protocolButtonWidth = 0;

  final AdService _adService = AdService();
  BannerAd? _stickyBanner;
  BannerAd? _sheetBanner;

  ServerService? _serverService;
  bool _serverServiceInitialized = false;

  static const _iosVpnStatusChannel = EventChannel('com.hwl.hwl-vpn/status');
  StreamSubscription? _iosVpnStatusSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_serverServiceInitialized) {
      _serverService = Provider.of<ServerService>(context, listen: false);
      _serverService!.addListener(_updateAds);
      _serverService!.initialize();
      _serverService!.initLogListener();
      _serverServiceInitialized = true;
    }

    if (_protocolButtonWidth == 0) {
      final localizations = AppLocalizations.of(context)!;
      final labelStyle =
          Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 14);
      final vlessWidth =
          _calculateTextWidth(localizations.vlessProtocol, labelStyle);
      final altWidth =
          _calculateTextWidth(localizations.alternativeProtocol, labelStyle);
      final maxWidth = max(vlessWidth, altWidth);
      final segmentWidth = maxWidth + 48; // 24 padding on each side
      _protocolButtonWidth = segmentWidth;
    }
    
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    _refreshAd();
  }

  void _refreshAd() {
    if (!mounted) return;
    final showAds = _serverService?.shouldShowAds ?? false;

    if (showAds) {
      setState(() {
        _stickyBanner?.destroy();
        _stickyBanner = null;
      });
      _updateAds();
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _colorAnimation = ColorTween(begin: primaryColor, end: accentColor2)
        .animate(_animationController!);
    _glowAnimation = Tween<double>(begin: 5, end: 15).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _animationController!.addListener(() {
      setState(() {});
    });

    VpnService.platform.setMethodCallHandler(_handleMethod);
    if (Platform.isIOS || Platform.isMacOS) {
      _listenToIosVpnStatus();
    }
  }

  void _listenToIosVpnStatus() {
    final serverService = Provider.of<ServerService>(context, listen: false);
    _iosVpnStatusSubscription =
        _iosVpnStatusChannel.receiveBroadcastStream().listen((status) {
      if (!mounted) return;
      switch (status) {
        case 'connected':
          serverService.setConnectionStatus(ConnectionStatus.connected);
          break;
        case 'connecting':
        case 'reasserting':
          serverService.setConnectionStatus(ConnectionStatus.connecting);
          break;
        case 'disconnecting':
          serverService.setConnectionStatus(ConnectionStatus.disconnecting);
          break;
        case 'disconnected':
        case 'invalid':
          serverService.setConnectionStatus(ConnectionStatus.disconnected);
          break;
        default:
          break;
      }
    });
  }

  void _updateAds() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final showAds = _serverService?.shouldShowAds ?? false;

    if (showAds && _stickyBanner == null) {
      if (mounted) {
        setState(() {
          _stickyBanner = _adService.createStickyBanner(context, 'R-M-17417280-6');
        });
      }
    } 
    else if (!showAds && _stickyBanner != null) {
      if (mounted) {
        setState(() {
          _stickyBanner?.destroy();
          _stickyBanner = null;
        });
      }
    }
  }

  Future<void> _handleMethod(MethodCall call) async {
    final serverService = Provider.of<ServerService>(context, listen: false);
    switch (call.method) {
      case 'updateStatus':
        if (!mounted) return;
        final status = call.arguments as String;
        if (status == 'Started') {
          serverService.setConnectionStatus(ConnectionStatus.connected);
          _showTopNotification(Text(
              AppLocalizations.of(context)!.statusConnected,
              style: TextStyle(
                  color: lightColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold)));
        } else if (status.startsWith('Error:')) {
          serverService.setConnectionStatus(ConnectionStatus.disconnected);
          _showTopNotification(
            Text(
              status,
              style: const TextStyle(color: accentColor1, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          );
        } else {
          serverService.setConnectionStatus(ConnectionStatus.disconnected);
        }
        break;
      case 'onVpnStopped':
        if (!mounted) return;
        serverService.setConnectionStatus(ConnectionStatus.disconnected);
        break;
      default:
        if (kDebugMode) {
          print('Unknown method ${call.method}');
        }
    }
  }

  double _calculateTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _serverService?.removeListener(_updateAds);
    _animationController?.dispose();
    _notificationTimer?.cancel();
    _iosVpnStatusSubscription?.cancel();
    _stickyBanner?.destroy();
    _sheetBanner?.destroy();
    super.dispose();
  }

  Color _getPingColor(int? ping) {
    if (ping == null || ping < 0) {
      return lightColor.withOpacity(0.5);
    }
    if (ping <= 350) {
      return accentColor2;
    }
    if (ping <= 650) {
      return Colors.amber;
    }
    return accentColor1;
  }

  Future<void> _disconnect() async {
    final serverService = Provider.of<ServerService>(context, listen: false);
    if (serverService.connectionStatus != ConnectionStatus.connected) return;

    serverService.setConnectionStatus(ConnectionStatus.disconnecting);
    await _vpnService.stopVpn();
    // Ensure the final state is set to disconnected, even if the native event is missed.
    serverService.setConnectionStatus(ConnectionStatus.disconnected);

    if (mounted) {
      final localizations = AppLocalizations.of(context)!;
      _showTopNotification(Text(localizations.statusDisconnected,
          style: TextStyle(
              color: lightColor.withOpacity(0.7),
              fontWeight: FontWeight.bold)));
    }
  }

  void _showTopNotification(Widget child) {
    if (mounted) {
      _notificationTimer?.cancel();
      setState(() {
        _notificationContent = child;
        _showNotification = true;
      });
      _notificationTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showNotification = false;
          });
        }
      });
    }
  }

  Future<void> _handleRefresh() async {
    final serverService = Provider.of<ServerService>(context, listen: false);
    await serverService.checkSubscriptionStatus(); // Check subscription status

    final apiService = ApiService();
    final localizations = AppLocalizations.of(context)!;

    try {
      // Wait for both futures to complete.
      final results = await Future.wait([
        serverService.fetchDataInBackground(),
        apiService.getDeviceStatus().timeout(const Duration(seconds: 5)),
      ]);

      if (!mounted) return;

      // Check status from getDeviceStatus
      final statusResult = results[1] as Map<String, dynamic>;
      if (statusResult['success'] == true) {
        _showTopNotification(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 12),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  localizations.servicesOnline,
                  style: TextStyle(color: lightColor.withOpacity(0.7), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      } else {
        // This case might be hit if getDeviceStatus returns success:false but doesn't throw.
        throw Exception('Device status check failed.');
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.circle, color: accentColor1, size: 12),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                localizations.servicesOffline,
                style: TextStyle(color: accentColor1, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ));
      }
    }
  }

  void _showCountrySelectionSheet() {
    final serverService = Provider.of<ServerService>(context, listen: false);
    serverService.clearPings();
    serverService.refreshCountries().whenComplete(() {
      if (serverService.selectedCountry != null) {
        serverService.pingServersForCountry(serverService.selectedCountry!);
      }
    });
    if (serverService.shouldShowAds && (Platform.isAndroid || Platform.isIOS)) {
      _sheetBanner = _adService.createStickyBanner(context, 'R-M-17417280-9');
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: darkColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 12.0, bottom: 24.0),
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: lightGrayColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.selectCountryAndServer,
                          style: const TextStyle(
                            color: lightColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                            children: [
                              Consumer<ServerService>(
                                builder: (context, serverService, child) {
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    alignment: WrapAlignment.center,
                                    children: serverService.countries.map((country) {
                                      final bool isSelected = country.name ==
                                          serverService.selectedCountry?.name;
                                      return GestureDetector(
                                        onTap: () async {
                                          final serverService = Provider.of<ServerService>(context, listen: false);
                                          if (serverService.connectionStatus == ConnectionStatus.connected && serverService.selectedCountry?.name != country.name) {
                                            await _disconnect();
                                          }
                                          setSheetState(() {
                                            serverService.selectCountry(country);
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                          constraints: const BoxConstraints(minWidth: 80, maxWidth: 150),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? primaryColor.withOpacity(0.3)
                                                : lightGrayColor,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: isSelected
                                                ? Border.all(
                                                    color: primaryColor, width: 2)
                                                : null,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                height: 40,
                                                width: 60,
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: CountryFlag.fromCountryCode(
                                                    country.code,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                country.name,
                                                style: const TextStyle(
                                                    color: lightColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                                softWrap: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Text(
                                AppLocalizations.of(context)!.servers,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: lightColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Consumer<ServerService>(
                                builder: (context, serverService, child) {
                                  final localizations = AppLocalizations.of(context)!;
                                  final boldStyle = DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold);
                                  if (serverService.selectedCountry == null ||
                                      serverService
                                          .selectedCountry!.servers.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20.0),
                                      child: Text(
                                        localizations.noServersForCountry,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: lightColor.withOpacity(0.7)),
                                      ),
                                    );
                                  }
                                                                                                      return Column(
                                                                                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                                        children: serverService
                                                                                                            .selectedCountry!.servers
                                                                                                            .map((server) {
                                                                    
                                                                        final bool isSelected = server.uuid ==
                                                                            serverService.selectedServer?.uuid;
                                                                        final int? ping =
                                                                            serverService.serverPings[server.uuid];
                                                                            //print(server.status);
                                                                        
                                                                        final bool isLocked = serverService.shouldShowAds && server.status != 'free';
                                  
                                                                        return Opacity(
                                                                          opacity: isLocked ? 0.5 : 1.0,
                                                                          child: Container(
                                                                            margin: const EdgeInsets.symmetric(vertical: 5.0),
                                                                            decoration: BoxDecoration(
                                                                              color: isSelected ? primaryColor.withOpacity(0.8) : lightGrayColor,
                                                                              borderRadius: BorderRadius.circular(15),
                                                                            ),
                                                                            child: Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                              children: [
                                                                                GestureDetector(
                                                                                  behavior: HitTestBehavior.opaque,
                                                                                  onTap: () async {
                                                                                    if (isLocked) return;
                                                                                    final serverService = Provider.of<ServerService>(context, listen: false);
                                                                                    if (serverService.selectedServer?.uuid != server.uuid) {
                                                                                      if (serverService.connectionStatus == ConnectionStatus.connected) {
                                                                                        await _disconnect();
                                                                                      }
                                                                                      setSheetState(() {
                                                                                        serverService.selectServer(server);
                                                                                      });
                                                                                    }
                                                                                  },
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                                                                    child: Row(
                                                                                      mainAxisAlignment:
                                                                                          MainAxisAlignment.spaceBetween,
                                                                                      children: [
                                                                                        Expanded(
                                                                                          child: RichText(
                                                                                            text: TextSpan(
                                                                                              children: [
                                                                                                TextSpan(
                                                                                                  text: server.name,
                                                                                                  style: boldStyle,
                                                                                                ),
                                                                                                if (server.status == 'free')
                                                                                                  WidgetSpan(
                                                                                                    alignment: PlaceholderAlignment.middle,
                                                                                                    child: Padding(
                                                                                                      padding: const EdgeInsets.only(left: 8.0),
                                                                                                      child: Container(
                                                                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                                                        decoration: BoxDecoration(
                                                                                                          border: Border.all(color: Colors.white, width: 1),
                                                                                                          borderRadius: BorderRadius.circular(4),
                                                                                                        ),
                                                                                                        child: Text(
                                                                                                          localizations.freeTag,
                                                                                                          style: const TextStyle(
                                                                                                            color: Colors.white,
                                                                                                            fontSize: 10,
                                                                                                            fontWeight: FontWeight.w500,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  )
                                                                                                else
                                                                                                  WidgetSpan(
                                                                                                    alignment: PlaceholderAlignment.middle,
                                                                                                    child: Padding(
                                                                                                      padding: const EdgeInsets.only(left: 8.0),
                                                                                                      child: Container(
                                                                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                                                        decoration: BoxDecoration(
                                                                                                          border: Border.all(color: accentColor2, width: 1),
                                                                                                          borderRadius: BorderRadius.circular(4),
                                                                                                        ),
                                                                                                        child: Text(
                                                                                                          localizations.premiumTag,
                                                                                                          style: const TextStyle(
                                                                                                            color: accentColor2,
                                                                                                            fontSize: 10,
                                                                                                            fontWeight: FontWeight.w500,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                    ),
                                                                                                  ),
                                                                                              ],
                                                                                            ),
                                                                                            overflow: TextOverflow.ellipsis,
                                                                                            maxLines: 1,
                                                                                          ),
                                                                                        ),
                                                                                        Row(
                                                                                          children: [
                                                                                            if (isLocked)
                                                                                              const Padding(
                                                                                                padding: EdgeInsets.only(right: 8.0),
                                                                                                child: Icon(Icons.lock_outline, size: 16, color: lightColor),
                                                                                              ),
                                                                                            Container(
                                                                                              width: 60,
                                                                                              alignment:
                                                                                                  Alignment.centerRight,
                                                                                              child: () {
                                                                                                if (ping == -1) {
                                                                                                  return LoadingAnimationWidget
                                                                                                      .progressiveDots(
                                                                                                    color: lightColor,
                                                                                                    size: 20,
                                                                                                  );
                                                                                                } else if (ping != null) {
                                                                                                  return Text(
                                                                                                    '$ping ms',
                                                                                                    style: TextStyle(
                                                                                                        color: lightColor
                                                                                                            .withOpacity(
                                                                                                                0.8)),
                                                                                                  );
                                                                                                } else {
                                                                                                  return Text(
                                                                                                    localizations.pingNA,
                                                                                                    style: TextStyle(
                                                                                                        color: lightColor
                                                                                                            .withOpacity(
                                                                                                                0.5)),
                                                                                                  );
                                                                                                }
                                                                                              }(),
                                                                                            ),
                                                                                            const SizedBox(width: 8),
                                                                                            Icon(
                                                                                              Icons.signal_cellular_alt,
                                                                                              color: _getPingColor(ping),
                                                                                              size: 16,
                                                                                            ),
                                                                                          ],
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                if (isSelected && (server.hasVless || server.hasSsh || server.hasHysteria2))
                                                                                  Builder(
                                                                                    builder: (context) {
                                                                                      final int protocolCount = (server.hasVless ? 1 : 0) + (server.hasHysteria2 ? 1 : 0) + (server.hasSsh ? 1 : 0);
                                                                                      
                                                                                      Widget buildProtocolButton(String label, bool isSelected, VoidCallback onTap) {
                                                                                        final button = GestureDetector(
                                                                                          onTap: onTap,
                                                                                          child: Container(
                                                                                            margin: const EdgeInsets.symmetric(horizontal: 4),
                                                                                            padding: EdgeInsets.symmetric(
                                                                                              vertical: 8, 
                                                                                              horizontal: protocolCount > 1 ? 8 : 32
                                                                                            ),
                                                                                            decoration: BoxDecoration(
                                                                                              color: isSelected ? accentColor2 : Colors.white.withOpacity(0.05),
                                                                                              borderRadius: BorderRadius.circular(8),
                                                                                              border: isSelected ? null : Border.all(color: lightGrayColor.withOpacity(0.3)),
                                                                                            ),
                                                                                            alignment: Alignment.center,
                                                                                            child: FittedBox(
                                                                                              fit: BoxFit.scaleDown,
                                                                                              child: Text(
                                                                                                label,
                                                                                                style: TextStyle(
                                                                                                  color: isSelected ? darkColor : lightColor.withOpacity(0.7),
                                                                                                  fontSize: 12,
                                                                                                  fontWeight: FontWeight.bold
                                                                                                ),
                                                                                                textAlign: TextAlign.center,
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        );
                                                                                        
                                                                                        if (protocolCount > 1) {
                                                                                          return Expanded(child: button);
                                                                                        }
                                                                                        return button;
                                                                                      }

                                                                                      return Container(
                                                                                        width: double.infinity,
                                                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                                                        decoration: BoxDecoration(
                                                                                          color: Colors.black.withOpacity(0.3),
                                                                                          borderRadius: const BorderRadius.only(
                                                                                            bottomLeft: Radius.circular(15),
                                                                                            bottomRight: Radius.circular(15),
                                                                                          )
                                                                                        ),
                                                                                        child: Row(
                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                          children: [
                                                                                            if (server.hasVless)
                                                                                              buildProtocolButton(
                                                                                                localizations.vlessProtocol,
                                                                                                serverService.selectedProtocol == Protocol.vless,
                                                                                                () async {
                                                                                                  final serverService = Provider.of<ServerService>(context, listen: false);
                                                                                                  if (serverService.selectedProtocol != Protocol.vless) {
                                                                                                    if (serverService.connectionStatus == ConnectionStatus.connected) {
                                                                                                      await _disconnect();
                                                                                                    }
                                                                                                    setSheetState(() {
                                                                                                      serverService.selectProtocol(Protocol.vless);
                                                                                                    });
                                                                                                  }
                                                                                                  Future.microtask(() => Navigator.of(context).pop());
                                                                                                },
                                                                                              ),
                                                                                            if (server.hasHysteria2)
                                                                                              buildProtocolButton(
                                                                                                localizations.hysteria2Protocol,
                                                                                                serverService.selectedProtocol == Protocol.hysteria2,
                                                                                                () async {
                                                                                                  final serverService = Provider.of<ServerService>(context, listen: false);
                                                                                                  if (serverService.selectedProtocol != Protocol.hysteria2) {
                                                                                                    if (serverService.connectionStatus == ConnectionStatus.connected) {
                                                                                                      await _disconnect();
                                                                                                    }
                                                                                                    setSheetState(() {
                                                                                                      serverService.selectProtocol(Protocol.hysteria2);
                                                                                                    });
                                                                                                  }
                                                                                                  Future.microtask(() => Navigator.of(context).pop());
                                                                                                },
                                                                                              ),
                                                                                            if (server.hasSsh)
                                                                                              buildProtocolButton(
                                                                                                localizations.alternativeProtocol,
                                                                                                serverService.selectedProtocol == Protocol.ssh,
                                                                                                () async {
                                                                                                  final serverService = Provider.of<ServerService>(context, listen: false);
                                                                                                  if (serverService.selectedProtocol != Protocol.ssh) {
                                                                                                    if (serverService.connectionStatus == ConnectionStatus.connected) {
                                                                                                      await _disconnect();
                                                                                                    }
                                                                                                    setSheetState(() {
                                                                                                      serverService.selectProtocol(Protocol.ssh);
                                                                                                    });
                                                                                                  }
                                                                                                  Future.microtask(() => Navigator.of(context).pop());
                                                                                                },
                                                                                              ),
                                                                                          ],
                                                                                        ),
                                                                                      );
                                                                                    },
                                                                                  ),
                                          ],
                                        ),
                                      ));
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_sheetBanner != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AdWidget(bannerAd: _sheetBanner!),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _sheetBanner?.destroy();
      _sheetBanner = null;
      _refreshAd();
    });
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildExpiredBanner(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: accentColor1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              localizations.subscriptionExpired,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _launchURL('https://t.me/your_bot'), // TODO: Replace with actual bot link
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accentColor1,
            ),
            child: Text(localizations.renewSubscription),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Consumer<ServerService>(
          builder: (context, serverService, child) {
            final isConnecting = serverService.connectionStatus == ConnectionStatus.connecting;
            final isDisconnecting = serverService.connectionStatus == ConnectionStatus.disconnecting;
            final isConnected = serverService.connectionStatus == ConnectionStatus.connected;

            // Control animation based on centralized status
            if (isConnected) {
              _animationController?.forward();
            } else { // ConnectionStatus.disconnected, ConnectionStatus.connecting
              _animationController?.reverse();
            }

            if (serverService.subscriptionStatus == SubscriptionStatus.expired &&
                serverService.connectionStatus == ConnectionStatus.connected &&
                serverService.selectedServer?.status != 'free') {
              Future.microtask(() => _disconnect());
            }
            return Stack(
              children: [
                Column(
                  children: [
                    if (serverService.subscriptionStatus == SubscriptionStatus.expired)
                      _buildExpiredBanner(context),
                    Expanded(
                      child: Stack(
                        children: [
                          // Notification is in the background
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            top: _showNotification ? (56.0 + 16.0) : 0,
                            left: 0,
                            right: 0,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              opacity: _showNotification ? 1.0 : 0.0,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.75,
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: _notificationContent ?? const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Main UI is in the foreground
                          LayoutBuilder(builder: (context, constraints) {
                            return RefreshIndicator(
                              onRefresh: _handleRefresh,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 50),
                                child: SizedBox(
                                  height: max(0, constraints.maxHeight - 50), // Adjust height for banner
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: lightGrayColor,
                                          borderRadius: BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: SizedBox(
                                          height: 56,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.settings,
                                                        color: lightColor),
                                                    onPressed: () {
                                                      Navigator.pushNamed(context,
                                                          SettingsScreen.routeName);
                                                    },
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 40, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: darkColor,
                                                    border: Border.all(
                                                        color: primaryColor, width: 1.5),
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    localizations.appName,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: lightColor,
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.person,
                                                        color: lightColor),
                                                    onPressed: () {
                                                      Navigator.pushNamed(context,
                                                          AccountScreen.routeName);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 200,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (_colorAnimation?.value ??
                                                          primaryColor)
                                                      .withOpacity(0.5),
                                                  blurRadius: 30,
                                                  spreadRadius: _glowAnimation?.value ?? 5,
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: (isConnecting || isDisconnecting)
                                                  ? null
                                                  : () async {
                                                HapticFeedback.mediumImpact();

                                                if (isConnected) {
                                                  await _disconnect();
                                                  return;
                                                }

                                                serverService.clearLogs();
                                                serverService.setConnectionStatus(ConnectionStatus.connecting);

                                                final prefs = PreferencesService();
                                                final personalKey = await prefs.getPersonalKey();

                                                String? vpnKeyToUse;

                                                if (personalKey != null && personalKey.isNotEmpty) {
                                                  // Use personal key if available
                                                  vpnKeyToUse = personalKey;
                                                } else {
                                                  // Fallback to selected server
                                                  final server = serverService.selectedServer;
                                                  if (server == null) {
                                                    _showTopNotification(Text(
                                                        localizations.selectServerFirst,
                                                        style: TextStyle(
                                                            color:
                                                                lightColor.withOpacity(0.7),
                                                            fontWeight:
                                                                FontWeight.bold)));
                                                    serverService.setConnectionStatus(ConnectionStatus.disconnected);
                                                    return;
                                                  }
                                                  
                                                  final requiredProtocol = serverService.selectedProtocol;
                                                  if (requiredProtocol == Protocol.vless) {
                                                    vpnKeyToUse = server.vlessLink;
                                                  } else if (requiredProtocol == Protocol.ssh) {
                                                    vpnKeyToUse = server.sshLink;
                                                  } else {
                                                    vpnKeyToUse = server.hysteria2Link;
                                                  }
                                                }


                                                if (vpnKeyToUse != null && vpnKeyToUse.isNotEmpty) {
                                                  await _vpnService.startVpn(
                                                      customVlessLink: vpnKeyToUse);
                                                  serverService.setConnectionStatus(ConnectionStatus.connected);
                                                  _showTopNotification(Text(
                                                    localizations.statusConnected,
                                                    style: TextStyle(
                                                        color: lightColor.withOpacity(0.7),
                                                        fontWeight: FontWeight.bold),
                                                  ));
                                                } else {
                                                  serverService.setConnectionStatus(ConnectionStatus.disconnected);
                                                  _showTopNotification(Text(
                                                      localizations.failedToGetKey,
                                                      style: TextStyle(
                                                          color: accentColor1,
                                                          fontWeight: FontWeight.bold)));
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                elevation: 0,
                                                shape: const CircleBorder(),
                                                backgroundColor:
                                                    _colorAnimation?.value ??
                                                        primaryColor,
                                                padding: const EdgeInsets.all(20),
                                              ),
                                              child: const Icon(
                                                Icons.power_settings_new,
                                                size: 90,
                                                color: lightColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),

                                          Padding(
                                            padding: const EdgeInsets.only(top: 24.0),
                                            child: GestureDetector(
                                              onTap: _showCountrySelectionSheet,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 20, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF383838),
                                                  borderRadius:
                                                      BorderRadius.circular(50.0),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          Colors.black.withOpacity(0.2),
                                                      blurRadius: 10,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    serverService.selectedCountry != null &&
                                                            serverService.selectedCountry!.code.isNotEmpty
                                                        ? SizedBox(
                                                            width: 30,
                                                            height: 20,
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(5),
                                                              child: CountryFlag.fromCountryCode(
                                                                serverService.selectedCountry!.code,
                                                              ),
                                                            ),
                                                          )
                                                        : const Text('🏳️', style: TextStyle(fontSize: 20)),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      serverService.selectedCountry?.name ?? localizations.selectCountry,
                                                      style: const TextStyle(color: lightColor, fontSize: 14, fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(Icons.keyboard_arrow_down, color: lightColor, size: 20),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_stickyBanner != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AdWidget(bannerAd: _stickyBanner!),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
