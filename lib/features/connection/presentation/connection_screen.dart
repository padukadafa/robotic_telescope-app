import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/connection_provider.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.wifi_tethering,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Telescope Connection',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Connect to your robotic telescope via WiFi',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Scan Button
                  Center(
                    child: AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              stops: [0.0, _scanAnimation.value, 1.0],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: provider.scanForTelescopes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(40),
                              elevation: 8,
                              shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_find,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Scan Networks',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Available Networks
                  if (provider.availableNetworks.isNotEmpty) ...[
                    Text(
                      'Available Telescopes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.availableNetworks.length,
                        itemBuilder: (context, index) {
                          final network = provider.availableNetworks[index];
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
                                onPressed: () => _showPasswordDialog(context, network, provider),
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
                        },
                      ),
                    ),
                  ],

                  // Connection Status
                  if (provider.isConnected) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.2),
                            Colors.green.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connected Successfully',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'Connected to ${provider.connectedNetwork}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: provider.disconnect,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Disconnect'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPasswordDialog(BuildContext context, String ssid, ConnectionProvider provider) {
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Connect to $ssid',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: passwordController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.connectToTelescope(ssid, passwordController.text);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}