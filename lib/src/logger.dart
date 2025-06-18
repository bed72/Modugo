// coverage:ignore-file
// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:modugo/src/modugo.dart';

/// A simple logging utility used internally by Modugo.
///
/// Provides multiple logging methods corresponding to different severity levels,
/// each prepending a timestamp, emoji, and tag to messages.
///
/// Logging output is colored for readability in terminals that support ANSI colors.
///
/// Logging can be globally enabled or disabled via [enabled] and
/// respects the [Modugo.debugLogDiagnostics] flag.
///
/// Example usage:
/// ```dart
/// Logger.info('Module loaded');
/// Logger.error('Failed to register bind');
/// ```
final class Logger {
  /// Enables or disables all logging output globally.
  ///
  /// Default is `true`.
  static bool enabled = true;

  /// Core method that logs a message with optional [emoji], [tag], and [level].
  ///
  /// Respects [enabled] and [Modugo.debugLogDiagnostics] to conditionally output logs.
  ///
  /// Outputs the message to standard output with colored formatting.
  static void log(
    String message, {
    String emoji = '',
    String tag = 'Modugo',
    _LogLevel level = _LogLevel.info,
  }) {
    if (!enabled || !Modugo.debugLogDiagnostics) return;

    final timestamp = _now();
    final coloredMessage = _colorize(
      level,
      '[$timestamp] $emoji [$tag] $message',
    );
    stdout.writeln(coloredMessage);
  }

  /// Logs an informational message (green text).
  static void info(String message, {String tag = 'INFO'}) =>
      log(message, tag: tag, emoji: ' 👀 ', level: _LogLevel.info);

  /// Logs an error message (red text).
  static void error(String message, {String tag = 'ERROR'}) =>
      log(message, tag: tag, emoji: ' ❌ ', level: _LogLevel.error);

  /// Logs a warning message (yellow text).
  static void warn(String message, {String tag = 'WARN'}) =>
      log(message, tag: tag, emoji: ' 😟 ', level: _LogLevel.warn);

  /// Logs a navigation-related message (blue text).
  static void navigation(String message, {String tag = 'NAV'}) =>
      log(message, tag: tag, emoji: ' 🧭 ', level: _LogLevel.trace);

  /// Logs a dispose-related message (magenta text).
  static void dispose(String message, {String tag = 'DISPOSE'}) =>
      log(message, tag: tag, emoji: ' 🗑️ ', level: _LogLevel.fatal);

  /// Logs an injection-related message (orange text).
  static void injection(String message, {String tag = 'INJECT'}) =>
      log(message, tag: tag, emoji: ' 💉 ', level: _LogLevel.debug);

  /// Returns the current time as a formatted string `HH:mm:ss`.
  static String _now() {
    final now = DateTime.now();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';
  }

  /// Wraps the [message] in ANSI color codes based on the [level].
  ///
  /// Supports colors:
  /// - info: green
  /// - warn: yellow
  /// - trace: blue
  /// - error: red
  /// - debug: orange
  /// - fatal: magenta
  static String _colorize(_LogLevel level, String message) {
    final colorCode = switch (level) {
      _LogLevel.info => '\x1B[32m',
      _LogLevel.warn => '\x1B[93m',
      _LogLevel.trace => '\x1B[34m',
      _LogLevel.error => '\x1B[31m',
      _LogLevel.debug => '\x1B[33m',
      _LogLevel.fatal => '\x1B[35m',
    };
    const reset = '\x1B[0m';
    return '$colorCode$message$reset';
  }
}

/// Defines the severity levels used by [Logger].
enum _LogLevel { info, trace, error, debug, fatal, warn }
