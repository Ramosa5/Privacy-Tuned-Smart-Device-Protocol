import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            title: 'Bluetooth',
            subtitle: 'Manage permissions & scanning behaviour',
            icon: Icons.bluetooth_rounded,
            colorScheme: colorScheme,
            onTap: () {
              // TODO: open Bluetooth-related settings
            },
          ),
          _SettingsTile(
            title: 'Smart-Device Protocol',
            subtitle: 'Configure your custom encryption settings',
            icon: Icons.lock_person_rounded,
            colorScheme: colorScheme,
            onTap: () {
              // TODO: navigate to protocol config (eg. key mgmt, algorithm, etc.)
            },
          ),
          _SettingsTile(
            title: 'Notifications',
            subtitle: 'Alert preferences & quiet hours',
            icon: Icons.notifications_active_rounded,
            colorScheme: colorScheme,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text(
            'App',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'About HomeGuard',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.info_outline_rounded),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
