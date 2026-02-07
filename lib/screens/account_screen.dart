import 'package:flutter/material.dart';
import 'package:hwl_vpn/api/api_service.dart';
import 'package:hwl_vpn/l10n/app_localizations.dart';
import 'package:hwl_vpn/screens/home_screen.dart';
import 'package:hwl_vpn/screens/onboarding_screen.dart';
import 'package:hwl_vpn/services/device_info_service.dart';
import 'package:hwl_vpn/services/preferences_service.dart';
import 'package:hwl_vpn/services/secure_storage_service.dart';
import 'package:hwl_vpn/utils/colors.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  static const routeName = '/account';

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _secureStorageService = SecureStorageService();
  final _apiService = ApiService();
  final _deviceInfoService = DeviceInfoService();
  final _prefsService = PreferencesService();
  final _codeController = TextEditingController();
  final _deviceNameController = TextEditingController();

  bool _isLinked = false;
  bool _isLoading = true;
  bool _showContinueButton = false;
  String _currentDeviceName = '';

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeScreen();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final isOffline = await _prefsService.getOfflineMode();
      if (isOffline) {
        if (mounted) {
          setState(() {
            _isLinked = false; 
            _isLoading = false;
          });
        }
        return;
      }

      final isGuest = await _prefsService.getUseFreeServers();
      if (isGuest) {
        await _fetchDeviceName();
        if (mounted) {
          setState(() {
            _isLinked = false;
          });
        }
        return;
      }

      final secret = await _secureStorageService.getClientSecret();
      if (!mounted) return;

      if (secret == null) {
        await _fetchDeviceName();
        if (mounted) {
          setState(() {
            _isLinked = false;
          });
        }
        return;
      }

      final statusResult = await _apiService.getDeviceStatus();
      if (!mounted) return;

      if (statusResult['success'] == true) {
        setState(() {
          _isLinked = true;
          _currentDeviceName = statusResult['device_name'] ?? '';
        });
      } else {
        if (statusResult['error'] == 'auth') {
          await _secureStorageService.deleteClientSecret();
        }
        setState(() {
          _isLinked = false;
        });
        final errorMessage = statusResult['error'] == 'auth'
            ? localizations.checkFailed
            : "Could not verify status, check network connection.";
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(errorMessage, style: const TextStyle(color: accentColor1))),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.', style: TextStyle(color: accentColor1))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDeviceName() async {
    if (mounted) {
      _deviceNameController.text = await _deviceInfoService.getDeviceName();
    }
  }

  Future<void> _runSelfCheck() async {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final isGuest = await _prefsService.getUseFreeServers();
    final secret = await _secureStorageService.getClientSecret();
    if (secret == null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(localizations.deviceNotLinked)),
      );
      return;
    }

    final statusResult = await _apiService.getDeviceStatus();
    if (!mounted) return;

    if (isGuest) {
      if (statusResult['success'] == true) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(localizations.guestModeActive)),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(localizations.updateFailed, style: const TextStyle(color: accentColor1))),
        );
      }
    } else {
      // Registered user logic
      if (statusResult['success'] == true) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(localizations.checkSuccess)),
        );
        setState(() {
          _isLinked = true;
          _currentDeviceName = statusResult['device_name'] ?? '';
        });
      } else {
        if (statusResult['error'] == 'auth') {
          await _secureStorageService.deleteClientSecret();
        }
        final errorMessage = statusResult['error'] == 'auth'
            ? localizations.checkFailed
            : localizations.checkFailedCouldNotConnect;
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(errorMessage, style: const TextStyle(color: accentColor1))),
        );
        if (mounted) {
          setState(() {
            _isLinked = false;
          });
        }
      }
    }
  }

  void _linkDevice() async {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    if (_codeController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.registerInstance(
      _codeController.text,
      _deviceNameController.text,
    );

    if (!mounted) return;

    final bool success = result['success'];
    final String? errorMessage = result['message'];

    if (success) {
      await _prefsService.saveIsGuest(false);
      await _prefsService.saveUseFreeServers(false);
      setState(() {
        _isLoading = false;
        _showContinueButton = true;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.linkFailed),
          content: Text(errorMessage ?? 'An unknown error occurred.'),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: Text(localizations.ok),
            ),
          ],
        ),
      );
    }
  }

  void _unlinkDevice() async {
    if (!mounted) return;
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    await _apiService.performUnlink();
    if (!mounted) return;

    await _prefsService.saveIsGuest(false);
    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      (_) => false,
    );
  }

  void _showUnlinkConfirmationDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.unlinkDeviceWarningTitle),
        content: Text(localizations.unlinkDeviceWarningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _unlinkDevice();
            },
            child: Text(localizations.unlinkDevice, style: const TextStyle(color: accentColor1)),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceNameDialog() {
    final localizations = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: _currentDeviceName);
    showDialog(
      context: context,
      builder: (context) {
        final dialogNavigator = Navigator.of(context);
        final dialogScaffoldMessenger = ScaffoldMessenger.of(context);

        return AlertDialog(
          title: Text(localizations.changeDeviceName),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(hintText: localizations.deviceNameOptional),
          ),
          actions: [
            TextButton(
              onPressed: () => dialogNavigator.pop(),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text;
                if (newName.isNotEmpty && newName != _currentDeviceName) {
                  final result = await _apiService.updateDeviceName(newName);
                  if (!mounted) return;
                  if (result['success']) {
                    setState(() {
                      _currentDeviceName = newName;
                    });
                    dialogNavigator.pop();
                  } else {
                    dialogScaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(result['message'] ?? 'Failed to update name')),
                    );
                  }
                } else {
                  dialogNavigator.pop();
                }
              },
              child: Text(localizations.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.account),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _runSelfCheck,
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showContinueButton) ...[
                            const Spacer(),
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                            const SizedBox(height: 24),
                            Text(
                              localizations.linkSuccess,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: lightColor),
                            ),
                            const SizedBox(height: 48),
                            ElevatedButton(
                              onPressed: () {
                                if (mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                                    (_) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              ),
                              child: Text(localizations.continueButton, style: const TextStyle(color: lightColor, fontSize: 18)),
                            ),
                            const Spacer(),
                          ] else if (!_isLinked) ...[
                             const Spacer(),
                             FutureBuilder<bool>(
                               future: _prefsService.getOfflineMode(),
                               builder: (context, snapshot) {
                                 if (snapshot.hasData && snapshot.data == true) {
                                   return Column(
                                     children: [
                                       const Icon(Icons.cloud_off, color: accentColor1, size: 80),
                                       const SizedBox(height: 24),
                                       Text(
                                         localizations.offlineMode,
                                         textAlign: TextAlign.center,
                                         style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightColor),
                                       ),
                                       const SizedBox(height: 16),
                                       Text(
                                         localizations.offlineModeDescription,
                                         textAlign: TextAlign.center,
                                         style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 16),
                                       ),
                                     ],
                                   );
                                 } else {
                                   return Column(
                                     children: [
                                       Text(
                                         localizations.linkDevice,
                                         textAlign: TextAlign.center,
                                         style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: lightColor),
                                       ),
                                       const SizedBox(height: 24),
                                       TextField(
                                         controller: _codeController,
                                         style: const TextStyle(color: lightColor),
                                         decoration: InputDecoration(
                                           labelText: localizations.enterCode,
                                           labelStyle: TextStyle(color: lightColor.withOpacity(0.7)),
                                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                       const SizedBox(height: 12),
                                       TextField(
                                         controller: _deviceNameController,
                                         style: const TextStyle(color: lightColor),
                                         decoration: InputDecoration(
                                           labelText: localizations.deviceNameOptional,
                                           labelStyle: TextStyle(color: lightColor.withOpacity(0.7)),
                                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                                       const SizedBox(height: 24),
                                       ElevatedButton(
                                         onPressed: _isLoading ? null : _linkDevice,
                                         style: ElevatedButton.styleFrom(
                                           backgroundColor: primaryColor,
                                           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                         ),
                                         child: Text(localizations.linkDevice, style: const TextStyle(color: lightColor, fontSize: 18)),
                                       ),
                                     ],
                                   );
                                 }
                               },
                             ),
                            const Spacer(),
                          ] else ...[
                            const SizedBox(height: 24),
                            // Linked View
                            Card(
                              color: primaryColor,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                        child: Text(
                                          _currentDeviceName.isNotEmpty ? _currentDeviceName : localizations.deviceIsLinked,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lightColor),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, color: lightColor, size: 20),
                                        onPressed: _showEditDeviceNameDialog,
                                        tooltip: localizations.changeDeviceName,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _showUnlinkConfirmationDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor1,
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                ),
                                child: Text(localizations.unlinkDevice, style: const TextStyle(color: lightColor, fontSize: 16)),
                              ),
                            ),
                            const Spacer(),
                          ],
                          if (_isLinked && !_showContinueButton) ...[
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
    );
  }
}
