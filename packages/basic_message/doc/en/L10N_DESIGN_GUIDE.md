# BASIC MESSAGE (Localization Architecture Solution)

`basic_message` provides a structured, scalable engineering framework for handling localization across both Flutter (GUI) and Dart (CLI) environments.

### I. Core Requirements
1.  **Unified Management**: Employs a standardized naming convention (Four-Level hierarchy) and message categorization (Message Level).
2.  **Platform Decoupling**: Supports both Flutter (requires `BuildContext`) and CLI (context-free) through a single unified logic.
3.  **Type Safety**: Leverages Dart `enum` and Generics to ensure compile-time safety and IDE auto-completion.
4.  **Full L10n Support**: Adheres to the `ARB` standard with Fallback mechanisms, enabling seamless integration with professional translation platforms.
5.  **Dynamic Rendering**: Supports parameter injection (`Intl.message` args), pluralization (`Intl.plural`), and gender-based localization.
6.  **Engineering Isolation**: Decouples core logic into a generic package, avoiding manual modification of auto-generated Flutter localization code.

---

### II. Architecture Overview
We utilize a **"Core Protocol + Platform Provider"** design pattern.

*   **`basic_message` (Core Library)**: Defines the protocol and engine; agnostic of GUI frameworks.
*   **`Flutter/CLI Host Project`**: Implements platform-specific resolution logic and registers it with the engine.

---

### III. Core Implementation (Generic Library `basic_message`)

#### 1. Package Structure

```text
basic_message/
├── lib/
│   ├── basic_message.dart
│   └── src/
│       └── basic_message_base.dart         # MessageEnum, MessageResolver, MessageEngine
├── bin/
│   └── gen_msg_resource.dar
│   └── gen_msg_registry.dart
│
└── pubspec.yaml                            #  executables: gen-msg-resource, gen-msg-registry
```

---

#### 2. Protocol Definition
```dart

/// alias logging.level
typedef MessageLevel = logging.Level;

/// Defines the contract for all message identifiers.
abstract class MessageEnum {
  /// Unique error or message code.
  int get code;

  /// use exit(code) to exit the process with a specific code.
  int get exit => 0;

  /// Severity level of the message.
  MessageLevel get level => MessageLevel.INFO;

  /// Corresponding ARB resource key.
  String get key;

  /// Default text used if no translation is found.
  String get msg;

  /// The `desc` provides a description of the message usage.
  String get desc => '';

  /// Default arguments for the message.
  Map<String, Object> get param;
}

/// Abstract provider to be implemented by the application.
/// Acts as the source for `intl` translation extraction.
abstract class MessageProvider<T extends MessageEnum> {
  /// Resolves the message to its localized string.
  /// Implementations should use [Intl.message] to define the translation key.
  String resolve(T message, {Map<String, Object>? args});
}

/// Global engine to handle message translation and dispatching.
class MessageEngine {
  static MessageProvider? _provider;

  /// Initializes the engine with a platform-specific provider.
  static void init(MessageProvider provider) {
    _provider = provider;
  }

  /// Translates the given message.
  /// Returns the default message if the engine is uninitialized or key is missing.
  static String tr<T extends MessageEnum>(
    T message, {
    Map<String, Object>? args,
  }) {
    // Merge values from 'args' into 'param', discarding any keys not present in the base 'param' map.
    if (args != null && args.isNotEmpty && message.param.isNotEmpty) {
      final param = Map<String, Object>.from(message.param); // default param

      param.addEntries(
        args.entries.where((entry) => param.containsKey(entry.key)),
      );

      args = param;
    }

    if (_provider == null) {
      return _renderFallback(message.msg, args);
    }
    return _provider!.resolve(message, args: args);
  }

  static String _renderFallback(String msg, Map<String, Object>? args) {
    if (args == null || args.isEmpty) return msg;
    var result = msg;
    args.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}

```

---

