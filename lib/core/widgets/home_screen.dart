import 'package:flutter/material.dart';
import 'package:robotic_telescope/features/connection/presentation/connection_screen.dart';
import 'package:robotic_telescope/features/object_selection/presentation/object_selection_screen.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/telescope_control_screen.dart';
import 'package:robotic_telescope/features/monitoring/presentation/monitoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ObjectSelectionScreen(),
    const TelescopeControlScreen(),
    const MonitoringScreen(),
  ];

  final List<String> _titles = ['Objects', 'Control', 'Monitoring'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search, size: 28),
                label: 'Objects',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.control_camera),
                activeIcon: Icon(Icons.control_camera, size: 28),
                label: 'Control',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor),
                activeIcon: Icon(Icons.monitor, size: 28),
                label: 'Monitor',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
