// coverage:ignore-file

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'package:modugo/src/modugo.dart';

final class ModugoLogger {
  static bool enabled = true;

  static final Logger _logger = Logger(
    level: Level.all,
    printer: _ModugoPrettyPrinter(),
  );

  static void log(
    String message, {
    String emoji = '',
    String tag = 'Modugo',
    Level level = Level.info,
  }) {
    if (!enabled || !Modugo.debugLogDiagnostics) return;

    final formatted = '$emoji [$tag] $message';
    _logger.log(level, formatted);
  }

  static void info(String message, {String tag = 'INFO'}) =>
      log(message, tag: tag, emoji: '👀', level: Level.info);

  static void error(String message, {String tag = 'ERROR'}) =>
      log(message, tag: tag, emoji: '❌', level: Level.error);

  static void warn(String message, {String tag = 'WARN'}) =>
      log(message, tag: tag, emoji: '😟', level: Level.warning);

  static void navigation(String message, {String tag = 'NAV'}) =>
      log(message, tag: tag, emoji: '🧭', level: Level.trace);

  static void dispose(String message, {String tag = 'DISPOSE'}) =>
      log(message, tag: tag, emoji: '🗑️', level: Level.fatal);

  static void injection(String message, {String tag = 'INJECT'}) =>
      log(message, tag: tag, emoji: '💉', level: Level.debug);
}

final class _ModugoPrettyPrinter extends LogPrinter {
  final Map<Level, AnsiColor> _levelColors = {
    Level.info: AnsiColor.fg(10),
    Level.trace: AnsiColor.fg(12),
    Level.error: AnsiColor.fg(196),
    Level.debug: AnsiColor.fg(208),
    Level.fatal: AnsiColor.fg(199),
    Level.warning: AnsiColor.fg(208),
  };

  final _timeFormat = DateFormat('HH:mm:ss');

  @override
  List<String> log(LogEvent event) {
    final message = event.message.toString();
    final now = _timeFormat.format(DateTime.now());
    final color = _levelColors[event.level] ?? AnsiColor.none();

    return ['${color('[$now]')} ${color(message)}'];
  }
}