### IV. Dual-Layer Loop Design
1.  **Core Protocol Layer (`basic_message`)**: Defines the `MessageEnum` interface and `MessageEngine`. It acts solely as a "translation dispatcher" without containing business text.
2.  **Platform Adaptation Layer (`Resolver`)**:
    *   **CLI**: Uses `intl` native reflection to read resources directly.
    *   **Flutter**: Uses `gen_msg_registry.dart` to parse `AppLocalizations` and bind keys at compile-time, ensuring zero runtime overhead.

---

### V. Engineering Workflow (SOP)

#### Phase 1: Definition
1.  **Define**: Create an `enum AppMessage` implementing `MessageEnum`.
2.  **Extract**: Use `gen_msg_resource` to convert the enum into a source file compatible with `intl_translation:extract_to_arb`.
3.  **Standardize**: The `.arb` file serves as the **Single Source of Truth** for all environments.

#### Phase 2: CLI Integration
CLI apps consume the core library directly.
*   **Initialization**: Call `MessageEngine.init(CliMessageProvider())`.
*   **Resolution**: `CliMessageProvider` calls `Intl.message` to map keys to generated `messages_<locale>.dart` files.

#### Phase 3: Flutter Integration
1.  **Generate**: Run `flutter gen-l10n` to create `AppLocalizations`.
2.  **Bind**: Run `gen-msg-registry` to generate the static mapping table.
3.  **Initialize**: Set `MessageEngine.init(FlutterResolver(l10n, registry))`.
---


### VI. Why This Is the "Ultimate Solution"

| Feature | Solution | Benefit |
| :--- | :--- | :--- |
| **Categorization** | `MessageEnum` | Type-safe and IDE-friendly. |
| **Decoupling** | `MessageEnum.key` | Strict separation of code logic and text resources. |
| **Scalability** | `MessageProvider` | Highly customizable for any platform. |
| **Safety** | Dart Generics | Compile-time detection of missing translation keys. |
| **Dynamic Data** | `Map<String, Object>?` | Unified variable handling, abstracting `intl` complexity. |
| **Engineering** | `gen-msg-registry` | Auto-generated mappings, no interference with `flutter_gen`. |
| **Reliability** | Fallback mechanism | Ensures app stability if translation is missing. |

---

### VII. Implementation Advice for Developers

1.  **For Pure Dart Developers**: Use `MessageEngine.tr(MyMessage.error)` directly, combined with the native `intl` toolchain. This is the most lightweight approach and aligns perfectly with the standard Dart ecosystem.
2.  **For Flutter Developers**: Use `basic_message` as your "glue layer." Simply ensure that after every modification to your `ARB` files, you run `flutter gen-l10n` followed by `gen-msg-registry`. This two-step process allows you to maintain Flutter’s performance while gaining the same type-safe development experience as your CLI projects.


### VIII. Application-Level Implementation Example

#### 1. Defining Business Message Enums (Workspace: `messages`, Package: `share_message`)
*Ensure key naming follows the [Four-Level Naming Convention](L10N_NAMING_GUIDE.md).*

```dart
// packages/share_message/lib/src/share_message_base.dart
enum AppMessage implements MessageEnum {
  commonGlobalBodyGenderLabel(
    901,
    'common_global_body_gender_label',
    '{gender, select, male{He} female{She} other{They}}',
    'gobal gender (male | female) to (He | She).',
    param: {'gender': 'male'},
  ),
  commonGlobalBodyAppleLabel(
    902,
    'common_global_body_apple_label',
    '{count, plural, =1{has one apple} other{has {count} apples}}',
    '',
    param: {'count': 5},
  ),

  commonGlobalBodyAssembleWhoseAppleLabel(
    903,
    'common_global_body_assembleWhoseApple_label',
    '{whose} {apple}',
    'assemble whose apple.',
    param: {'whose': 'male', 'apple': 5},
  ),

  commonGlobalActionConfirmExitLabel(
    1001,
    'common_global_action_confirm_exit_label',
    'Are you sure to exit?',
    'cli exit tips.',
  ),
  homeIndexHeaderWelcomeLabel(
    1003,
    'home_index_header_welcome_label',
    'Welcome, {username}!',
    '',
    param: {'username': 'Guest'},
  ),
  homeIndexHeaderDefaultTitle(
    1004,
    'home_index_header_default_title',
    'Multi Language Home Page',
    '',
  ),
  homeIndexCounterIncrementLabel(
    1005,
    'home_index_counter_increment_label',
    'You have pushed the button this many times:',
    '',
  ),
  homeIndexCounterIncrementAction(
    1006,
    'home_index_counter_increment_action',
    'Increment',
    '',
  );

  @override
  final int code;
  @override
  final String key;
  @override
  final String msg;

  @override
  final Map<String, Object> param;

  @override
  final MessageLevel level;

  @override
  final int exit;

  @override
  final String desc;

  const AppMessage(
    this.code,
    this.key,
    this.msg,
    this.desc, {
    // ignore: unused_element_parameter
    this.param = const {},

    // ignore: unused_element_parameter
    this.level = MessageLevel.INFO,

    // ignore: unused_element_parameter
    this.exit = 0,
  });
}
```

