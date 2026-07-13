# Basic Message: A Practical Guide

This document helps you **understand the workflow and collaborative process of `basic_message`**. By reviewing this architectural overview, you can visualize the process before diving into the [Example Repository](https://github.com/huanguan1978/messages) for hands-on practice.

## I. Architectural Overview

The core workflow of `basic_message` is a seamless end-to-end pipeline:

```
┌─────────────────────────────────────────────────────────────────┐
│       Message Definition (Shared Package)                       │
│  enum AppMessage implements MessageEnum {                       │
│    welcomeLabel(1001, 'home_index_welcome_label', ...);         │
│  }                                                              │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│       ARB Files (Collaboration Hub)        
│  {                                                               
│    "home_index_welcome_label": "Welcome, {username}!"            
│  }                                                               
│  • Source for translators to perform localization                                  
│  • Version-controlled via translation platforms                                 
└────────┬──────────────────────────┬──────────────────────────────┘
         │                          │
         ▼                          ▼
    CLI Workflow                GUI Workflow
  ┌───────────────┐           ┌──────────────────┐
  │  CliProvider  │           │ GuiProvider      │
  │ Intl.message  │           │ AppLocalizations │
  └──────┬────────┘           └─────┬────────────┘
         │                          │
         ▼                          ▼
  MessageEngine.tr()         MessageEngine.tr()
  Returns localized text     Returns localized text
```

**Workflow Interpretation:**
1. **Message Definition**: Define once in a shared package to be used by all platforms.
2. **ARB Generation**: Use `basic_message:gen_msg_resource` + `intl_translation:extract_to_arb` to generate standard formats.
3. **Translation**: Translators work based on ARB files (supporting third-party TMS platforms).
4. **Integration**: CLI/GUI platforms implement their own Providers to call `MessageEngine.tr()` and retrieve translated text.

---

## II. Deep Dive into Core Concepts

### 1. MessageEnum - Type Manager
**Role:** The "data source" and "type constraint" for all messages.

```dart
enum AppMessage implements MessageEnum {
  welcomeLabel(
    1001,                                  // code: User-defined ID
    'home_index_welcome_label',            // key: ARB identifier
    'Welcome, {username}!',                // msg: Default fallback text
    'Shared welcome message',              // desc: optional description
    param: {'username': 'Guest'},          // param: Default parameters
  );
  
  // Property definitions...
}
```

**Design Philosophy:**
- `code`: Custom message ID for cross-system tracking.
- `key`: The unique ARB identifier, decoupling code from strings.
- `msg`: Provides a fallback string; prevents crashes if translation is missing.
- `param`: Defines dynamic parameters to prevent missing arguments.
- **Compile-time Safety**: `AppMessage.welcomeLabel` is far safer than raw strings.

### 2. MessageProvider - Translation Driver
**Role:** An adapter layer that converts `MessageEnum` into localized text.

```dart
// CLI: Uses official intl toolchain
class CliMessageProvider extends MessageProvider<AppMessage> {
  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    return Intl.message(message.msg, name: message.key, args: args?.values.toList());
  }
}

// GUI: Based on Flutter's generated AppLocalizations
class GuiMessageProvider extends MessageProvider<AppMessage> {
  final AppLocalizations l10n;
  
  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    return resolveL10n(l10n, message.key, args);
  }
}
```


### 3. MessageEngine: The Translation Dispatcher
A global entry point that hides implementation details of the underlying `Provider`.
*   **Singleton Pattern**: Initialize once in `main()` to share across the entire app.
*   **Context-Free**: Eliminates the need for "Context drilling" in Flutter.

```dart
class MessageEngine {
  static MessageProvider? _provider;
  
  static void init(MessageProvider provider) {
    _provider = provider;
  }
  
  static String tr<T extends MessageEnum>(T message, {Map<String, Object>? args}) {
    if (_provider == null) {
      return _renderFallback(message.msg, args); 
    }
    return _provider!.resolve(message, args: args);
  }
}
```

**Workflow：**
```dart
// Initialize once in main()
MessageEngine.init(CliMessageProvider('en'));

// Call anywhere
print(MessageEngine.tr(AppMessage.welcomeLabel, args: {'username': 'Alice'}));
// output：Welcome，Alice！
```


### 4. ARB Files: The Bridge
Standardized format for developer-translator collaboration.
*   **Google Standard**: Native compatibility with the Flutter/Dart toolchain.
*   **Rich Features**: Native support for parameters (`{param}`), pluralization, and gender-based selection.

```json
// intl_en.arb
{
  "@@locale": "en",
  "home_index_welcome_label": "Welcome, {username}!",
  "home_index_counter_label": "{count, plural, =0{No items} one{One item} other{# items}}",
  "common_global_gender_label": "{gender, select, male{He} female{She} other{They}}"
}

// intl_zh.arb 
{
  "@@locale": "zh",
  "home_index_welcome_label": "欢迎，{username}！",
  "home_index_counter_label": "{count, plural, =0{没有项目} one{一个项目} other{# 个项目}}",
  "common_global_gender_label": "{gender, select, male{他} female{她} other{他们}}"
}
```

---

## III. End-to-End Collaboration Example

Scenario: Internationalized Application Supporting CLI and GUI

### Step 1: Define Messages
Define your messages in a shared package, adhering to the [Naming Convention](I10N_NAMING_GUIDE2.md).

```dart
// packages/share_message/lib/src/app_message.dart
enum AppMessage implements MessageEnum {
  commonGlobalActionSubmitAction(
    2001,
    'common_global_action_submit_action',
    'Submit',
    'Global submit button text',
  ),
  homeIndexCounterIncrementLabel(
    1001,
    'home_index_counter_increment_label',
    'You have pushed the button: {count} times',
    'Counter display with parameter',
    param: {'count': 0},
  ),
  homeIndexHeaderWelcomeLabel(
    1002,
    'home_index_header_welcome_label',
    'Welcome, {username}!',
    'Personalized welcome message',
    param: {'username': 'Guest'},
  );
  
  // Implementation of MessageEnum interface...
}
```

### Step 2: Generate ARB

```bash
# 1. Convert message enum to resource class
# dart run basic_message:gen_msg_resource -i <appmessage_file> -o <resource_file>
dart run basic_message:gen_msg_resource \
  -i packages/share_message/lib/src/app_message.dart \
  -o packages/share_message/lib/generated/messages_resource.g.dart

# 2. Extract to ARB
# dart run intl_translation:extract_to_arb --output-dir=<l10n_dir> <resource_file>

dart run intl_translation:extract_to_arb \
  --output-dir=packages/share_message/lib/l10n \
  packages/share_message/lib/generated/messages_resource.g.dart
```

**result：**
```
packages/share_message/lib/l10n/
├── intl_messages.arb        # default file name
├── intl_en.arb              # en（copy default to en）
└── intl_zh.arb              # zh（copy default to zh）
```


### Step 3: CLI Integration

```dart
// packages/cli_example/lib/cli_message_provider.dart
import 'package:intl/intl.dart';
import 'package:share_message/share_message.dart';

class CliMessageProvider extends MessageProvider<AppMessage> {
  final String locale;
  
  CliMessageProvider(this.locale);
  
  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    return Intl.message(
      message.msg,
      name: message.key,
      args: args?.values.toList(),
      locale: locale,
    );
  }
}

// CLI entry point
void main() async {
  await initializeMessages('zh');  // load messages_zh.dart
  MessageEngine.init(CliMessageProvider('zh'));
  
  print(MessageEngine.tr(AppMessage.homeIndexHeaderWelcomeLabel, args: {'username': 'Alice'}));
  // output（chinese）：欢迎，Alice！
}
```

**Collaboration process：**
```
AppMessage.homeIndexHeaderWelcomeLabel
    ↓
CliMessageProvider.resolve()
    ↓ (lookup key='home_index_header_welcome_label')
messages_zh.dart (same key)
    ↓
localized output："Welcome，Alice！"
```

### Step 4: GUI Integration

```dart
// packages/gui_example/lib/gui_message_provider.dart
import 'package:flutter/widgets.dart';
import 'package:share_message/share_message.dart';
import 'package:gui_example/l10n/app_localizations.dart';
import 'package:gui_example/l10n/messages_registry.g.dart';  // from basic_message:gen_msg_registry

class GuiMessageProvider extends MessageProvider<AppMessage> {
  final AppLocalizations l10n;
  
  GuiMessageProvider(this.l10n);
  
  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    // Method for mapping keys to AppLocalizations via the registry
    // For example, key='home_index_header_welcome_label' map to l10n.homeIndexHeaderWelcomeLabel(username)
    return resolveL10n(l10n, message.key, args);
  }
}

// Using in a Widget
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(MessageEngine.tr(AppMessage.homeIndexHeaderWelcomeLabel, args: {'username': 'Alice'})),
      ),
      body: Center(
        child: Column(
          children: [
            Text(MessageEngine.tr(AppMessage.homeIndexCounterIncrementLabel, args: {'count': 42})),
            ElevatedButton(
              onPressed: () {},
              child: Text(MessageEngine.tr(AppMessage.commonGlobalActionSubmitAction)),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Collaboration process：**
```
AppMessage.homeIndexHeaderWelcomeLabel
    ↓
GuiMessageProvider.resolve()
    ↓ (lookup key='home_index_header_welcome_label')
messages_registry.g.dart (registry)
    ↓
AppLocalizations.homeIndexHeaderWelcomeLabel(username)
    ↓
localized output："Welcome，Alice！"
```

---

## IV. Common Patterns

###  **Single-Language App**: Simply initialize the engine with the required locale once at startup.

```dart
void main() {
  // initialize once at startup
  MessageEngine.init(CliMessageProvider('en'));
  
  // call anywhere
  print(MessageEngine.tr(AppMessage.homeIndexHeaderWelcomeLabel, args: {'username': 'Bob'}));
}
```

###  **Multi-Language (Dynamic Switching)**: 

- **CLI**: Re-initialize the `CliMessageProvider` when the locale changes.
- **GUI**: Use a `ValueListenableBuilder` or `Provider` to rebuild the tree; update the `GuiMessageProvider` on locale changes.

**CLI Example：**
```dart
class LanguageSwitcher {
  static String currentLocale = 'en';
  
  static void setLocale(String locale) async {
    currentLocale = locale;
    await initializeMessages(locale);
    MessageEngine.init(CliMessageProvider(locale));
  }
}

// locale change
await LanguageSwitcher.setLocale('zh');
print(MessageEngine.tr(AppMessage.homeIndexHeaderWelcomeLabel));  // output chinese
```

**GUI Example：**
```dart
final ValueNotifier<Locale> localeNotifier = ValueNotifier(Locale('en'));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              MessageEngine.init(GuiMessageProvider(AppLocalizations.of(context)!));
              return HomePage();
            },
          ),
        );
      },
    );
  }
}

