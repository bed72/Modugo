import 'package:modugo/src/routes/paths/parse.dart';
import 'package:modugo/src/routes/paths/regexp.dart';
import 'package:modugo/src/routes/paths/function.dart';
import 'package:modugo/src/routes/paths/extract.dart' as ex;

final class CompilerRoute {
  final String pattern;
  final List<String> _parameters = [];

  late final _tokens = parse(pattern, parameters: _parameters);
  late final _regExp = tokensToRegExp(_tokens);
  late final _builder = tokensToFunction(_tokens);

  CompilerRoute(this.pattern);

  bool match(String path) => _regExp.hasMatch(path);

  Map<String, String>? extract(String path) {
    final match = _regExp.matchAsPrefix(path);
    if (match == null) return null;
    return ex.extract(_parameters, match);
  }

  String build(Map<String, String> args) => _builder(args);

  RegExp get regExp => _regExp;

  List<String> get parameters => List.unmodifiable(_parameters);
}
