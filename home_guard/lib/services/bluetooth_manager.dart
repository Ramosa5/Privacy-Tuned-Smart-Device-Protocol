import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../screens/protocol/smart_device_protocol.dart';

class BluetoothManager {
  BluetoothManager._internal();

  static final BluetoothManager instance = BluetoothManager._internal();

  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;

  Stream<List<ScanResult>> get scanResults => _flutterBlue.scanResults;

  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    await _flutterBlue.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    await _flutterBlue.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect(autoConnect: false);
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    await device.disconnect();
  }

  /// Example of sending encrypted payload to an ESP32 characteristic.
  ///
  /// - [device] must already be connected.
  /// - [serviceUuid] and [characteristicUuid] should match your ESP32 firmware.
  Future<void> sendEncrypted(
      BluetoothDevice device, {
        required Guid serviceUuid,
        required Guid characteristicUuid,
        required SmartDeviceProtocol protocol,
        required Uint8List plainPayload,
      }) async {
    // Encrypt with your custom protocol
    final encryptedPayload = await protocol.encrypt(plainPayload);

    // Discover services / characteristics
    final services = await device.discoverServices();
    final targetService = services.firstWhere(
          (s) => s.uuid == serviceUuid,
      orElse: () => throw Exception('Service not found'),
    );

    final characteristic = targetService.characteristics.firstWhere(
          (c) => c.uuid == characteristicUuid,
      orElse: () => throw Exception('Characteristic not found'),
    );

    await characteristic.write(encryptedPayload, withoutResponse: false);
  }

  /// Example of reading + decrypting from a characteristic.
  Future<Uint8List> readDecrypted(
      BluetoothDevice device, {
        required Guid serviceUuid,
        required Guid characteristicUuid,
        required SmartDeviceProtocol protocol,
      }) async {
    final services = await device.discoverServices();
    final targetService = services.firstWhere(
          (s) => s.uuid == serviceUuid,
      orElse: () => throw Exception('Service not found'),
    );

    final characteristic = targetService.characteristics.firstWhere(
          (c) => c.uuid == characteristicUuid,
      orElse: () => throw Exception('Characteristic not found'),
    );

    final cipherBytes = Uint8List.fromList(await characteristic.read());
    final plainBytes = await protocol.decrypt(cipherBytes);
    return plainBytes;
  }
}