// locale change
void changeLanguage(String locale) {
  localeNotifier.value = Locale(locale);
}
```

### **Server + CLI + GUI Sharing**:

A single `MessageEnum` package serves all three tiers, with each platform implementing its own light `Provider`.

```
┌─────────────────────┐
│  share_message      │  
└──────┬─────┬────────┘
       │     │
    ┌──▼──┐┌─▼──┐┌──────┐
    │CLI  ││GUI ││Server│  
    └──┬──┘└─┬──┘└──┬───┘
       │     │      │
    ┌──▼──┐┌─▼──┐┌──▼────┐
    │CLI  ││GUI ││Server │  
    │Prv. ││Prv.││Prv.   │
    └─────┘└────┘└───────┘
```

## V. Development Workflow

1. Define new messages in the shared package (update `enum`).
2. Run `gen_msg_resource` to generate resource classes.
3. Run `extract_to_arb` to update ARB files.
4. Translators perform localization on ARB files.
5. Run `generate_from_arb` to generate localized Dart code.
6. Use `MessageEngine.tr()` to consume new messages.

*Tip: Use `ft:FileTools` with `ft-messages-multilanguage.yaml` for full automation of this pipeline.*

## Summary

| Component | Responsibility | Key Role |
|------|------|--------|
| **MessageEnum** | Definition | Type safety & Compile-time check |
| **ARB Files** | Collaboration | TMS integration & Versioning |
| **MessageProvider** | Translation | Hides CLI/GUI differences |
| **MessageEngine** | Dispatch | Global access & Provider switching |

Now, head over to the [Example Repository](https://github.com/huanguan1978/messages) and start your hands-on journey!
