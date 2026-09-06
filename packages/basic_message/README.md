[English](https://github.com/huanguan1978/messages/blob/main/packages/basic_message/doc/en) | [Chinese
](https://github.com/huanguan1978/messages/blob/main/packages/basic_message/doc/zh)


# basic_message

A structured, type-safe, and compile-time mapping localization framework for Dart, specifically designed for multi-environment projects (Flutter GUI and Dart CLI). It enables "Define Once, Use Everywhere" by decoupling business logic from platform-specific translation implementations.

[![pub package](https://img.shields.io/pub/v/basic_message.svg)](https://pub.dev/packages/basic_message)

## Why basic_message?

Building a full-stack Dart/Flutter project often leads to fragmented localization management. `basic_message` solves these common pain points:

*   **Unified Definition**: Define messages in a shared package; reuse them seamlessly across CLI, GUI, and Server.
*   **Type Safety**: Leverage Dart `enum` and Generics to catch missing translation keys at compile-time.
*   **Platform Decoupling**: Use a unified `MessageProvider` interface to bridge the gap between context-dependent Flutter apps and context-free CLI tools.
*   **ARB Standard**: Native support for the `ARB` (Application Resource Bundle) format, ensuring compatibility with professional translation platforms.
*   **Zero Runtime Overhead**: Utilize code generation to bind keys, maintaining high performance in both GUI and CLI environments.
*   **Sophisticated Rendering**: Built-in support for dynamic parameters, plurals, and gender-based localization, abstracting the complexity of the `intl` package.

## Quick Start

### Core Workflow

1.  **Define**: Create a shared `MessageEnum` in a central package.
2.  **Generate**: Extract ARB files for translation management.
3.  **Integrate**: Implement a platform-specific `MessageProvider`.
4.  **Execute**: Use `MessageEngine.tr()` to dispatch translations anywhere in your app.

### 1. Installation

```bash
dart pub add basic_message
```

### 2. Define Messages (Shared Package)

Create a dedicated package (e.g., `share_message`) to hold your message definitions.

```yaml
# packages/share_message/pubspec.yaml
dependencies:
  basic_message: ^1.0.0
```

```dart
// packages/share_message/lib/src/share_message_base.dart
import 'package:basic_message/basic_message.dart';

enum AppMessage implements MessageEnum {
  welcomeLabel(
    1001,
    'home_index_header_welcome_label',
    'Welcome, {username}!',
    'Personalized welcome message',
    param: {'username': 'Guest'},
  );
  
  // ... implement MessageEnum interface (code, key, msg, param, desc)

  @override
  final int code;
  @override
  final String key;
  @override
  final String msg;
  @override
  final Map<String, Object> param;
  @override
  final String desc;

  const AppMessage(
    this.code,
    this.key,
    this.msg,
    this.desc, {
    this.param = const {},
  });
}
```

### 3. Generate ARB Resources

Use the provided CLI tools to bridge your enums and the standard `intl` pipeline:

1.  `dart run basic_message:gen_msg_resource` — Generates intermediate resource classes.
2.  `dart run intl_translation:extract_to_arb` — Extracts the ARB files for your translation team.
3.  Translate the ARB files, then run `generate_from_arb` to create the localized Dart code.

*(For full automation, see our [Design Guide](doc/en/L10N_DESIGN_GUIDE.md) and the [Example Repository](https://github.com/huanguan1978/messages)).*


### 4. CLI Integration
**Step**: Add the shared message package dependency, copy the `CliMessageProvider` boilerplate from the [Example Repository](https://github.com/huanguan1978/messages), and initialize `MessageEngine` in your `main()` entry point.

```dart
// Conceptual snippet: please refer to 'cli_example' for the full implementation
import 'package:basic_message/basic_message.dart';

void main() {
  MessageEngine.init(CliMessageProvider('en'));
  print(MessageEngine.tr(AppMessage.welcomeLabel, args: {'username': 'Alice'}));
}
```

### 5. Flutter Integration
**Step**: Add the `basic_message` dependency to your Flutter project and run
`flutter gen-l10n` to generate the localization classes. For the complete
Flutter integration, refer to the [`gui_example`](https://github.com/huanguan1978/messages/tree/main/packages/gui_example)
in the Example Repository.

The example includes `GuiMessageProvider`, the generated message registry,
locale switching, and the `GuiMessageInitializer` helper. You can copy and
adapt these files to your Flutter project.

Place `GuiMessageInitializer` in `MaterialApp.builder` to initialize
`MessageEngine` globally with the current localization context:

```dart
MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => GuiMessageInitializer(child: child!),
  home: const HomePage(),
);
```

Then use shared messages anywhere below `MaterialApp`:

```dart
Text(
  MessageEngine.tr(
    AppMessage.welcomeLabel,
    args: {'username': 'Alice'},
  ),
)
```

`basic_message` is a pure Dart package and does not include the
Flutter-specific `GuiMessageInitializer`. Copy its implementation from
`gui_example` and adjust the imports for your project.

## v2 Update (v1.0.2)

v2 introduces the **5-Level Semantic Coordinate Architecture** and a **Late-Binding** workflow, designed to enhance rigor and maintainability in localization management for large-scale projects. For detailed specifications, please refer to [L10N_NAMING_GUIDE2.md](doc/en/L10N_NAMING_GUIDE2.md).

### Real-world Implementation References

To help developers effectively adopt the v2 standard, we provide the following reference implementations, demonstrating how to efficiently integrate `basic_message` in complex business scenarios:

*   **CLI Localization**: See [chapose](https://github.com/huanguan1978/chacrypt/tree/main/chapose), a tool focused on command-line file encryption and decryption.
*   **GUI Localization**: See [chabox](https://github.com/huanguan1978/chacrypt/tree/main/chabox), a graphical workstation focused on personal privacy and secure file storage.

Both modules are derived from the [chacrypt](https://github.com/huanguan1978/chacrypt) project—an ecosystem dedicated to offline file security and data sovereignty. Visit the [GitHub repository](https://github.com/huanguan1978/chacrypt) to learn more.

## Resources

*   **[Design Guide](doc/en/L10N_DESIGN_GUIDE.md)**: Deep dive into architecture, workflows, and best practices.
*   **[Naming Convention](doc/en/L10N_NAMING_GUIDE2.md)**: Standardized five-level naming strategy for team consistency.
*   **[Example Repository](https://github.com/huanguan1978/messages)**: A complete, ready-to-run boilerplate including `share_message`, `cli_example`, and `gui_example`.
