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

> To hand step 3 entirely to AI, read the [AI Translation Workflow Guide](AI_TRANSLATION_GUIDE.md).
> Prerequisites: (1) you have completed the integration steps in this section — messages are defined, the automated generation flow for translation files works, and the app displays text by active locale; (2) the English baseline `intl_en.arb` is stable and no longer changing — starting translation on an unstable baseline means every later change may trigger retranslation.

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


## AI Coding Assistant Skill

`basic_message` provides the `basic-message-l10n` Skill to help AI coding
assistants follow the L10N v2 naming convention and correctly handle message
classification, ICU parameters, ARB resources, and code generation workflows.

### Install for VS Code Copilot

From the root of a Dart or Flutter project that depends on `basic_message`, run:

```bash
dart pub get
dart run skills@ get -p basic_message --agent copilot
```

`-p basic_message` limits discovery to Skills provided by this package. The
command still displays an interactive selection list; select:

```text
basic-message-l10n
```

The Skill is installed in the project's `.github/skills/` directory, which is
the project-level Skill directory used by GitHub Copilot in VS Code. Adding the
dependency or running `dart pub get` alone does not install the Skill.

After installation, reopen the project or start a new Copilot Chat session.
The Skill can usually be found in the `/` menu, or Copilot can be asked to
choose it for the current task. Discovering a Skill does not guarantee that it
will automatically activate for every related request.

### Other AI Coding Assistants

The `skills` CLI also supports Antigravity and other AI coding assistants. To
install the same `basic_message` Skill for Antigravity, replace the Agent
selection:

```bash
dart run skills@ get -p basic_message --agent antigravity
```

Each coding assistant may use a different project-level Skill directory. Check
the Agent options supported by the current CLI version with:

```bash
dart run skills@ get --help
```

The supported list may change between CLI versions. See the
[`skills` CLI documentation](https://pub.dev/packages/skills) for details.

## Resources

*   **[Design Guide](L10N_DESIGN_GUIDE.md)**: Deep dive into architecture, workflows, and best practices.
*   **[Naming Convention](L10N_NAMING_GUIDE2.md)**: Five-level semantic naming and workflow convention for consistent team usage.
*   **[Localization Strategy](L10N_STRATEGY_GUIDE.md)**: Prioritize localization by user role, separating the beginner workflow, advanced payload, and technical identifiers.
*   **[AI Translation Workflow Guide](AI_TRANSLATION_GUIDE.md)**: After completing the integration steps above and once the English baseline `intl_en.arb` is stable, hand the full translation of a language to AI using this protocol (AI groups messages globally and sets the glossary first, then translates batch by batch with automated checks per batch). Includes the companion tool `gen_msg_analyzer` and copy-paste AI session templates.
*   **[Example Repository](https://github.com/huanguan1978/messages)**: A complete, ready-to-run boilerplate including `share_message`, `cli_example`, and `gui_example`.
