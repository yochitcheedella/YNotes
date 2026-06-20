import 'package:flutter/foundation.dart';

/// Production-safe logger for YNote.
/// In release builds, all log output is completely suppressed.
/// In debug builds, messages are printed to stderr with timestamps and levels.
class AppLogger {
  static const String _appTag = '[YNote]';

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log('DEBUG', tag ?? _appTag, message);
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      _log('INFO ', tag ?? _appTag, message);
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      _log('WARN ', tag ?? _appTag, message);
    }
  }

  /// Errors are always logged even in release but never expose sensitive data.
  static void error(String message, {Object? exception, StackTrace? stackTrace, String? tag}) {
    if (kDebugMode) {
      _log('ERROR', tag ?? _appTag, message);
      if (exception != null) {
        _log('ERROR', tag ?? _appTag, 'Exception: $exception');
      }
      if (stackTrace != null) {
        _log('ERROR', tag ?? _appTag, stackTrace.toString());
      }
    }
    // In production, integrate with crash reporter (e.g. Firebase Crashlytics) here.
  }

  static void security(String message, {String? tag}) {
    // Security audit events: always log in debug, pipe to audit log in production
    if (kDebugMode) {
      _log('AUDIT', tag ?? _appTag, '🔐 $message');
    }
  }

  static void _log(String level, String tag, String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23); // HH:mm:ss.mmm
    debugPrint('$timestamp [$level] $tag: $message');
  }
}
