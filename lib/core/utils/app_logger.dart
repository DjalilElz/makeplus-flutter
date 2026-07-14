// lib/core/utils/app_logger.dart

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger.
///
/// Everything here is a no-op in release builds. API responses, JWTs and user
/// emails flow through these calls, so they must never reach a production
/// device log. Use this instead of `print()`.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  /// Debug / trace. Stripped in release.
  static void d(dynamic message) {
    if (kDebugMode) _logger.d(message);
  }

  /// Notable but expected events. Stripped in release.
  static void i(dynamic message) {
    if (kDebugMode) _logger.i(message);
  }

  /// Recoverable problems. Stripped in release.
  static void w(dynamic message) {
    if (kDebugMode) _logger.w(message);
  }

  /// Failures. Stripped in release — wire a crash reporter here if one is added.
  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
