// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:args/args.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_style/dart_style.dart';

import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', mandatory: true)
    ..addOption('output', abbr: 'o', mandatory: true);

  final args = parser.parse(arguments);
  var input = args['input'] ?? '';
  var output = args['output'] ?? '';
  if (input.isEmpty || output.isEmpty) {
    print(
      'Usage: dart run gen_msg_resource.dart -i <input_file> -o <output_file>',
    );
    exit(1);
  }
  if (!p.isAbsolute(input)) input = p.absolute(input);
  if (!p.isAbsolute(output)) output = p.absolute(output);

  final inputFile = File(input);
  final outputFile = File(output);
  if (!inputFile.existsSync()) {
    print('❌ Input file not found: $input');
    exit(1);
  }
  try {
    outputFile.parent.createSync(recursive: true);
  } catch (e) {
    print('❌ Failed to create output directory: ${outputFile.parent.path}');
    exit(1);
  }

  final content = inputFile.readAsStringSync();
  final result = parseString(content: content);

  final visitor = _EnumVisitor();
  result.unit.visitChildren(visitor);

  final buffer = StringBuffer()
    ..writeln("// Generated code. DO NOT EDIT.\n")
    ..writeln("// ignore_for_file: non_constant_identifier_names\n")
    ..writeln("import 'package:intl/intl.dart';\n")
    ..writeln("class L10nResource {");

  for (final m in visitor.messages) {
    // Strictly use the keys from the 'param' Map defined in the enum constant.
    // If the message string has more parameters, they are ignored per design.
    final uniqueParams = m.defaultArgs.keys.toList();

    // Generate signature
    final paramDecl = uniqueParams.map((p) => "Object? $p").join(', ');
    final signature = paramDecl.isNotEmpty ? paramDecl : '';
    final sanitizeKey = m.key.replaceAll('.', '_');

    buffer.writeln("  static String $sanitizeKey($signature) {");

    // Move null-safety check OUTSIDE the Intl.message call
    for (final p in uniqueParams) {
      buffer.writeln(
        "    $p = ${m.defaultArgs[p] != null ? "$p ?? '${m.defaultArgs[p]}'" : "$p ?? ''"};",
      );
    }

    buffer.writeln("    return Intl.message(");
    buffer.writeln("      '${m.defaultValue}',");
    // Use ClassName_MethodName to satisfy the intl tool naming requirement
    buffer.writeln("      name: '$sanitizeKey',");

    if (uniqueParams.isNotEmpty) {
      buffer.writeln("      args: [${uniqueParams.join(', ')}],");
      buffer.writeln(
        "      examples: const {${uniqueParams.map((p) => "'$p': '${m.defaultArgs[p] ?? ''}'").join(', ')}},",
      );
    }

    if (m.desc.isNotEmpty) buffer.writeln("      desc: '${m.desc}',");

    buffer.writeln("    );");
    buffer.writeln("  }");
  }

  buffer.writeln("}");

  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );
  outputFile.writeAsStringSync(formatter.format(buffer.toString()));
  print('✅ Generated: ${args['output']}');
}

class MessageDefinition {
  final String name, key, defaultValue, desc;
  final Map<String, Object?> defaultArgs;
  MessageDefinition(
    this.name,
    this.key,
    this.defaultValue,
    this.defaultArgs,
    this.desc,
  );
}

class _EnumVisitor extends RecursiveAstVisitor<void> {
  final List<MessageDefinition> messages = [];

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    final args = node.arguments?.argumentList.arguments;

    // Check if we have at least 3 arguments (code, key, msg, desc)
    if (args != null && args.length > 3) {
      final enumName = node.name.lexeme;
      final key = (args[1] as StringLiteral).stringValue ?? '';
      final msg = (args[2] as StringLiteral).stringValue ?? '';
      final desc = (args[3] as StringLiteral).stringValue ?? '';

      var defaultArgs = <String, Object?>{};

      // Look for the 'param' named argument among all arguments starting from index 4
      for (final arg in args.skip(4)) {
        if (arg is NamedExpression && arg.name.label.name == 'param') {
          final val = arg.expression;
          if (val is SetOrMapLiteral) {
            defaultArgs = _parseMap(val);
          }
          break; // Found it
        }
      }
      messages.add(MessageDefinition(enumName, key, msg, defaultArgs, desc));
    }
    super.visitEnumConstantDeclaration(node);
  }

  Object? _resolveLiteral(Expression expression) {
    if (expression is StringLiteral) {
      return expression.stringValue;
    } else if (expression is IntegerLiteral) {
      return expression.value;
    } else if (expression is BooleanLiteral) {
      return expression.value;
    } else if (expression is DoubleLiteral) {
      return expression.value;
    } else if (expression is SetOrMapLiteral) {
      return _parseMap(expression);
    }
    return null;
  }

  Map<String, Object?> _parseMap(SetOrMapLiteral mapExpr) {
    final Map<String, Object?> resultMap = {};

    for (var entry in mapExpr.elements) {
      if (entry is MapLiteralEntry) {
        final key = _resolveLiteral(entry.key);
        final value = _resolveLiteral(entry.value);
        if (key is String) resultMap[key] = value;
      }
    }
    return resultMap;
  }

  // cls_lastline
}
