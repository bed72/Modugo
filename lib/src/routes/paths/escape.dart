/// A regular expression that matches characters which would alter a capturing group.
///
/// This includes:
/// - `:` → used for named groups
/// - `=` → used for lookaheads
/// - `!` → used for negative lookaheads
///
/// These characters must be escaped to ensure the group remains a regular capturing group.
final _groupRegExp = RegExp(r'[:=!]');

/// Escapes a matched character to preserve it as a literal inside a regex.
///
/// Used internally by [escapeGroup] to prevent transformation of capturing groups.
///
/// Example:
/// ```dart
/// final result = _escape(RegExp(r':').firstMatch(':')!); // → '\:'
/// ```
String _escape(Match match) => '\\${match[0]}';

/// Escapes special characters in a [group] to ensure it remains a **capturing group**.
///
/// This function is designed to prevent regex modifiers like:
/// - `(?:...)` non-capturing groups
/// - `(?=...)` lookaheads
/// - `(?!...)` negative lookaheads
///
/// These patterns are **not allowed** in Modugo's route system because
/// they disrupt the mapping between route parameters and regex groups.
///
/// Example:
/// ```dart
/// final safeGroup = escapeGroup('(?=abc)'); // → '(\?=abc)'
/// ```
String escapeGroup(String group) =>
    group.replaceFirstMapped(_groupRegExp, _escape);
