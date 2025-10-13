// coverage:ignore-file

import 'dart:developer' as developer;
import 'package:modugo/src/modugo.dart';

/// A simple, dependency-free logger used internally by Modugo.
///
/// This version replaces `talker_logger` by leveraging Dart’s built-in
/// [developer.log] API. It preserves the same static API and log levels.
///
/// Logs are emitted only when [Modugo.debugLogDiagnostics] is `true`.
final class Logger {
  Logger._();

  static const String _defaultTag = 'MODUGO';

  /// Logs an informational message.
  static void information(String message, {String tag = _defaultTag}) =>
      _log(message, level: 'INFO', tag: tag);

  /// Logs a debug message.
  static void debug(String message, {String tag = _defaultTag}) =>
      _log(message, level: 'DEBUG', tag: tag);

  /// Logs an error message.
  static void error(String message, {String tag = _defaultTag}) =>
      _log(message, level: 'ERROR', tag: tag);

  /// Logs a warning message.
  static void warn(String message, {String tag = _defaultTag}) =>
      _log(message, level: 'WARN', tag: tag);

  /// Logs navigation-related messages.
  static void navigation(String message, {String tag = 'NAVIGATION'}) =>
      _log(message, level: 'NAVIGATION', tag: tag);

  /// Logs module-related messages.
  static void module(String message, {String tag = 'MODULE'}) =>
      _log(message, level: 'MODULE', tag: tag);

  /// Logs dependency injection messages.
  static void injection(String message, {String tag = 'INJECT'}) =>
      _log(message, level: 'INJECT', tag: tag);

  /// Logs disposal messages.
  static void dispose(String message, {String tag = 'DISPOSE'}) =>
      _log(message, level: 'DISPOSE', tag: tag);

  /// Internal log method that prints messages only in debug mode.
  static void _log(
    String message, {
    required String level,
    required String tag,
  }) {
    if (!Modugo.debugLogDiagnostics) return;

    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final formatted = '[$formattedTime][$level][$tag] $message';
    developer.log(formatted, name: _defaultTag);
  }
}
