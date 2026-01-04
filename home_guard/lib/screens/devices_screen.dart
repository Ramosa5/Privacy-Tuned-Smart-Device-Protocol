import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_manager.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  String _displayName(BluetoothDevice d) {
    final name = d.platformName.trim();
    if (name.isNotEmpty) return name;
    return d.remoteId.str;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Devices',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connected ESP32 and other IoT devices via encrypted Bluetooth.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),

          StreamBuilder<List<BluetoothDevice>>(
            stream: BluetoothManager.instance.connectedDevicesStream,
            initialData: BluetoothManager.instance.connectedDevices,
            builder: (context, snapshot) {
              final devices = snapshot.data ?? const <BluetoothDevice>[];

              if (devices.isEmpty) {
                return _EmptyState(colorScheme: colorScheme);
              }

              return Column(
                children: [
                  for (final d in devices)
                    _DeviceTile(
                      device: d,
                      name: _displayName(d),
                      secure: true, // docelowo masz szyfrowany protokół
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.withOpacity(0.08),
            ),
            child: const Icon(Icons.devices_other_rounded, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No connected devices yet.\nTap + on the Home screen to scan & pair.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatefulWidget {
  final BluetoothDevice device;
  final String name;
  final bool secure;

  const _DeviceTile({
    required this.device,
    required this.name,
    required this.secure,
  });

  @override
  State<_DeviceTile> createState() => _DeviceTileState();
}

class _DeviceTileState extends State<_DeviceTile> {
  bool _disconnecting = false;

  Future<void> _disconnect() async {
    if (_disconnecting) return;

    setState(() => _disconnecting = true);

    try {
      await BluetoothManager.instance.disconnect(widget.device);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnected: ${widget.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnect failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Skoro lista jest z connectedDevicesStream, status jest online
    const isOnline = true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: colorScheme.primary.withOpacity(0.08),
            ),
            child: Icon(
              Icons.memory_rounded,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isOnline ? Icons.circle : Icons.circle_outlined,
                      size: 10,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      widget.secure
                          ? Icons.lock_outline_rounded
                          : Icons.lock_open_rounded,
                      size: 14,
                      color: widget.secure
                          ? colorScheme.primary
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.secure ? 'Encrypted' : 'Unencrypted',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.device.remoteId.str,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // 🔌 Rozłącz
          _disconnecting
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : IconButton(
            tooltip: 'Disconnect',
            onPressed: _disconnect,
            icon: Icon(
              Icons.link_off_rounded,
              color: Colors.redAccent.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
