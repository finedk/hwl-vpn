import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return '${androidInfo.manufacturer} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.name;
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await _deviceInfo.windowsInfo;
      return windowsInfo.computerName;
    }
    return 'Unknown Device';
  }

  Future<String> getFingerprint() async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id; // androidId
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown-ios-id';
    } else if (Platform.isWindows) {
      WindowsDeviceInfo windowsInfo = await _deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    }
    return 'unknown-fingerprint';
  }
}