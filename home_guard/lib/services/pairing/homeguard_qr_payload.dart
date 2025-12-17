import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class HomeGuardQrPayload {
  final String deviceId;
  final SimplePublicKey devicePublicKey;
  final String? btIdentifier;
  final int version;

  HomeGuardQrPayload({
    required this.deviceId,
    required this.devicePublicKey,
    required this.version,
    this.btIdentifier,
  });

  factory HomeGuardQrPayload.fromRawQr(String raw) {
    final uri = Uri.parse(raw);

    if (uri.scheme != 'homeguard' || uri.host != 'pair') {
      throw FormatException('Invalid HomeGuard QR format');
    }

    final did = uri.queryParameters['did'];
    final pkB64 = uri.queryParameters['pk'];
    final bt = uri.queryParameters['bt'];
    final vStr = uri.queryParameters['v'] ?? '1';

    if (did == null || pkB64 == null) {
      throw FormatException('Missing required QR parameters');
    }

    final pkBytes = base64Decode(pkB64);

    // X25519 public key (recommended)
    final publicKey = SimplePublicKey(
      pkBytes,
      type: KeyPairType.x25519,
    );

    final version = int.tryParse(vStr) ?? 1;

    return HomeGuardQrPayload(
      deviceId: did,
      devicePublicKey: publicKey,
      btIdentifier: bt,
      version: version,
    );
  }
}
