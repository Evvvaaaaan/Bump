import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final Function() onPhoneShake;
  final double shakeThresholdGravity;
  final int minTimeBetweenShakes;
  final int shakeCountResetTime;
  final int minShakeCount;

  int _shakeCount = 0;
  int _lastShakeTimestamp = 0;
  StreamSubscription<UserAccelerometerEvent>? _streamSubscription;

  ShakeDetector({
    required this.onPhoneShake,
    this.shakeThresholdGravity = 2.7,
    this.minTimeBetweenShakes = 1000,
    this.shakeCountResetTime = 3000,
    this.minShakeCount = 1,
  });

  void startListening() {
    _streamSubscription = userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      double gX = event.x / 9.8;
      double gY = event.y / 9.8;
      double gZ = event.z / 9.8;

      // gForce will be close to 1 when there is no movement.
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > shakeThresholdGravity) {
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Ignore if too close to last shake
        if (_lastShakeTimestamp + minTimeBetweenShakes > now) {
          return;
        }

        // Reset count if too much time passed
        if (_lastShakeTimestamp + shakeCountResetTime < now) {
          _shakeCount = 0;
        }

        _lastShakeTimestamp = now;
        _shakeCount++;

        if (_shakeCount >= minShakeCount) {
          _shakeCount = 0;
          onPhoneShake();
        }
      }
    });
  }

  void stopListening() {
    _streamSubscription?.cancel();
  }
}
