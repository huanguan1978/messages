// Generates a translation context pack: for every message defined in the
// input MessageEnum definition file, locates all call sites in a project and
// extracts formatting-immune (AST-based) source context for each.
//
// The output JSON is intended as input material for a translation workflow:
// a translator (human or model) reads msg/desc/param plus the real call-site
// context to disambiguate message semantics without guessing.
//
// Usage:
//   dart run basic_message:gen_msg_analyzer \
//     -i lib/message/definition.dart \
//     -s . \
//     -o lib/l10n/messages_analyzer.g.json

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

/// Default maximum characters kept per extracted source snippet.
const _defaultMaxSnippetChars = 2000;

/// Floor for `--max-snippet`: below this, context slices routinely cut off
/// nested call structures and lose their disambiguation value.
const _minMaxSnippetChars = 2000;

int _maxSnippetChars = _defaultMaxSnippetChars;

const _skippedDirs = {'.dart_tool', '.git', '.idea', '.vscode', 'build'};

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'input',
      abbr: 'i',
      mandatory: true,
      help: 'Message definition file (e.g. lib/message/definition.dart).',
    )
    ..addOption(
      'source',
      abbr: 's',
      mandatory: true,
      help: 'Project root directory scanned for call sites.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      mandatory: true,
      help: 'Output JSON file (e.g. lib/l10n/messages_analyzer.g.json).',
    )
    ..addOption(
      'max-snippet',
      abbr: 'm',
      defaultsTo: '$_defaultMaxSnippetChars',
      help:
          'Max characters per extracted source snippet (floor: '
          '$_minMaxSnippetChars).',
    );

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on ArgParserException catch (e) {
    print('❌ ${e.message}\n${parser.usage}');
    exit(1);
  }

  var input = args['input'] as String;
  var source = args['source'] as String;
  var output = args['output'] as String;
  if (!p.isAbsolute(input)) input = p.absolute(input);
  if (!p.isAbsolute(source)) source = p.absolute(source);
  if (!p.isAbsolute(output)) output = p.absolute(output);

  final definitionFile = File(input);
  if (!definitionFile.existsSync()) {
    print('❌ Input file not found: $input');
    exit(1);
  }
  if (!Directory(source).existsSync()) {
    print('❌ Source directory not found: $source');
    exit(1);
  }

  final maxSnippetRaw = int.tryParse(args['max-snippet'] as String);
  if (maxSnippetRaw == null || maxSnippetRaw <= 0) {
    print('❌ Invalid --max-snippet value: ${args['max-snippet']}');
    exit(1);
  }
  _maxSnippetChars = maxSnippetRaw < _minMaxSnippetChars
      ? _minMaxSnippetChars
      : maxSnippetRaw;
  if (_maxSnippetChars != maxSnippetRaw) {
    print('ℹ --max-snippet raised to the floor value: $_maxSnippetChars');
  }

  // Step 1: parse message definitions (same visitor as gen_msg_resource).
  final unit = parseString(
    content: definitionFile.readAsStringSync(),
    path: input,
  ).unit;
  final definitionVisitor = _EnumVisitor();
  unit.visitChildren(definitionVisitor);
  final messages = definitionVisitor.messages;
  if (messages.isEmpty) {
    print('❌ No message definitions found in: $input');
    exit(1);
  }
  final targets = messages.map((m) => m.name).toSet();

  // Step 2: collect candidate .dart files under the project root.
  final excludePaths = <String>{
    p.canonicalize(input),
    p.canonicalize(output),
  };
  final files = _collectDartFiles(source, excludePaths);

  // Step 3: parse each candidate file once and collect identifier references.
  final refs = <String, List<_CallSite>>{};
  for (final m in messages) {
    refs[m.name] = [];
  }

  var parsedFiles = 0;
  for (final file in files) {
    final content = file.readAsStringSync();

    // Cheap prefilter: skip parsing when no target name appears at all.
    var containsAny = false;
    for (final name in targets) {
      if (content.contains(name)) {
        containsAny = true;
        break;
      }
    }
    if (!containsAny) continue;

    final lineInfo = LineInfo.fromContent(content);
    final collector = _ReferenceCollector(targets);
    parseString(content: content, path: file.path).unit.visitChildren(collector);
    parsedFiles++;

    for (final entry in collector.hits.entries) {
      for (final ident in entry.value) {
        refs[entry.key]!.add(
          _describeCallSite(
            ident: ident,
            content: content,
            lineInfo: lineInfo,
            relativePath: p.relative(file.path, from: source).replaceAll(r'\', '/'),
          ),
        );
      }
    }
  }

  // Step 4: assemble the JSON pack.
  final entries = <Map<String, Object?>>[];
  var totalCallSites = 0;
  final unreferenced = <String>[];

  for (final m in messages) {
    final sites = refs[m.name]!
      ..sort(
        (a, b) {
          final byFile = a.file.compareTo(b.file);
          return byFile != 0 ? byFile : a.line.compareTo(b.line);
        },
      );
    if (sites.isEmpty) unreferenced.add(m.name);
    totalCallSites += sites.length;

    entries.add({
      'code': m.code,
      'key': m.key,
      'member': m.name,
      'msg': m.defaultValue,
      'desc': m.desc,
      if (m.defaultArgs.isNotEmpty) 'paramExamples': m.defaultArgs,
      'callSites': [
        for (final s in sites)
          {
            'file': s.file,
            'line': s.line,
            if (s.call != null) 'call': s.call,
            if (s.context != null) 'context': s.context,
            if (s.owner.isNotEmpty) 'owner': s.owner,
          },
      ],
    });
  }

  final pack = {
    'generator': 'basic_message:gen_msg_analyzer',
    'definitionFile': p.relative(input, from: source).replaceAll(r'\', '/'),
    'messageCount': messages.length,
    'callSiteCount': totalCallSites,
    'messages': entries,
  };

  final outputFile = File(output);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(pack),
  );

  print('✅ Generated: $output');
  print('   messages: ${messages.length}, call sites: $totalCallSites, '
      'files parsed: $parsedFiles');
  if (unreferenced.isNotEmpty) {
    print('⚠ No call sites found for ${unreferenced.length} message(s):');
    for (final name in unreferenced) {
      print('   - $name');
    }
  }
}