#### 2. CLI Implementation (Resolver)
The CLI logic leverages the `intl` package directly.

**Step A: Generate resource data classes from the enum:**
```bash
dart run basic_message:gen_msg_resource -i packages/share_message/lib/src/share_message_base.dart -o packages/cli_example/lib/generated/messages_resource.g.dart 
```

**Step B: Extract ARB files from the generated resource class:**
```bash
dart run intl_translation:extract_to_arb --output-dir=packages/cli_example/lib/l10n packages/cli_example/lib/generated/messages_resource.g.dart
```

**Step C: Generate localized Dart code after translation:**
```bash
dart run intl_translation:generate_from_arb --output-dir=packages/cli_example/lib/generated/ packages/cli_example/lib/generated/messages_resource.g.dart packages/cli_example/lib/l10n/intl_*.arb
```


**Implementing the CLI Message Provider:**
```dart
// packages/cli_example/lib/cli_message_provider.dart

import 'package:intl/intl.dart';
import 'package:basic_message/basic_message.dart';
import 'package:share_message/share_message.dart';

class CliMessageProvider extends MessageProvider<AppMessage> {
  final String locale;
  CliMessageProvider(this.locale);

  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    // final methodName = message.key.replaceAll('.', '_');
    return Intl.message(
      message.msg,
      name: message.key,
      args: args?.values.toList(),
      locale: locale,
    );
  }
}

```

```dart
// packages/cli_example/bin/cli_example.dart

import 'package:basic_message/basic_message.dart';
import 'package:share_message/share_message.dart';

import 'package:cli_example/cli_message_provider.dart';
import 'package:cli_example/generated/messages_all.dart';

void main() {
  final locales = ['en', 'zh'];
  final locale = locales.first;
  // Intl.defaultLocale = locale;

  toggleLocale(locale);
}

void toggleLocale(String locale) {
  initializeMessages(locale).then((_) {
    MessageEngine.init(CliMessageProvider(locale));
    print(MessageEngine.tr(AppMessage.commonGlobalActionConfirmExitLabel));
    print(
      MessageEngine.tr(
        AppMessage.homeIndexHeaderWelcomeLabel,
        args: AppMessage.homeIndexHeaderWelcomeLabel.param,
      ),
    );

    // toggleLangAssembleWhoseApple();
  });
}

```

#### 3. Flutter Implementation (Resolver) (Resolver [workspace:messages, package: gui_example])
Flutter integration uses the standard `l10n` build flow, extended by our registry generator.

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: intl_en.arb 
output-localization-file: app_localizations.dart
```

**Generate Localization Files:**
```bash
cp packages/cli_example/lib/l10n/intl_*.arb packages/gui_example/lib/l10n/
cd packages/gui_example
flutter l10n-gen
```

**Generate the Registry Map:**
```bash
dart run basic_message:gen_msg_registry
```

**Implementing the GUI Message Provider:**
```dart
// packages/gui_example/lib/gui_message_provider.dart

import 'package:flutter/widgets.dart';
import 'package:basic_message/basic_message.dart';

import './l10n/app_localizations.dart';
import './l10n/messages_registry.g.dart';

