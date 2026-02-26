import 'package:get_it/get_it.dart';
import 'package:robotic_telescope/core/services/telescope_websocket_manager.dart';
import 'package:robotic_telescope/core/services/telescope_dummy_service.dart';
import 'package:robotic_telescope/core/services/stepper_motor_controller.dart';
import 'package:robotic_telescope/core/services/database_helper.dart';
import 'package:robotic_telescope/core/dao/astronomical_object_dao.dart';
import 'package:robotic_telescope/core/services/astronomical_detection_service.dart';

final getIt = GetIt.instance;

/// Setup dependency injection
/// Call this once at app startup
void setupServiceLocator() {
  // Register TelescopeWebSocketManager as singleton
  getIt.registerLazySingleton<TelescopeWebSocketManager>(
    () => TelescopeWebSocketManager(),
  );

  // Register TelescopeDummyService as singleton
  getIt.registerLazySingleton<TelescopeDummyService>(
    () => TelescopeDummyService(),
  );

  // Register StepperMotorController as singleton
  getIt.registerLazySingleton<StepperMotorController>(
    () => StepperMotorController(),
  );

  // Register DatabaseHelper as singleton
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  // Register AstronomicalObjectDao as singleton
  getIt.registerLazySingleton<AstronomicalObjectDao>(
    () => AstronomicalObjectDao(getIt<DatabaseHelper>()),
  );

  // Register AstronomicalDetectionService as singleton
  getIt.registerLazySingleton<AstronomicalDetectionService>(
    () => AstronomicalDetectionService(),
  );
}

class Services {
  static TelescopeWebSocketManager get websocket =>
      getIt<TelescopeWebSocketManager>();
  static TelescopeDummyService get dummy => getIt<TelescopeDummyService>();
  static StepperMotorController get stepper => getIt<StepperMotorController>();
  static DatabaseHelper get database => getIt<DatabaseHelper>();
  static AstronomicalObjectDao get objectDao => getIt<AstronomicalObjectDao>();
  static AstronomicalDetectionService get astronomicalDetection =>
      getIt<AstronomicalDetectionService>();
}