class _CallSite {
  final String file;
  final int line;
  final String? call;
  final String? context;
  final String owner;
  _CallSite({
    required this.file,
    required this.line,
    required this.call,
    required this.context,
    required this.owner,
  });
}

/// Walks up the AST from a referenced identifier and extracts source slices
/// for (a) the enclosing invocation, (b) the enclosing statement or catch
/// clause, and (c) the enclosing declaration names.
///
/// Because dart format only changes whitespace, AST-level extraction is
/// immune to line wrapping of long call chains.
_CallSite _describeCallSite({
  required SimpleIdentifier ident,
  required String content,
  required LineInfo lineInfo,
  required String relativePath,
}) {
  // L1: nearest enclosing invocation (the actual call, e.g. ME.tr(...)).
  AstNode? node = ident.parent;
  AstNode? invocation;
  while (node != null) {
    if (node is MethodInvocation ||
        node is InstanceCreationExpression ||
        node is FunctionExpressionInvocation) {
      invocation = node;
      break;
    }
    node = node.parent;
  }

  // L2: nearest enclosing statement or catch clause, searched above the
  // invocation so nested calls resolve to the outer semantic unit.
  AstNode? start = (invocation ?? ident).parent;
  AstNode? statement;
  while (start != null) {
    if (start is Statement || start is CatchClause) {
      statement = start;
      break;
    }
    start = start.parent;
  }

  // L3: enclosing declaration names (method / class, mixin, extension, enum).
  final ownerParts = <String>[];
  node = ident.parent;
  while (node != null) {
    if (node is MethodDeclaration ||
        node is FunctionDeclaration ||
        node is ConstructorDeclaration) {
      ownerParts.add(_declarationName(node));
    } else if (node is NamedCompilationUnitMember) {
      ownerParts.add(_declarationName(node));
    }
    node = node.parent;
  }
  final owner = ownerParts.reversed.join('.');

  final call = invocation == null
      ? null
      : _snippet(content.substring(invocation.offset, invocation.end));
  final context = statement == null
      ? null
      : _snippet(content.substring(statement.offset, statement.end));

  return _CallSite(
    file: relativePath,
    line: lineInfo.getLocation(ident.offset).lineNumber,
    call: call,
    // Redundant when the statement is the call itself.
    context: (context == null || context == call) ? null : context,
    owner: owner,
  );
}

