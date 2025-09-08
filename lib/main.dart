import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/connection_provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/features/connection/presentation/connection_screen.dart';
import 'package:robotic_telescope/features/object_selection/presentation/object_selection_screen.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/telescope_control_screen.dart';
import 'package:robotic_telescope/features/monitoring/presentation/monitoring_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => ObjectProvider()),
        ChangeNotifierProvider(create: (_) => TelescopeProvider()),
      ],
      child: MaterialApp(
        title: 'Robotic Telescope Control',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.dark,
          ),
          fontFamily: 'Inter',
          cardTheme: const CardThemeData(
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ConnectionScreen(),
    const ObjectSelectionScreen(),
    const TelescopeControlScreen(),
    const MonitoringScreen(),
  ];

  final List<String> _titles = [
    'Connection',
    'Objects',
    'Control',
    'Monitoring',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
              color: Colors.black.withOpacity(0.1),
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
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                icon: Icon(Icons.wifi),
                activeIcon: Icon(Icons.wifi, size: 28),
                label: 'Connection',
              ),
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