class GuiMessageProvider<T extends MessageEnum> implements MessageProvider<T> {
  final BuildContext context;
  GuiMessageProvider(this.context);

  @override
  String resolve(T message, {Map<String, Object>? args}) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return message.msg;

    try {
      return resolveL10n(l10n, message.key, args);
    } catch (e) {
      return message.msg;
    }
  }
}

```

```dart
// packages/gui_example/lib/main.dart

import 'package:flutter/material.dart';
import 'package:basic_message/basic_message.dart';
import 'package:share_message/share_message.dart';

import './gui_message_provider.dart';
import './l10n/app_localizations.dart';

/// A simple Flutter application demonstrating the use of a custom message engine for localization.
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en'));

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: localeNotifier,
      builder: (context, value, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: value,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: .fromSeed(seedColor: Colors.deepPurple),
          ),
          // home: const MyHomePage(title: 'Flutter Demo Home Page'),
          home: Builder(
            builder: (context) {
              MessageEngine.init(GuiMessageProvider(context));
              final title = MessageEngine.tr(
                AppMessage.homeIndexHeaderDefaultTitle,
              );
              return MyHomePage(title: title);
            },
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),

        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (Locale newLocale) {
              localeNotifier.value = newLocale;
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: Locale('en'),
                child: Text('English (en)'),
              ),
              const PopupMenuItem(
                value: Locale('zh'),
                child: Text('Chinese (zh)'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text(MessageEngine.tr(AppMessage.homeIndexCounterIncrementLabel)),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: MessageEngine.tr(AppMessage.homeIndexCounterIncrementAction),
        child: const Icon(Icons.add),
      ),
    );
  }
}

```

### IX. Project Automation & Optimization

To minimize manual CLI tasks, we recommend using `ft:FileTools`. 
*   **Generate ARB**: `ft shell . --config=ft-messages-multilanguage.yaml --blocks=gen_arb_scripts`
*   **Generate Dart from ARB**: `ft shell . --config=ft-messages-multilanguage.yaml --blocks=gen_from_arb_scripts`
*   **Flutter L10n Build**: `ft shell --config=ft-messages-multilanguage.yaml --blocks=flutter_gen_scripts`

**Performance Optimization (Excluding `lib/generated`)**:
1.  **VS Code**: Add `"dart.formatExclude": ["lib/generated/**"]` to your `settings.json`.
2.  **Analysis**: Add `lib/generated/**` to `analyzer.exclude` in `analysis_options.yaml`.
3.  **Generator Templates**: Include `// dart format off` at the top of generated files to prevent unwanted reformatting.


**About ft:FileTools**:

- [Why ft? Beyond Shell Scripts and Standard Toolchains](https://github.com/huanguan1978/ft/blob/main/doc/en/FAQ.md)
- [ft: FileTools - High-Performance Cross-Platform File Management & Automation](https://pub.dev/packages/filetools)
- Install it：`dart pub global activate --executable=ft filetools`

---

### X. Architecture Summary

| Feature | Solution | Benefit |
| :--- | :--- | :--- |
| **Data Classification** | `MessageEnum` | Enables IDE auto-completion and structured management. |
| **Tooling Decoupling** | `MessageEnum.key` | Separates UI logic from localization resources. |
| **Extensible Architecture** | `MessageProvider` | Allows for custom platform-specific resolution logic. |
| **Type Safety** | Dart Generics | Catches missing keys at compile-time. |
| **Dynamic Rendering** | `Map<String, Object>? args` | Standardizes parameter passing, abstracting `intl` complexity. |
| **Engineering Isolation** | `gen-msg-registry` | Bridges the gap without modifying generated Flutter code. |
| **Fallback Mechanism** | `defaultMessage` | Prevents runtime crashes if a translation is missing. |

This architecture creates a **closed-loop system**: from initial business definition (`MessageEnum`) to resource extraction (`ARB`), and finally to platform-specific binding (`Resolver`). It ensures that your multi-language infrastructure is robust, scalable, and type-safe across both CLI and Flutter environments.