String _declarationName(AstNode node) {
  if (node is MethodDeclaration) return node.name.lexeme;
  if (node is FunctionDeclaration) return node.name.lexeme;
  if (node is ConstructorDeclaration) {
    return node.name?.lexeme ?? node.returnType.toString();
  }
  if (node is NamedCompilationUnitMember) return node.name.lexeme;
  return '<unknown>';
}

/// Normalizes indentation and truncates long snippets.
String _snippet(String raw) {
  final lines = raw.split('\n');
  var minIndent = -1;
  for (var i = 1; i < lines.length; i++) {
    final trimmed = lines[i].trimLeft();
    if (trimmed.isEmpty) continue;
    final indent = lines[i].length - trimmed.length;
    minIndent = minIndent < 0 ? indent : (indent < minIndent ? indent : minIndent);
  }
  final normalized = minIndent > 0
      ? [
          lines.first,
          for (var i = 1; i < lines.length; i++)
            lines[i].length >= minIndent
                ? lines[i].substring(minIndent)
                : lines[i].trimLeft(),
        ].join('\n')
      : raw;

  final single = normalized.replaceAll('\n', '\n  ').trim();
  if (single.length <= _maxSnippetChars) return single;
  return '${single.substring(0, _maxSnippetChars)}\n  … [truncated]';
}

List<File> _collectDartFiles(String root, Set<String> excludePaths) {
  final files = <File>[];
  void recurse(Directory dir) {
    for (final entity in dir.listSync(followLinks: false)) {
      final base = p.basename(entity.path);
      if (entity is Directory) {
        if (base.startsWith('.') || _skippedDirs.contains(base)) continue;
        recurse(entity);
      } else if (entity is File && base.endsWith('.dart')) {
        if (base.endsWith('.g.dart')) continue;
        if (excludePaths.contains(p.canonicalize(entity.path))) continue;
        files.add(entity);
      }
    }
  }

  recurse(Directory(root));
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

class MessageDefinition {
  final int code;
  final String name, key, defaultValue, desc;
  final Map<String, Object?> defaultArgs;
  MessageDefinition(
    this.code,
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

    if (args != null && args.length > 3) {
      final enumName = node.name.lexeme;
      final code = (args[0] as IntegerLiteral).value ?? 0;
      final key = (args[1] as StringLiteral).stringValue ?? '';
      final msg = (args[2] as StringLiteral).stringValue ?? '';
      final desc = (args[3] as StringLiteral).stringValue ?? '';

      var defaultArgs = <String, Object?>{};
      for (final arg in args.skip(4)) {
        if (arg is NamedExpression && arg.name.label.name == 'param') {
          final val = arg.expression;
          if (val is SetOrMapLiteral) {
            defaultArgs = _parseMap(val);
          }
          break;
        }
      }
      messages.add(MessageDefinition(code, enumName, key, msg, defaultArgs, desc));
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
}

class _ReferenceCollector extends RecursiveAstVisitor<void> {
  final Set<String> targets;
  final Map<String, List<SimpleIdentifier>> hits = {};

  _ReferenceCollector(this.targets);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (targets.contains(node.name)) {
      (hits[node.name] ??= []).add(node);
    }
    super.visitSimpleIdentifier(node);
  }
}
