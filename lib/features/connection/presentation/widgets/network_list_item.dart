import 'package:flutter/material.dart';
import 'package:robotic_telescope/core/providers/connection_provider.dart';
import 'package:robotic_telescope/features/connection/presentation/widgets/password_dialog.dart';

class NetworkListItem extends StatelessWidget {
  final String network;
  final ConnectionProvider provider;

  const NetworkListItem({
    super.key,
    required this.network,
    required this.provider,
  });

  void _showPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PasswordDialog(ssid: network, provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.router,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          network,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Robotic Telescope Network',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _showPasswordDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('Connect'),
        ),
      ),
    );
  }
}
