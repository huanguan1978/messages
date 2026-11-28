[English](https://github.com/huanguan1978/messages/tree/main/packages/basic_message/doc/en) |
[Chinese](https://github.com/huanguan1978/messages/tree/main/packages/basic_message/doc/zh)


# basic_message

A structured, type-safe localization framework for Dart, designed for
cross-platform projects that share messages between Flutter UI and Dart CLI
code. It enables "define once, use anywhere" by decoupling business logic from
platform-specific translation implementations.

[![pub package](https://img.shields.io/pub/v/basic_message.svg)](https://pub.dev/packages/basic_message)

## Why basic_message?

Building a full-stack Dart/Flutter project often leads to fragmented localization management. `basic_message` solves these common pain points:

*   **Unified definitions**: Define messages in a shared package and reuse them across CLI, GUI, and server code.
*   **Type safety**: Use Dart enums and generics to catch missing translation keys at compile time.
*   **Platform decoupling**: Use a common `MessageProvider` interface for context-dependent Flutter apps and context-free CLI tools.
*   **ARB support**: Use the Application Resource Bundle format with standard translation tooling.
*   **Generated bindings**: Generate typed access to messages instead of maintaining manual runtime mappings.
*   **Rich formatting**: Handle dynamic parameters, plurals, and gender-based messages while keeping `intl` details out of business logic.

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
3.  **An AI Skill assists authorized work**. When developers use an AI coding assistant, the Skill can process explicitly selected components, classify their `st`/`cd`/`rs` messages, validate ICU parameters, choose the correct generation commands, and ask whether to generate after a batch of edits is complete.

`basic_message` does not replace developers or translators. It moves repetitive,
mechanical, and easily overlooked engineering work into established
conventions and tools. This lets teams focus on the message's business meaning,
timing, parameters, and natural expression in each language.

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
  basic_message: ^1.0.7
```

```dart
// packages/share_message/lib/src/share_message_base.dart
import 'package:basic_message/basic_message.dart';

enum AppMessage implements MessageEnum {
  /// st_profile_home_header_welcomeLabel
  welcomeLabel(
    20001,
    'st_profile_home_header_welcomeLabel',
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

> To hand step 3 entirely to AI, read the [AI Translation Workflow Guide](doc/en/AI_TRANSLATION_GUIDE.md).
> Prerequisites: (1) the integration steps in this section are complete — messages are defined, the automated generation flow for translation files works, and the app displays text by active locale; (2) the English baseline `intl_en.arb` is stable and no longer changing — starting on an unstable baseline means every later change may trigger retranslation.

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

`basic_message` is a pure Dart package and does not include
Flutter-specific `GuiMessageInitializer`. Copy its implementation from
`gui_example` and adjust the imports for your project.

## v2 Global Guidance Update (v1.0.7)

Version `1.0.7` establishes two complementary global guides for localization
work:

1. **[Tiered Localization Strategy](doc/en/L10N_STRATEGY_GUIDE.md)** determines
   what should be localized first. It separates the beginner workflow from
   advanced payload and explains when technical identifiers may retain their
   original form.
2. **[Naming & Workflow Convention](doc/en/L10N_NAMING_GUIDE2.md)** determines
   how messages that enter the localization system are organized. It defines the
   `st`/`cd`/`rs` lifecycle, five-level semantic coordinates, metadata, and
   generation workflow.

Together, these guides provide a complete engineering model:

> The strategy defines **what enters localization and why**; the naming
> convention defines **how it is classified, named, generated, and maintained**.

### AI Agent Integration

The package includes an AI Agent Skill that applies both guides within a
developer-authorized scope. It distinguishes program identifiers from
user-facing text, classifies included messages with the v2 naming convention,
and generates and validates localization resources.

The Skill does not choose the product's beginner workflow or advanced area.
Developers explicitly select the component or components to process, and nested
or reused child components require separate selection. The Agent then works only
within that authorized scope.

The published Skill is stored in the package-root `skills/` directory so it can
be discovered by the official Dart `skills` tooling.

#### Install for VS Code Copilot

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

The Skill is installed in the project's `.github/skills/` directory, the
project-level Skill location used by GitHub Copilot in VS Code. Adding the
dependency or running `dart pub get` alone does not install it.

After installation, reopen the project or start a new Copilot Chat session.
The Skill can usually be found in the `/` menu, or Copilot can be asked to
choose it for the current task. Discovering a Skill does not guarantee that it
will automatically activate for every related request.

#### Other AI coding assistants

The `skills` CLI also supports Antigravity and other AI coding assistants. To
install the same Skill for Antigravity, change the Agent selection:

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

### Real-world Implementation References

These reference implementations show how to integrate `basic_message` into
real CLI and GUI products:

*   **CLI localization**: [chapose](https://github.com/huanguan1978/chacrypt/tree/main/chapose), a command-line file encryption and decryption tool.
*   **GUI localization**: [chabox](https://github.com/huanguan1978/chacrypt/tree/main/chabox), a desktop application for personal privacy and secure file storage.

Both modules belong to the [chacrypt](https://github.com/huanguan1978/chacrypt)
project, which focuses on offline file security and data sovereignty.

## Resources

*   **[Design Guide](doc/en/L10N_DESIGN_GUIDE.md)**: Architecture, implementation details, and generation workflows.
*   **[Localization Strategy](doc/en/L10N_STRATEGY_GUIDE.md)**: Localization tiers, user workflows, skeleton/payload boundaries, and technical identifiers.
*   **[Naming & Workflow Convention](doc/en/L10N_NAMING_GUIDE2.md)**: Five-level keys, lifecycle classification, metadata, and message-generation rules.
*   **[AI Translation Workflow Guide](doc/en/AI_TRANSLATION_GUIDE.md)**: After completing the integration steps above and once the English baseline `intl_en.arb` is stable, hand the full translation of a language to AI using this protocol (AI groups messages globally and sets the glossary first, then translates batch by batch with automated checks per batch). Includes the companion tool `gen_msg_analyzer` and copy-paste AI session templates.
*   **[Example Repository](https://github.com/huanguan1978/messages)**: A complete, ready-to-run boilerplate including `share_message`, `cli_example`, and `gui_example`.
