import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  PermissionsService._();

  static final PermissionsService instance = PermissionsService._();

  Future<void> requestCorePermissions() async {
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      await _requestIosPermissions();
    }
  }

  Future<void> _requestAndroidPermissions() async {
    // Camera for QR scanning
    await Permission.camera.request();

    // Bluetooth permissions (Android 12+)
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();

    // Some devices/versions still require location for BLE scanning
    await Permission.locationWhenInUse.request();
  }

  Future<void> _requestIosPermissions() async {
    await Permission.camera.request();
    await Permission.bluetooth.request();
  }
}
