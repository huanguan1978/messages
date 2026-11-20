# basic_message

[![pub package](https://img.shields.io/pub/v/basic_message.svg)](https://pub.dev/packages/basic_message)


A structured, type-safe, and compile-time mapping localization framework for Dart, specifically designed for multi-environment projects (Flutter GUI and Dart CLI). It enables "Define Once, Use Everywhere" by decoupling business logic from platform-specific translation implementations.

## Why basic_message?

Building a full-stack Dart/Flutter project often leads to fragmented localization management. `basic_message` solves these common pain points:

*   **Unified Definition**: Define messages in a shared package; reuse them seamlessly across CLI, GUI, and Server.
*   **Type Safety**: Leverage Dart `enum` and Generics to catch missing translation keys at compile-time.
*   **Platform Decoupling**: Use a unified `MessageProvider` interface to bridge the gap between context-dependent Flutter apps and context-free CLI tools.
*   **ARB Standard**: Native support for the `ARB` (Application Resource Bundle) format, ensuring compatibility with professional translation platforms.
*   **Zero Runtime Overhead**: Utilize code generation to bind keys, maintaining high performance in both GUI and CLI environments.
*   **Sophisticated Rendering**: Built-in support for dynamic parameters, plurals, and gender-based localization, abstracting the complexity of the `intl` package.

### What Makes Localization Tedious?

The difficult part of localization is often not translating a single string, but managing the complete message engineering workflow:

*   Designing stable, meaningful keys for every message.
*   Distinguishing static text, validation or guard messages, and execution results.
*   Keeping message code, parameters, ICU expressions, and ARB resources synchronized.
*   Supporting both CLI and Flutter applications consistently.
*   Avoiding manual edits to generated files, missing locale files, and unnecessary repeated generation.

These tasks recur as a project grows. Developers must handle file paths, naming rules, generation order, and platform differences in addition to the text itself. This repeated coordination work is the complex and error-prone part of localization.

`basic_message` reduces that cost in three ways:

1.  **Conventions reduce decision-making costs**. Shared message lifecycles, five-level semantic coordinates, code ranges, and parameter rules give developers and teams a consistent understanding of each message.
2.  **Scripts remove repetitive work**. Generation tools handle the conversion between `MessageEnum`, ARB resources, and localized code, avoiding manual mapping while keeping changes verifiable and reproducible.
3.  **An AI Skill assists the workflow**. When developers use an AI coding assistant, the Skill can help identify localization candidates, classify `st`/`cd`/`rs` messages, validate ICU parameters, choose the correct generation commands, and ask whether to generate after a batch of edits is complete.

`basic_message` does not replace developers or translators. Instead, it gives repetitive, mechanical, and easily overlooked engineering work to established conventions and tools. This lets users focus on what matters: the business meaning and timing of a message, its parameters, and whether its expression is accurate and natural in each language.

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

*(For full automation, see our [Design Guide](L10N_DESIGN_GUIDE.md) and the [Example Repository](https://github.com/huanguan1978/messages)).*


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

Translation arguments may be Dart `Enum` values. `MessageEngine` automatically
uses the enum member name, so an ICU `select` branch can be called without
manually converting the value with `.name`:

```dart
enum MenuEntity { home, settings }

MessageEngine.tr(
  AppMessage.navigationLabel,
  args: {'label': MenuEntity.home},
);
```

### 5. Flutter Integration
**Step**: Add the shared message package dependency, run `flutter gen-l10n`, copy the `GuiMessageProvider` boilerplate and registry generator from the [Example Repository](https://github.com/huanguan1978/messages), and initialize `MessageEngine` within a `Builder` to gain `BuildContext` access.

```dart
// Conceptual snippet: please refer to 'gui_example' for the full implementation
import 'package:flutter/material.dart';
import 'package:basic_message/basic_message.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    MessageEngine.init(GuiMessageProvider(context));
    return MaterialApp(
      home: Scaffold(
        body: Text(MessageEngine.tr(AppMessage.welcomeLabel)),
      ),
    );
  }
}
```


## Resources

*   **[Design Guide](L10N_DESIGN_GUIDE.md)**: Deep dive into architecture, workflows, and best practices.
*   **[Naming Convention](L10N_NAMING_GUIDE2.md)**: Standardized four-level naming strategy for team consistency.
*   **[Example Repository](https://github.com/huanguan1978/messages)**: A complete, ready-to-run boilerplate including `share_message`, `cli_example`, and `gui_example`.
