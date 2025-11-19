import 'package:flutter_test/flutter_test.dart';
import 'package:robotic_telescope/core/services/telescope_dummy_service.dart';

void main() {
  group('TelescopeDummyService', () {
    late TelescopeDummyService service;

    setUp(() {
      service = TelescopeDummyService();
      service.start();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize with home position', () {
      expect(service.currentAzimuth, 0.0);
      expect(service.currentElevation, 45.0);
      expect(service.isMoving, false);
      expect(service.isCalibrated, true);
    });

    test('should emit position updates', () async {
      final positions = <Map<String, dynamic>>[];

      service.positionStream.listen((position) {
        positions.add(position);
      });

      // Wait for some position updates
      await Future.delayed(const Duration(milliseconds: 500));

      expect(positions.isNotEmpty, true);
      expect(positions.first['type'], 'position');
      expect(positions.first['azimuth'], isA<double>());
      expect(positions.first['elevation'], isA<double>());
    });

    test('should move to target position', () async {
      final result = await service.moveTo(180, 60);

      expect(result['status'], 'success');
      expect(result['command'], 'goto');
      expect(service.isMoving, true);
      expect(result['targetAzimuth'], 180.0);
      expect(result['targetElevation'], 60.0);
    });

    test('should slew in all directions', () async {
      final upResult = await service.slew('up', steps: 10);
      expect(upResult['status'], 'success');
      expect(upResult['direction'], 'up');

      final downResult = await service.slew('down', steps: 5);
      expect(downResult['status'], 'success');

      final leftResult = await service.slew('left', steps: 15);
      expect(leftResult['status'], 'success');

      final rightResult = await service.slew('right', steps: 20);
      expect(rightResult['status'], 'success');
    });

    test('should stop movement', () async {
      // Start moving
      await service.moveTo(180, 60);
      expect(service.isMoving, true);

      // Stop
      final result = await service.stop();
      expect(result['status'], 'success');
      expect(service.isMoving, false);
    });

    test('should calibrate to home position', () async {
      // Move somewhere
      await service.moveTo(180, 60);

      // Wait a bit for movement
      await Future.delayed(const Duration(milliseconds: 200));

      // Calibrate
      final result = await service.calibrate();

      expect(result['status'], 'success');
      expect(service.currentAzimuth, 0.0);
      expect(service.currentElevation, 45.0);
      expect(service.isCalibrated, true);
    });

    test('should go to home position', () async {
      // Move somewhere
      await service.slew('right', steps: 90);

      // Go home
      final result = await service.goHome();

      expect(result['status'], 'success');
      expect(service.isMoving, true);
    });

    test('should set speed', () async {
      final result = await service.setSpeed(5.0);

      expect(result['status'], 'success');
      expect(result['speed'], 5.0);
    });

    test('should clamp elevation between 0 and 90', () async {
      await service.slew('up', steps: 100); // Try to go beyond 90
      expect(service.currentElevation, lessThanOrEqualTo(90.0));

      await service.moveTo(0, 0);
      await Future.delayed(const Duration(seconds: 1));

      await service.slew('down', steps: 100); // Try to go below 0
      expect(service.currentElevation, greaterThanOrEqualTo(0.0));
    });

    test('should wrap azimuth around 360 degrees', () async {
      await service.slew('right', steps: 370); // Go past 360
      expect(service.currentAzimuth, lessThan(360.0));
      expect(service.currentAzimuth, greaterThanOrEqualTo(0.0));
    });

    test('should emit status updates', () async {
      final statuses = <String>[];

      service.statusStream.listen((status) {
        statuses.add(status);
      });

      await service.moveTo(180, 60);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(statuses.isNotEmpty, true);
    });

    test('should return current position', () {
      final position = service.getPosition();

      expect(position['azimuth'], isA<double>());
      expect(position['elevation'], isA<double>());
      expect(position['moving'], isA<bool>());
      expect(position['calibrated'], isA<bool>());
    });

    test('should return status info', () {
      final status = service.getStatus();

      expect(status['connected'], true);
      expect(status['calibrated'], true);
      expect(status['moving'], false);
      expect(status['mode'], 'dummy');
      expect(status['position'], isA<Map>());
    });
  });
}
