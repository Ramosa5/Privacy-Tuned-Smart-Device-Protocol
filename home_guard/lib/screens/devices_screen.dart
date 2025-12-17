import 'package:flutter/material.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final devices = [
      _DeviceMock(name: 'Test List Device', status: 'Online', secure: true),
      // _DeviceMock(name: 'Garage Door ESP32', status: 'Online', secure: true),
      // _DeviceMock(name: 'Backyard Sensor', status: 'Offline', secure: false),
    ];

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
            'Manage your ESP32 and other IoT devices connected via encrypted Bluetooth.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),
          for (final d in devices) _DeviceTile(device: d),
        ],
      ),
    );
  }
}

class _DeviceMock {
  final String name;
  final String status;
  final bool secure;

  _DeviceMock({
    required this.name,
    required this.status,
    required this.secure,
  });
}

class _DeviceTile extends StatelessWidget {
  final _DeviceMock device;

  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = device.status.toLowerCase() == 'online';

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
              color: isOnline
                  ? colorScheme.primary.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.1),
            ),
            child: Icon(
              Icons.memory_rounded,
              color: isOnline ? colorScheme.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
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
                      device.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      device.secure
                          ? Icons.lock_outline_rounded
                          : Icons.lock_open_rounded,
                      size: 14,
                      color: device.secure
                          ? colorScheme.primary
                          : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      device.secure ? 'Encrypted' : 'Unencrypted',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: navigate to device details, send commands via BluetoothManager
            },
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
