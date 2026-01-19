import 'package:flutter/material.dart';
import 'package:robotic_telescope/features/callibration/callibration_screen.dart';
import 'package:robotic_telescope/features/waterpass/waterpass_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan'), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'Sensor',
            items: [
              _SettingsItem(
                icon: Icons.tune,
                title: 'Kalibrasi Sensor',
                subtitle: 'Kalibrasi gyro dan kompas',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CallibrationScreen(),
                    ),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.water_drop_outlined,
                title: 'Lihat Waterpass',
                subtitle: 'Monitor level teleskop secara real-time',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WaterpassScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Tentang',
            items: [
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'Versi Aplikasi',
                subtitle: '1.0.0',
                onTap: () {},
                showChevron: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});

  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            )
          : null,
      onTap: onTap,
    );
  }
}
