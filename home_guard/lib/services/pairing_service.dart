import 'dart:typed_data';
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../screens/protocol/smart_device_protocol.dart';
import 'bluetooth_manager.dart';
import 'pairing/homeguard_qr_payload.dart';

class PairingService {
  PairingService._internal();

  static final PairingService instance = PairingService._internal();

  final _storage = const FlutterSecureStorage();

  // Use X25519 for ECDH
  final X25519 _ecdh = X25519();
  final Hkdf _hkdf = Hkdf(
    hmac: Hmac.sha256(), outputLength: 32,
  );

  /// 1) Parse QR
  /// 2) Do ECDH + HKDF to derive session key
  /// 3) Store per-device key in secure storage
  /// 4) Optionally connect via BLE and do a test ping
  Future<void> pairFromQr(String rawQr) async {
    final payload = HomeGuardQrPayload.fromRawQr(rawQr);

    // 1. Generate ephemeral app key pair
    final appKeyPair = await _ecdh.newKeyPair();
    final appPublicKey = await appKeyPair.extractPublicKey();

    // 2. ECDH -> shared secret
    final sharedSecretKey = await _ecdh.sharedSecretKey(
      keyPair: appKeyPair,
      remotePublicKey: payload.devicePublicKey,
    );

    final sharedSecretBytes = await sharedSecretKey.extractBytes();

    // 3. HKDF to derive session key
    final sessionSecretKey = await _hkdf.deriveKey(
      secretKey: sharedSecretKey,
      nonce: const [], // or a salt from QR / firmware if you want
      info: utf8.encode('HomeGuard-Session-v1')
    );

    final sessionKeyBytes = await sessionSecretKey.extractBytes();

    // Store key in secure storage as base64
    final sessionKeyB64 = base64Encode(sessionKeyBytes);

    await _storage.write(
      key: 'device_session_key_${payload.deviceId}',
      value: sessionKeyB64,
    );

    // TODO: store appPublicKey if device needs it (e.g. you send it over BLE)
    final appPubKeyBytes = (appPublicKey as SimplePublicKey).bytes;
    final appPubKeyB64 = base64Encode(appPubKeyBytes);
    await _storage.write(
      key: 'device_app_pub_${payload.deviceId}',
      value: appPubKeyB64,
    );

    // 4. Optional: connect via BLE and send appPublicKey to device
    //    (Device uses it to compute the same shared secret).
    if (payload.btIdentifier != null) {
      await _connectAndSendPublicKey(
        btIdentifier: payload.btIdentifier!,
        appPublicKeyBytes: appPubKeyBytes,
        deviceId: payload.deviceId,
        sessionSecretKey: sessionSecretKey,
      );
    }
  }

  Future<void> _connectAndSendPublicKey({
    required String btIdentifier,
    required List<int> appPublicKeyBytes,
    required String deviceId,
    required SecretKey sessionSecretKey,
  }) async {
    // Simple example: scan until we see a device with matching ID/name.
    final bluetooth = BluetoothManager.instance;

    await bluetooth.startScan(timeout: const Duration(seconds: 5));

    final scanResult = await bluetooth.scanResults
        .firstWhere((results) => results.any((r) {
      // match by device name or ID; adjust to your actual logic
      return r.device.platformName.contains(btIdentifier) ||
          r.device.remoteId.str == btIdentifier;
    }));

    await bluetooth.stopScan();

    final device = scanResult.firstWhere((r) {
      return r.device.platformName.contains(btIdentifier) ||
          r.device.remoteId.str == btIdentifier;
    }).device;

    await bluetooth.connectToDevice(device);

    // You must define these UUIDs to match your ESP32 firmware
    final serviceUuid = Guid('0000ffff-0000-1000-8000-00805f9b34fb');
    final characteristicUuid = Guid('0000ff01-0000-1000-8000-00805f9b34fb');

    final protocol = EcdhSessionProtocol(sessionSecretKey);

    // Example: send our public key as plaintext (not encrypted yet),
    // depending on your handshake design:
    //
    // - Option A: first message is appPubKey as plaintext
    // - Option B: pre-defined handshake frame
    //
    // Here: we send plain appPublicKey; you can change this to match firmware.
    await bluetooth.sendEncrypted(
      device,
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      protocol: protocol,
      plainPayload: Uint8List.fromList(appPublicKeyBytes),
    );

    // Optional: read a response, decrypt, etc.

    await bluetooth.disconnectDevice(device);
  }

  /// Later, when you need to talk to a device, load the session key:
  Future<SmartDeviceProtocol> getProtocolForDevice(String deviceId) async {
    final b64 = await _storage.read(key: 'device_session_key_$deviceId');
    if (b64 == null) {
      throw StateError('No session key stored for device $deviceId');
    }
    final bytes = Uint8List.fromList(base64Decode(b64));
    final secretKey = SecretKey(bytes);
    return EcdhSessionProtocol(secretKey);
  }
}
