import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:yaml/yaml.dart';

import 'package:path/path.dart' as p;

void main(List<String> args) {
  final l10nConfigPath = 'l10n.yaml';
  final l10nConfigFile = File(l10nConfigPath);

  if (!l10nConfigFile.existsSync()) {
    print(
      '❌ Error: $l10nConfigPath not found. Please ensure it exists in the project root.',
    );
    exit(1);
  }

  final l10nYaml = loadYaml(l10nConfigFile.readAsStringSync());
  final outputDir = l10nYaml['output-dir'] ?? p.join('lib', 'l10n');
  final outputClass =
      l10nYaml['output-localization-file'] ?? 'app_localizations.dart';

  final input = p.join(outputDir, outputClass);
  final output = p.join(outputDir, 'messages_registry.g.dart');

  final inputFile = File(input);
  if (!inputFile.existsSync()) {
    print('❌ Error: ${inputFile.path} not found.');
    exit(1);
  }

  final outputFile = File(output);
  try {
    if (outputFile.existsSync()) {
      outputFile.deleteSync();
    } else {
      Directory(outputDir).createSync(recursive: true);
    }
  } catch (e) {
    print('❌ Error deleting existing registry: $e');
    exit(1);
  }

  final inputContent = inputFile.readAsStringSync();
  final parseResult = parseString(content: inputContent, path: input);
  final visitor = _LocalizationsVisitor();
  parseResult.unit.visitChildren(visitor);

  final buffer = StringBuffer();
  buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND");
  buffer.writeln("import './app_localizations.dart';");
  buffer.writeln(
    "\nString resolveL10n(AppLocalizations l10n, String key, Map<String, dynamic>? args) {",
  );
  buffer.writeln("  switch (key) {");

  for (var method in visitor.methods) {
    // 直接使用方法名，因为它就是我们要的 key
    buffer.write("    case '${method.name}': ");

    if (method.isGetter) {
      buffer.writeln("return l10n.${method.name};");
    } else {
      final paramMapping = method.params.map((p) {
        final value = "args?['${p.name}']";
        if (p.type == 'Object') {
          return "$value ?? ''";
        } else {
          return "($value as ${p.type})";
        }
      }).join(', ');
      buffer.writeln("return l10n.${method.name}($paramMapping);");
    }
  }

  buffer.writeln(
    "    default: throw Exception('Key \$key not found in AppLocalizations');",
  );
  buffer.writeln("  }");
  buffer.writeln("}");

  outputFile.writeAsStringSync(buffer.toString());
  print('✅ Successfully generated registry at $output');
}

class MethodInfo {
  final String name;
  final bool isGetter;
  final List<ParamInfo> params;
  MethodInfo(this.name, this.isGetter, this.params);
}

class ParamInfo {
  final String name;
  final String type;
  ParamInfo(this.name, this.type);
}

class _LocalizationsVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInfo> methods = [];

  // 需要过滤的系统方法/属性名单
  final _excludeList = {
    'of',
    'delegate',
    'isSupported',
    'shouldReload',
    'load',
    'localName',
    'supportedLocales',
    'localizationsDelegates',
    'get',
  };

  static String _getParamType(FormalParameter p) {
    if (p is SimpleFormalParameter) {
      return p.type?.toString() ?? 'Object';
    }
    if (p is DefaultFormalParameter) {
      final inner = p.parameter;
      if (inner is SimpleFormalParameter) {
        return inner.type?.toString() ?? 'Object';
      }
      return 'Object';
    }
    if (p is FieldFormalParameter) {
      return p.type?.toString() ?? 'Object';
    }
    return 'Object';
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;
    if (_excludeList.contains(name)) return;

    final params = node.parameters?.parameters.map((p) {
          final type = _getParamType(p);
          final paramName = p.name!.lexeme;
          return ParamInfo(paramName, type);
        }).toList() ??
        [];
    // 捕获 Getter (ARB 翻译中无参的项)
    final isGetter = node.isGetter;

    methods.add(MethodInfo(name, isGetter, params));
    super.visitMethodDeclaration(node);
  }
}
