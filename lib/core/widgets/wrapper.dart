import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/widgets/home_screen.dart';
import 'package:robotic_telescope/features/callibration/callibration_screen.dart';
import 'package:robotic_telescope/features/connection/presentation/connection_screen.dart';

class WrapperScreen extends StatelessWidget {
  const WrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TelescopeProvider>(
        builder: (context, value, child) {
          if (!value.isConnected) {
            return ConnectionScreen();
          }
          if (!value.isCallibrated) {
            return CallibrationScreen();
          }
          return HomeScreen();
        },
      ),
    );
  }
}
