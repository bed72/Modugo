// coverage:ignore-file

import 'dart:io' show stdout;
import 'dart:developer' as developer;

import 'package:modugo/src/modugo.dart';

/// A dependency-free logger for Modugo.
///
/// Prints colored logs to the console and sends structured log
/// messages to the Dart DevTools console via [developer.log].
///
/// Works across Flutter Mobile, Web, and Desktop.
/// Logs appear only when [Modugo.debugLogDiagnostics] is `true`.
final class Logger {
  Logger._();

  static const _defaultTag = 'MODUGO';

  /// Logs informational messages (blue).
  static void information(String message) => _log(message, level: 'INFO');

  /// Logs debug messages (green).
  static void debug(String message) => _log(message, level: 'DEBUG');

  /// Logs warning messages (yellow).
  static void warn(String message) => _log(message, level: 'WARN');

  /// Logs error messages (red).
  static void error(String message) => _log(message, level: 'ERROR');

  /// Logs module-specific messages (cyan).
  static void module(String message, {String tag = 'MODULE'}) =>
      _log(message, level: 'MODULE');

  /// Logs dependency injection messages (green).
  static void injection(String message, {String tag = 'INJECT'}) =>
      _log(message, level: 'INJECT');

  /// Logs disposal messages (gray).
  static void dispose(String message, {String tag = 'DISPOSE'}) =>
      _log(message, level: 'DISPOSE');

  /// Logs navigation messages (cyan).
  static void navigation(String message, {String tag = 'NAVIGATION'}) =>
      _log(message, level: 'NAVIGATION');

  /// Internal logging method with ANSI colors and DevTools support.
  static void _log(String message, {required String level}) {
    if (!Modugo.debugLogDiagnostics) return;

    final now = DateTime.now();
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    final formatted = '[$formattedTime][$level] $message';

    // ANSI colors
    const red = '\x1B[31m';
    const blue = '\x1B[34m';
    const reset = '\x1B[0m';
    const cyan = '\x1B[36m';
    const gray = '\x1B[90m';
    const green = '\x1B[32m';
    const yellow = '\x1B[33m';

    final color = switch (level) {
      'INFO' => blue,
      'ERROR' => red,
      'WARN' => yellow,
      'DEBUG' => green,
      'MODULE' => cyan,
      'DISPOSE' => gray,
      'INJECT' => green,
      'NAVIGATION' => cyan,
      _ => reset,
    };

    try {
      stdout.writeln('$color$formatted$reset');
    } catch (_) {
      // In environments without stdout (e.g. web), silently ignore
    }

    developer.log(formatted, name: _defaultTag);
  }
}
