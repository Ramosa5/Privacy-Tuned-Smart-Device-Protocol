import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  BluetoothManager._();
  static final BluetoothManager instance = BluetoothManager._();

  StreamSubscription<List<ScanResult>>? _scanSub;
  final StreamController<List<ScanResult>> _espResultsController =
  StreamController.broadcast();

  /// Stream wyników (już przefiltrowanych na ESP/ESP32/HomeGuard).
  Stream<List<ScanResult>> get espScanResults => _espResultsController.stream;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  final Map<String, ScanResult> _resultsById = {};

  bool _isLikelyEsp32(ScanResult r) {
    final name = r.device.platformName.trim();
    if (name.isEmpty) return false;
    final upper = name.toUpperCase();
    return upper.contains('ESP32') ||
        upper.contains('ESP') ||
        upper.contains('HOMEGUARD');
  }

  Future<void> startEspScan({Duration timeout = const Duration(seconds: 6)}) async {
    // wyczyść stare wyniki
    _resultsById.clear();
    _isScanning = true;
    _emit();

    // słuchaj wyników
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (_isLikelyEsp32(r)) {
          _resultsById[r.device.remoteId.str] = r;
        }
      }
      _emit();
    });

    // uruchom skan
    await FlutterBluePlus.startScan(timeout: timeout);

    // po timeout skan sam się kończy
    _isScanning = false;
    _emit();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    _emit();
  }

  Future<BluetoothDevice> connect(ScanResult result,
      {Duration timeout = const Duration(seconds: 12)}) async {
    final device = result.device;
    await device.connect(timeout: timeout, autoConnect: false);
    return device;
  }

  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }

  void _emit() {
    final list = _resultsById.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    _espResultsController.add(list);
  }

  void dispose() {
    _scanSub?.cancel();
    _espResultsController.close();
  }
}
