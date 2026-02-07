import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/services/icon_cache.dart';
import 'package:hwl_vpn/utils/colors.dart';

class AppInfo {
  final String name;
  final String packageName;

  AppInfo({required this.name, required this.packageName});
}

class AppIcon extends StatefulWidget {
  final String packageName;
  const AppIcon({super.key, required this.packageName});

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  static const platform = MethodChannel('com.hwl_vpn.app/channel');
  final IconCache _iconCache = IconCache();
  Uint8List? _icon;

  @override
  void initState() {
    super.initState();
    _getIcon();
  }

  Future<void> _getIcon() async {
    if (_iconCache.has(widget.packageName)) {
      if (mounted) {
        setState(() {
          _icon = _iconCache.get(widget.packageName);
        });
      }
      return;
    }

    try {
      final Uint8List? iconData = await platform.invokeMethod('getAppIcon', {'packageName': widget.packageName});
      if (mounted) {
        setState(() {
          _icon = iconData;
        });
        if (iconData != null) {
          _iconCache.set(widget.packageName, iconData);
        }
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to get app icon: '${e.message}'.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_icon != null) {
      return Image.memory(_icon!, width: 40, height: 40);
    } else {
      // Placeholder while loading
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(child: Icon(Icons.android)),
      );
    }
  }
}

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});
  static const routeName = '/app-selection';
  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  static const platform = MethodChannel('com.hwl_vpn.app/channel');
  List<AppInfo> _installedApps = [];
  Set<String> _selectedPackageNames = {};
  bool _isLoading = true;
  bool _showSystemApps = false;
  bool _isFirstLoad = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstLoad) {
      final selectedApps = ModalRoute.of(context)!.settings.arguments as List<String>?;
      if (selectedApps != null) {
        _selectedPackageNames = selectedApps.toSet();
      }
      _loadApps();
      _isFirstLoad = false;
    }
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<dynamic> apps = await platform.invokeMethod('getInstalledApps', {'showSystemApps': _showSystemApps});
      _installedApps = apps.map((app) {
        return AppInfo(
          name: app['name'],
          packageName: app['packageName'],
        );
      }).toList();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to get installed apps: '${e.message}'.");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onAppSelected(String packageName, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedPackageNames.add(packageName);
      } else {
        _selectedPackageNames.remove(packageName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_selectedPackageNames.toList());
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.selectApps),
          actions: [
            if (!_isLoading)
              Row(
                children: [
                  Text(localizations.showSystemApps),
                  Switch(
                    value: _showSystemApps,
                    onChanged: (value) {
                      setState(() {
                        _showSystemApps = value;
                      });
                      _loadApps();
                    },
                    activeColor: primaryColor,
                  ),
                ],
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _installedApps.length,
                itemBuilder: (context, index) {
                  final app = _installedApps[index];
                  final isSelected = _selectedPackageNames.contains(app.packageName);
                  return CheckboxListTile(
                    title: Text(app.name),
                    subtitle: Text(app.packageName),
                    secondary: AppIcon(packageName: app.packageName),
                    value: isSelected,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _onAppSelected(app.packageName, value);
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
