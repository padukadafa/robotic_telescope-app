import 'package:flutter/material.dart';
import 'package:robotic_telescope/features/ai_detection/ai_detection_screen.dart';

/// Example: How to navigate to AI Detection Screen
///
/// This file demonstrates how to add AI object detection to your app navigation

class NavigationExample extends StatelessWidget {
  const NavigationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telescope Control')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example 1: Button to navigate to AI Detection
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIDetectionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('AI Object Detection'),
            ),

            const SizedBox(height: 16),

            // Example 2: Card with description
            Card(
              margin: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIDetectionScreen(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 32,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'AI Detection',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Automatically detect and track astronomical objects '
                        'using on-device AI',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Integration with existing wrapper or navigation drawer
///
/// If you have a navigation drawer or bottom navigation, add AI Detection like this:
class NavigationDrawerExample extends StatelessWidget {
  const NavigationDrawerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Telescope Control',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text('Telescope Control'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to telescope control
            },
          ),

          // AI Detection menu item
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('AI Detection'),
            subtitle: const Text('Auto-track objects'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIDetectionScreen(),
                ),
              );
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// Example: Bottom Navigation Bar integration
class BottomNavExample extends StatefulWidget {
  const BottomNavExample({super.key});

  @override
  State<BottomNavExample> createState() => _BottomNavExampleState();
}

class _BottomNavExampleState extends State<BottomNavExample> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Center(child: Text('Control Screen')),
    const AIDetectionScreen(), // AI Detection tab
    const Center(child: Text('Settings Screen')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Control'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'AI Detect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Example: Direct usage with WebSocket
///
/// This shows how to manually control the detection and correction system
class ManualControlExample extends StatefulWidget {
  const ManualControlExample({super.key});

  @override
  State<ManualControlExample> createState() => _ManualControlExampleState();
}

class _ManualControlExampleState extends State<ManualControlExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Control Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('See AI_DETECTION_GUIDE.md for detailed usage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Example: Initialize and use detection programmatically
                _initializeDetection();
              },
              child: const Text('Initialize Detection'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeDetection() async {
    // See AI_DETECTION_GUIDE.md for complete examples
    print('See DetectionProvider API in AI_DETECTION_GUIDE.md');
  }
}
