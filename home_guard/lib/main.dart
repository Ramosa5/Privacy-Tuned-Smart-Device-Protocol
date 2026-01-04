import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/settings_screen.dart';
import 'services/permissions_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'services/bluetooth_manager.dart';

void main() {
  runApp(const HomeGuardApp());
}

class HomeGuardApp extends StatelessWidget {
  const HomeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B7BEC),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
        ),
      ),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    DevicesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 🔐 Ask for camera + Bluetooth (and location if needed) once at startup
    PermissionsService.instance.requestCorePermissions();
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onAddDevicePressed() {
    // FAB is only shown on the main/dashboard screen.
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return const _AddDeviceSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'HomeGuard'
              : _selectedIndex == 1
              ? 'Devices'
              : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other_rounded),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        onPressed: _onAddDevicePressed,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add_rounded),
      )
          : null,
    );
  }
}

class _AddDeviceSheet extends StatelessWidget {
  const _AddDeviceSheet();

  Future<void> _scanAndShowResults(BuildContext context) async {
    // Zamknij ten sheet
    Navigator.pop(context);

    // Otwórz sheet z listą wyników (UI), a scan robi BluetoothManager
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _BleScanSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add IoT Device',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan for nearby ESP32-based devices via Bluetooth Low Energy (BLE).',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _scanAndShowResults(context),
              icon: const Icon(Icons.bluetooth_searching_rounded),
              label: const Text('Scan & Pair'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BleScanSheet extends StatefulWidget {
  const _BleScanSheet();

  @override
  State<_BleScanSheet> createState() => _BleScanSheetState();
}

class _BleScanSheetState extends State<_BleScanSheet> {
  final _bt = BluetoothManager.instance;

  @override
  void initState() {
    super.initState();
    _bt.startEspScan(timeout: const Duration(seconds: 6));
  }

  @override
  void dispose() {
    _bt.stopScan();
    super.dispose();
  }

  Future<void> _connect(ScanResult r) async {
    try {
      final device = await _bt.connect(r);

      if (!mounted) return;
      final name = device.platformName.trim().isEmpty
          ? device.remoteId.str
          : device.platformName;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to: $name')),
      );

      // TODO: tutaj następny krok: handshake / protokół / zapis sparowanego device
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to establish connection: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scanning',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _bt.startEspScan(timeout: const Duration(seconds: 6)),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Scan again',
                ),
              ],
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<ScanResult>>(
              stream: _bt.espScanResults,
              builder: (context, snapshot) {
                final results = snapshot.data ?? const <ScanResult>[];

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _bt.isScanning
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(Icons.check_circle_rounded, color: cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _bt.isScanning
                                  ? 'Looking for devices...'
                                  : 'Found: ${results.length}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (results.isEmpty && !_bt.isScanning)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Nothing there...',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    else
                      SizedBox(
                        height: 360, // aby lista miała miejsce w bottom-sheet
                        child: ListView.separated(
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final r = results[index];
                            final name = r.device.platformName.trim();
                            final displayName =
                            name.isEmpty ? 'Unknown device' : name;

                            return Container(
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.memory_rounded, color: cs.primary),
                                title: Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'RSSI: ${r.rssi} • ${r.device.remoteId.str}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                trailing: const Icon(Icons.link_rounded),
                                onTap: () => _connect(r),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

