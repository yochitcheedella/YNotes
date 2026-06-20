import 'dart:async';
import 'package:flutter/material.dart';

class AutoLockService {
  static final AutoLockService instance = AutoLockService._internal();
  AutoLockService._internal();

  DateTime? _lastInteractionTime;
  Duration _lockDuration = const Duration(minutes: 1); // default
  Timer? _timer;
  VoidCallback? _onLockTriggered;
  bool _isLocked = false;

  void initialize({
    required Duration initialDuration,
    required VoidCallback onLockTriggered,
  }) {
    _lockDuration = initialDuration;
    _onLockTriggered = onLockTriggered;
    _isLocked = false;
    recordInteraction();
    _startTimer();
  }

  void updateDuration(Duration newDuration) {
    _lockDuration = newDuration;
    recordInteraction();
    _startTimer();
  }

  void recordInteraction() {
    _lastInteractionTime = DateTime.now();
  }

  bool get isLocked => _isLocked;

  void lock() {
    _isLocked = true;
    _timer?.cancel();
    if (_onLockTriggered != null) {
      _onLockTriggered!();
    }
  }

  void unlock() {
    _isLocked = false;
    recordInteraction();
    _startTimer();
  }

  void pause() {
    // When app goes to background, check if we need to lock immediately or if it's already idle
    _timer?.cancel();
  }

  void resume() {
    // When app comes back to foreground, check if it stayed in background longer than the timeout
    if (_lastInteractionTime != null) {
      final elapsed = DateTime.now().difference(_lastInteractionTime!);
      if (elapsed >= _lockDuration) {
        lock();
      } else {
        _startTimer();
      }
    } else {
      lock();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_isLocked) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_lastInteractionTime != null) {
        final elapsed = DateTime.now().difference(_lastInteractionTime!);
        if (elapsed >= _lockDuration) {
          lock();
        }
      }
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
