import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  BluetoothManager._();
  static final BluetoothManager instance = BluetoothManager._();

  // -----------------------
  // Scan results (ESP-ish)
  // -----------------------
  StreamSubscription<List<ScanResult>>? _scanSub;
  final StreamController<List<ScanResult>> _espResultsController =
  StreamController.broadcast();

  /// Stream wyników (przefiltrowanych na ESP/ESP32/HomeGuard, ale NIE odrzuca pustej nazwy).
  Stream<List<ScanResult>> get espScanResults => _espResultsController.stream;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  final Map<String, ScanResult> _resultsById = {};

  // -----------------------
  // Connected devices count
  // -----------------------
  final Map<String, BluetoothDevice> _connectedById = {};
  final StreamController<int> _connectedCountController =
  StreamController<int>.broadcast();

  /// Stream liczby połączonych urządzeń (dla Dashboardu)
  Stream<int> get connectedCountStream => _connectedCountController.stream;

  int get connectedCount => _connectedById.length;
  final StreamController<List<BluetoothDevice>> _connectedDevicesController =
  StreamController<List<BluetoothDevice>>.broadcast();

  Stream<List<BluetoothDevice>> get connectedDevicesStream =>
      _connectedDevicesController.stream;

  List<BluetoothDevice> get connectedDevices =>
      _connectedById.values.toList(growable: false);

  void _emitConnectedDevices() {
    _connectedDevicesController.add(connectedDevices);
  }

  void _emitConnectedCount() {
    _connectedCountController.add(_connectedById.length);
    _emitConnectedDevices();
  }

  /// Łagodny filtr: jeżeli nazwa jest pusta -> nadal pokazuj urządzenie.
  /// (ESP32 bardzo często reklamuje się bez nazwy.)
  bool _isLikelyEsp32(ScanResult r) {
    final name = r.device.platformName.trim();
    if (name.isEmpty) return true; // <--- kluczowa zmiana
    final upper = name.toUpperCase();
    return upper.contains('ESP32') ||
        upper.contains('ESP') ||
        upper.contains('HOMEGUARD');
  }

  Future<void> startEspScan({Duration timeout = const Duration(seconds: 6)}) async {
    _resultsById.clear();
    _isScanning = true;
    _emit();

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (_isLikelyEsp32(r)) {
          _resultsById[r.device.remoteId.str] = r;
        }
      }
      _emit();
    });

    await FlutterBluePlus.startScan(timeout: timeout);

    _isScanning = false;
    _emit();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
    _emit();
  }

  /// Connect + update "connected devices" count.
  /// Count rośnie po udanym połączeniu i spada automatycznie po rozłączeniu.
  Future<BluetoothDevice> connect(
      ScanResult result, {
        Duration timeout = const Duration(seconds: 12),
      }) async {
    final device = result.device;

    await device.connect(timeout: timeout, autoConnect: false);

    // oznacz jako connected
    _connectedById[device.remoteId.str] = device;
    _emitConnectedCount();

    // automatycznie reaguj na zmianę stanu połączenia
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectedById.remove(device.remoteId.str);
        _emitConnectedCount();
      } else if (state == BluetoothConnectionState.connected) {
        _connectedById[device.remoteId.str] = device;
        _emitConnectedCount();
      }
    });

    return device;
  }

  Future<void> disconnect(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } finally {
      _connectedById.remove(device.remoteId.str);
      _emitConnectedCount();
    }
  }

  /// Disconnect all (np. przy wylogowaniu lub zamknięciu aplikacji)
  Future<void> disconnectAll() async {
    final devices = _connectedById.values.toList();
    for (final d in devices) {
      try {
        await d.disconnect();
      } catch (_) {}
    }
    _connectedById.clear();
    _emitConnectedCount();
  }

  void _emit() {
    final list = _resultsById.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    _espResultsController.add(list);
  }

  void dispose() {
    _scanSub?.cancel();
    _espResultsController.close();
    _connectedCountController.close();
    _connectedDevicesController.close();
  }
}
