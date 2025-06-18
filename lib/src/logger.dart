// coverage:ignore-file
// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:modugo/src/modugo.dart';

final class Logger {
  static bool enabled = true;

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

  static void info(String message, {String tag = 'INFO'}) =>
      log(message, tag: tag, emoji: ' 👀 ', level: _LogLevel.info);

  static void error(String message, {String tag = 'ERROR'}) =>
      log(message, tag: tag, emoji: ' ❌ ', level: _LogLevel.error);

  static void warn(String message, {String tag = 'WARN'}) =>
      log(message, tag: tag, emoji: ' 😟 ', level: _LogLevel.warn);

  static void navigation(String message, {String tag = 'NAV'}) =>
      log(message, tag: tag, emoji: ' 🧭 ', level: _LogLevel.trace);

  static void dispose(String message, {String tag = 'DISPOSE'}) =>
      log(message, tag: tag, emoji: ' 🗑️ ', level: _LogLevel.fatal);

  static void injection(String message, {String tag = 'INJECT'}) =>
      log(message, tag: tag, emoji: ' 💉 ', level: _LogLevel.debug);

  static String _now() {
    final now = DateTime.now();
    twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';
  }

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

enum _LogLevel { info, trace, error, debug, fatal, warn }
