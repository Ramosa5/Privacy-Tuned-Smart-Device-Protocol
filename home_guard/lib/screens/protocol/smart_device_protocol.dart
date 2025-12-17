import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Abstract protocol – you already had something like this.
abstract class SmartDeviceProtocol {
  Future<Uint8List> encrypt(Uint8List plainBytes);
  Future<Uint8List> decrypt(Uint8List cipherBytes);
}

/// ECDH session protocol using an already-derived session SecretKey.
///
/// We assume:
/// - ECDH + HKDF was done beforehand
/// - This class only handles symmetric encryption/decryption
class EcdhSessionProtocol implements SmartDeviceProtocol {
  final SecretKey _sessionKey;
  final Cipher _cipher = AesGcm.with256bits();
  final Random _random = Random.secure();

  EcdhSessionProtocol(this._sessionKey);

  // Generate a random 12-byte nonce for AES-GCM
  List<int> _randomNonce() {
    final nonce = List<int>.generate(12, (_) => _random.nextInt(256));
    return nonce;
  }

  @override
  Future<Uint8List> encrypt(Uint8List plainBytes) async {
    final nonce = _randomNonce();

    final secretBox = await _cipher.encrypt(
      plainBytes,
      secretKey: _sessionKey,
      nonce: nonce,
    );

    // Frame = nonce (12 bytes) + ciphertext + MAC
    final combined = Uint8List(
      nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );

    combined.setRange(0, nonce.length, nonce);
    combined.setRange(nonce.length, nonce.length + secretBox.cipherText.length,
        secretBox.cipherText);
    combined.setRange(
      nonce.length + secretBox.cipherText.length,
      combined.length,
      secretBox.mac.bytes,
    );

    return combined;
  }

  @override
  Future<Uint8List> decrypt(Uint8List cipherBytes) async {
    const nonceLength = 12;
    const macLength = 16; // AES-GCM MAC size

    if (cipherBytes.length < nonceLength + macLength) {
      throw ArgumentError('Invalid frame');
    }

    final nonce = cipherBytes.sublist(0, nonceLength);
    final cipherText =
    cipherBytes.sublist(nonceLength, cipherBytes.length - macLength);
    final macBytes =
    cipherBytes.sublist(cipherBytes.length - macLength, cipherBytes.length);
    final mac = Mac(macBytes);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final plain = await _cipher.decrypt(
      secretBox,
      secretKey: _sessionKey,
    );

    return Uint8List.fromList(plain);
  }
}
