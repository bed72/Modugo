// coverage:ignore-file
// ignore_for_file: library_private_types_in_public_api

import 'package:logger/logger.dart';
import 'package:modugo/src/modugo.dart';

/// A singleton logger used internally by Modugo to output diagnostic
/// messages with customizable formatting and emojis.
///
/// The logger respects the [Modugo.debugLogDiagnostics] flag, so logs will
/// only be emitted when this flag is set to `true`.
///
/// Internally, it uses the `logger` package with a custom [_ModugoPrettyPrinter]
/// to colorize and format output consistently.
///
/// Example usage:
/// ```dart
/// ModugoLogger.info('Module initialized');
/// ModugoLogger.error('Failed to resolve dependency');
/// ```
final class ModugoLogger {
  /// Singleton instance of [ModugoLogger].
  static final ModugoLogger _instance = ModugoLogger._internal();

  /// Factory constructor to return the singleton instance.
  factory ModugoLogger() => _instance;

  /// Internal logger from the `logger` package.
  late final Logger _logger;

  /// Internal constructor that sets up the logger with a custom printer.
  ModugoLogger._internal() {
    _logger = Logger(level: Level.all, printer: _ModugoPrettyPrinter());
  }

  /// Logs a custom message with optional emoji, tag, and log [level].
  ///
  /// If [Modugo.debugLogDiagnostics] is false, the log is suppressed.
  static void log(
    String message, {
    String emoji = '',
    String tag = 'Modugo',
    Level level = Level.info,
  }) {
    if (!Modugo.debugLogDiagnostics) return;

    final fullMessage = '$emoji [$tag] $message';

    final _ = switch (level) {
      Level.info => _instance._logger.i(fullMessage),
      Level.debug => _instance._logger.d(fullMessage),
      Level.error => _instance._logger.e(fullMessage),
      Level.warning => _instance._logger.w(fullMessage),
      _ => _instance._logger.i(fullMessage),
    };
  }

  /// Logs an informational message with 👀 emoji and `INFO` tag.
  static void info(String message, {String tag = 'INFO'}) =>
      log(message, emoji: ' 👀 ', tag: tag, level: Level.info);

  /// Logs a warning message with 😟 emoji and `WARN` tag.
  static void warn(String message, {String tag = 'WARN'}) =>
      log(message, emoji: ' 😟 ', tag: tag, level: Level.warning);

  /// Logs an error message with ❌ emoji and `ERROR` tag.
  static void error(String message, {String tag = 'ERROR'}) =>
      log(message, emoji: ' ❌ ', tag: tag, level: Level.error);

  /// Logs a navigation-related message with 🧭 emoji and `NAV` tag.
  static void navigation(String message, {String tag = 'NAV'}) =>
      log(message, emoji: ' 🧭 ', tag: tag, level: Level.trace);

  /// Logs a disposal-related message with 🗑️ emoji and `DISPOSE` tag.
  static void dispose(String message, {String tag = 'DISPOSE'}) =>
      log(message, emoji: ' 🗑️ ', tag: tag, level: Level.off);

  /// Logs an injection-related message with 💉 emoji and `INJECT` tag.
  static void injection(String message, {String tag = 'INJECT'}) =>
      log(message, emoji: ' 💉 ', tag: tag, level: Level.debug);
}

/// A custom log printer for Modugo that colorizes messages based on level,
/// adds a timestamp, and formats the output consistently.
final class _ModugoPrettyPrinter extends LogPrinter {
  /// Mapping of log levels to ANSI colors.
  final Map<Level, AnsiColor> _levelColors = {
    Level.info: AnsiColor.fg(10),
    Level.trace: AnsiColor.fg(12),
    Level.error: AnsiColor.fg(196),
    Level.debug: AnsiColor.fg(208),
    Level.fatal: AnsiColor.fg(199),
    Level.warning: AnsiColor.fg(208),
  };

  @override
  List<String> log(LogEvent event) {
    final timestamp = _now();
    final message = event.message.toString();
    final color = _levelColors[event.level] ?? AnsiColor.none();

    return ['${color('[$timestamp]')} ${color(message)}'];
  }

  /// Returns current time as a formatted string `HH:mm:ss`.
  String _now() {
    final now = DateTime.now();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';
  }
}
