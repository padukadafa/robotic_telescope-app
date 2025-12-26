import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/widgets/wrapper.dart';
import 'package:robotic_telescope/features/object_selection/provider/object_selection_provider.dart';
import 'package:robotic_telescope/core/widgets/home_screen.dart';
import 'package:robotic_telescope/core/di/service_locator.dart';

void main() {
  // Setup dependency injection
  setupServiceLocator();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TelescopeProvider()),
          ChangeNotifierProvider(create: (_) => ObjectSelectionProvider()),
        ],
        child: const WrapperScreen(),
      ),
    );
  }
}
