import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'notification_service.dart';

class AccelerometerService {
  static StreamSubscription? _subscription;
  static Timer? _inactivityTimer;
  static DateTime? _lastMovementTime;

  // Threshold for detecting movement (adjust if too sensitive)
  static const double _movementThreshold = 1.5;

  static const Duration _inactivityDuration = Duration(minutes: 30);

  static void start() {
    _lastMovementTime = DateTime.now();
    _startInactivityTimer();

    _subscription = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z,
      );

      // 9.8 is gravity — subtract it to get actual movement
      final movement = (magnitude - 9.8).abs();

      if (movement > _movementThreshold) {
        // User is moving — reset the timer
        _lastMovementTime = DateTime.now();
        _resetInactivityTimer();
      }
    });

    print('✅ Accelerometer service started');
  }

  static void _startInactivityTimer() {
    _inactivityTimer = Timer.periodic(
      const Duration(minutes: 5), 
      (_) => _checkInactivity(),
    );
  }

  static void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
  }

  static void _checkInactivity() {
    if (_lastMovementTime == null) return;

    final timeSinceMovement =
        DateTime.now().difference(_lastMovementTime!);

    if (timeSinceMovement >= _inactivityDuration) {
      print('🌿 User inactive for ${timeSinceMovement.inMinutes} minutes — sending wellness prompt');
      NotificationService.showWellnessPrompt();

      // Reset so we don't spam notifications
      _lastMovementTime = DateTime.now();
    }
  }

  static void stop() {
    _subscription?.cancel();
    _inactivityTimer?.cancel();
    _subscription = null;
    _inactivityTimer = null;
    print('⛔ Accelerometer service stopped');
  }
}