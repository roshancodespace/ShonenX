import 'package:shonenx/source_engine/dsl_engine/dsl_context.dart';
import 'package:shonenx/source_engine/dsl_engine/helper_registry.dart';

abstract class ASTNode {
  Future<dynamic> evaluate(ExecutionContext context, HelperRegistry helpers);
}

class LiteralNode extends ASTNode {
  final dynamic value;
  LiteralNode(this.value);

  @override
  Future<dynamic> evaluate(
    ExecutionContext context,
    HelperRegistry helpers,
  ) async => value;

  @override
  String toString() => 'Literal($value)';
}

class VariableNode extends ASTNode {
  final String name;
  VariableNode(this.name);

  @override
  Future<dynamic> evaluate(
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    if (name == 'lastOutput') {
      return context.lastOutput;
    }
    if (name.contains('.')) {
      final parts = name.split('.');
      dynamic current = context.getVariable(parts[0]);
      for (var i = 1; i < parts.length; i++) {
        if (current is Map) {
          current = current[parts[i]];
        } else if (current is List) {
          final idx = int.tryParse(parts[i]);
          if (idx != null && idx >= 0 && idx < current.length) {
            current = current[idx];
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      return current;
    }
    return context.getVariable(name);
  }

  @override
  String toString() => 'Variable($name)';
}

class CallNode extends ASTNode {
  final String functionName;
  final List<ASTNode> arguments;
  CallNode(this.functionName, this.arguments);

  @override
  Future<dynamic> evaluate(
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final evaluatedArgs = <dynamic>[];
    for (final arg in arguments) {
      evaluatedArgs.add(await arg.evaluate(context, helpers));
    }
    return await helpers.execute(functionName, evaluatedArgs, context);
  }

  @override
  String toString() => 'Call($functionName, $arguments)';
}

enum TokenType {
  identifier,
  string,
  number,
  boolean,
  lparen,
  rparen,
  comma,
  eof,
}

class Token {
  final TokenType type;
  final String value;
  Token(this.type, this.value);

  @override
  String toString() => 'Token(${type.name}, "$value")';
}

class Tokenizer {
  final String input;
  int _position = 0;

  Tokenizer(this.input);

  List<Token> tokenize() {
    final tokens = <Token>[];
    while (_position < input.length) {
      final char = input[_position];

      if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
        _position++;
        continue;
      }

      if (char == '(') {
        tokens.add(Token(TokenType.lparen, '('));
        _position++;
        continue;
      }

      if (char == ')') {
        tokens.add(Token(TokenType.rparen, ')'));
        _position++;
        continue;
      }

      if (char == ',') {
        tokens.add(Token(TokenType.comma, ','));
        _position++;
        continue;
      }

      // String literal
      if (char == "'" || char == '"') {
        final quote = char;
        _position++;
        final start = _position;
        while (_position < input.length && input[_position] != quote) {
          // support escaping
          if (input[_position] == '\\' && _position + 1 < input.length) {
            _position += 2;
          } else {
            _position++;
          }
        }
        final val = input.substring(start, _position);
        if (_position < input.length) _position++; // consume closing quote
        tokens.add(Token(TokenType.string, val));
        continue;
      }

      // Number literal
      if (RegExp(r'[0-9]').hasMatch(char)) {
        final start = _position;
        while (_position < input.length &&
            RegExp(r'[0-9\.]').hasMatch(input[_position])) {
          _position++;
        }
        tokens.add(Token(TokenType.number, input.substring(start, _position)));
        continue;
      }

      // Identifier / Keyword / Boolean
      if (RegExp(r'[a-zA-Z_]').hasMatch(char)) {
        final start = _position;
        while (_position < input.length &&
            RegExp(r'[a-zA-Z0-9_\.]').hasMatch(input[_position])) {
          _position++;
        }
        final val = input.substring(start, _position);
        if (val == 'true' || val == 'false') {
          tokens.add(Token(TokenType.boolean, val));
        } else {
          tokens.add(Token(TokenType.identifier, val));
        }
        continue;
      }

      throw Exception('Unexpected character "$char" at position $_position');
    }
    tokens.add(Token(TokenType.eof, ''));
    return tokens;
  }
}

class ExpressionParser {
  final List<Token> tokens;
  int _index = 0;

  ExpressionParser(this.tokens);

  Token get _current => tokens[_index];

  void _consume(TokenType type) {
    if (_current.type == type) {
      _index++;
    } else {
      throw Exception(
        'Expected token ${type.name} but got ${_current.type.name} at index $_index',
      );
    }
  }

  ASTNode parse() {
    final node = _parsePrimary();
    if (_current.type != TokenType.eof) {
      throw Exception('Unexpected tokens trailing after expression');
    }
    return node;
  }

  ASTNode _parsePrimary() {
    final token = _current;
    if (token.type == TokenType.string) {
      _index++;
      return LiteralNode(token.value);
    }
    if (token.type == TokenType.number) {
      _index++;
      final val = num.tryParse(token.value);
      return LiteralNode(val ?? 0);
    }
    if (token.type == TokenType.boolean) {
      _index++;
      return LiteralNode(token.value == 'true');
    }
    if (token.type == TokenType.identifier) {
      _index++;
      if (_current.type == TokenType.lparen) {
        _index++; // consume '('
        final args = <ASTNode>[];
        if (_current.type != TokenType.rparen) {
          args.add(_parsePrimary());
          while (_current.type == TokenType.comma) {
            _index++; // consume ','
            args.add(_parsePrimary());
          }
        }
        _consume(TokenType.rparen);
        return CallNode(token.value, args);
      }
      return VariableNode(token.value);
    }
    throw Exception('Unexpected primary token: ${token.toString()}');
  }
}

class ExpressionEvaluator {
  static ASTNode parse(String expr) {
    final tokenizer = Tokenizer(expr);
    final parser = ExpressionParser(tokenizer.tokenize());
    return parser.parse();
  }

  static Future<dynamic> evaluate(
    String expr,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final ast = parse(expr);
    return await ast.evaluate(context, helpers);
  }

  static Future<dynamic> evaluateTemplate(
    dynamic value,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    if (value is String) {
      if (value.startsWith('{{') &&
          value.endsWith('}}') &&
          !value.substring(2, value.length - 2).contains('{{')) {
        // Direct expression evaluation (retains primitive type return values like List/Map/bool/num)
        final expr = value.substring(2, value.length - 2).trim();
        return await evaluate(expr, context, helpers);
      }
      // String interpolation template
      final pattern = RegExp(r'\{\{(.*?)\}\}');
      final matches = pattern.allMatches(value);
      if (matches.isEmpty) return value;

      String result = value;
      // Evaluate right-to-left to not invalidate offsets
      final list = matches.toList();
      for (var i = list.length - 1; i >= 0; i--) {
        final m = list[i];
        final expr = m.group(1)!.trim();
        final evaluated = await evaluate(expr, context, helpers);
        result = result.replaceRange(
          m.start,
          m.end,
          evaluated?.toString() ?? '',
        );
      }
      return result;
    }
    if (value is Map) {
      final evaluatedMap = <dynamic, dynamic>{};
      for (final entry in value.entries) {
        evaluatedMap[entry.key] = await evaluateTemplate(
          entry.value,
          context,
          helpers,
        );
      }
      return evaluatedMap;
    }
    if (value is List) {
      final evaluatedList = <dynamic>[];
      for (final item in value) {
        evaluatedList.add(await evaluateTemplate(item, context, helpers));
      }
      return evaluatedList;
    }
    return value;
  }
}
