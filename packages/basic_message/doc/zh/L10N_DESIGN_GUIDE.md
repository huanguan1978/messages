# BASIC MESSAGE (多语言构建方案)

`basic_message`通过一套结构化、可扩展的工程架构方案，来处理 Flutter (GUI) 和 Dart (CLI) 双环境下的多语言共享。

### 一、 核心需求提炼
1.  **数据分类与管理**：使用统一的命名规范（四级命名约定）和信息类型（类似日志类型）对信息进行分类。
2.  **跨平台解耦**：一套逻辑同时支持 Flutter（需要 Context）和 CLI（无需 Context）。
3.  **强类型约束**：利用 Dart 的 `enum` 和泛型，保证开发时的类型安全和代码自动补全。
4.  **多语言支持**：集成 `ARB` 国际化标准，且提供默认兜底文案（Fallback），可基于`ARB`标准配合第三方翻译平台实现更多语言的本地化。
5.  **参数动态渲染**：支持带变量的提示信息（`Intl.message`的args参数，也可以用参数传递日期时间及货币本地化），以及复数(`Intl.plural`)和属性(`Intl.gender`)本地化处理。
6.  **工程化隔离**：核心逻辑提取为通用包，避免修改自动生成的 Flutter 本地化代码。

---

### 二、 架构方案概览
采用 **“统一接口包 (Core) + 平台适配层 (Provider)”** 的设计模式。

*   **`basic_message` (核心库)**：定义协议和引擎，不依赖任何 GUI 框架。
*   **`Flutter/CLI 宿主项目`**：实现具体的翻译逻辑（Resolver），并注册到引擎中。

---

### 三、 核心实现代码（通用库 `basic_message`）

#### 1、 `basic_message` 包的结构设计

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

#### 2. 定义接口
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

此方案以“CLI 为源头、Flutter 为下游”的架构演进进行了深度整合。通过将 `basic_message` 封装为独立库，我们实现了一套**“定义一次，多端复用，类型安全，编译时映射”**的工业级国际化标准。


### 四、 核心架构总结：双层闭环设计

该方案将国际化逻辑分为 **核心协议层** 和 **平台适配层**：

1.  **核心协议层 (`basic_message`)**：定义了 `MessageEnum` 接口和 `MessageEngine` 引擎。它完全独立，不包含任何业务文案，仅负责“翻译分发”。
2.  **平台适配层 (`Resolver`)**：
    *   **CLI 端**：利用 `intl` 包的 `Intl.message` 原生反射特性，直接读取资源，无需中间映射表。
    *   **GUI 端 (Flutter)**：由于 Flutter 的静态编译限制，通过 `basic_message` 提供的代码生成工具(`gen_msg_registry.dart`)，在编译前解析 `AppLocalizations`，生成静态的 `registry.g.dart`，实现无运行开销的翻译绑定。

---

### 五、 工程化落地流程 (Standard Operating Procedure)

#### 第一阶段：定义 (以 CLI/核心库为中心)
1.  **定义业务**：在核心库中创建 `enum AppMessage` 实现 `MessageEnum`。
2.  **提取文案**：先使用 `gen_msg_resource.dart` 把  `enum AppMessage` 转生成 `intl_translation:extract_to_arb` 可以分析的内含 `Intl.message` 数据类源代码, 再使用 `intl_translation:extract_to_arb` 从数据类源代码提取 `messages.arb`。
3.  **标准化**：`arb` 文件作为所有环境（CLI/GUI）唯一的“事实来源”。

#### 第二阶段：CLI 应用集成
CLI 直接作为“源头”消费核心库，无需处理 GUI 的静态限制。
*   **实现**：调用 `MessageEngine.init(CliMessageProvider())`。
*   **原理**：`CliMessageProvider` 内部直接调用 `Intl.message`，根据 `name` (即 `MessageEnum.key`) 自动匹配由 `generate_from_arb` 生成的 `messages_<locale>.dart`。

#### 第三阶段：Flutter 应用扩展
作为下游，Flutter 引入 `basic_message` 并通过工具补齐桥接。
1.  **生成 L10n**：运行 `flutter gen-l10n`，生成 `AppLocalizations` 类。
2.  **自动绑定**：运行 `basic_message` 提供的 CLI 工具：
    `gen-msg-registry --l10n-class=AppLocalizations --output=lib/generated/registry.g.dart`
    *该工具可以用 `package:analyzer` 读取 `AppLocalizations` 的方法签名，自动生成映射表。*
3.  **配置与调用**：在初始化时 `MessageEngine.init(FlutterResolver(l10n, registry))`。

---


### 六、 为什么这套方案是“终极方案”？

| 需求点 | 解决方案 | 优势 |
| :--- | :--- | :--- |
| **数据分类** | `MessageEnum` | 基于枚举值及属性可支持现代 IDE 代码补全。 |
| **工具链解耦** | `MessageEnum.key` | Key 作为业务信息唯一标识，可以实现代码逻辑与文案资源的完全隔离。 |
| **可扩展架构** | `MessageProvider` | 核心逻辑与用户端业务分离，适配层逻辑用户可高度自定义。 |
| **类型安全** | Dart Generics | 利用 Dart 强类型，编译期捕获缺失的翻译 Key。 |
| **动态渲染** | `Map<String, Object>? args` | 统一的变量传参格式，屏蔽 `intl` 内部细节。 |
| **工程化隔离** | `gen-msg-registry` | 自动生成映射，不修改 `flutter_gen` 生成的代码。 |
| **兜底机制** | `defaultMessage` | 若翻译缺失，自动回退至兜底文案，保证应用不 Crash。 |

---

### 七、 给开发者的实施建议 

1.  **对于纯 Dart 开发者**：直接通过 `MessageEngine.tr(MyMessage.error)` 调用，配合 `intl` 原生工具链，这是最轻量、最符合 Dart 生态的用法。
2.  **对于 Flutter 开发者**：请将 `basic_message` 作为“胶水层”。只需确保每次修改 `ARB` 后，先运行 `flutter gen-l10n`，再运行 `gen-msg-registry`。通过这两个命令，你不仅拥有了 Flutter 的性能，还获得了与 CLI 一致的类型安全代码体验。


### 八、应用层实现示例

#### 1. 定义业务信息枚举（宿主项目[workspace:messages, package: share_message]）

`key`命名请遵守[四级命名约定](L10N_NAMING_GUIDE2.md).
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
#### 2. CLI 端实现 (Resolver [workspace:messages, package: cli_example])
CLI 端逻辑简单，直接利用 `intl` 包。

**把业务信息枚举转资源数据类**：运行 `basic_message` 提供的 CLI 工具：
```shell
# Generate message resources from the base definition file
dart run basic_message:gen_msg_resource -i packages/share_message/lib/src/share_message_base.dart -o packages/cli_example/lib/generated/messages_resource.g.dart 

```

**从资源数据类提取ARB文件**：使用 `intl_translation:extract_to_arb` 得到 `intl_messages.arb`：
    `intl_translation:extract_to_arb --output-dir=lib/l10n lib/generated/resource.g.dart`
```shell
# Generate the .arb files for translation
dart run intl_translation:extract_to_arb --output-dir=packages/cli_example/lib/l10n packages/cli_example/lib/generated/messages_resource.g.dart
```

**用户自已翻译ARB文件之后转成多语言DART文件**：
```shell
# Rename the generated .arb file to match the locale (e.g., intl_en.arb for English), and add the @@locale key (e.g., "@@locale": "en") to the .arb file.
mv packages/cli_example/lib/l10n/intl_messages.arb packages/cli_example/lib/l10n/intl_en.arb

# After translating the .arb files, generate the Dart code for message resolution
dart run intl_translation:generate_from_arb --output-dir=packages/cli_example/lib/generated/ packages/cli_example/lib/generated/messages_resource.g.dart packages/cli_example/lib/l10n/intl_*.arb
```


**实现CLI端消息供应者
```dart
# packages/cli_example/lib/cli_message_provider.dart

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

**CLI 应用初始化：**
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

#### 3. Flutter 端实现 (Resolver [workspace:messages, package: gui_example])
Flutter 端逻辑，并不复杂，一看就会。

首先定义必需的`l10n.yaml`，内容大致如下:
```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: intl_en.arb 
output-localization-file: app_localizations.dart
```

接着复制上述CLI示例中已翻译好的`arb`文件到`arb-dir`设置的目录中后，用`flutter l10n-gen`生成`app_localizations.dart`。
```shell
cp packages/cli_example/lib/l10n/intl_*.arb packages/gui_example/lib/l10n/
cd packages/gui_example
flutter l10n-gen
```

接着用`basic_message:gen_msg_registry`分析`app_localizations.dart`生成映射表。
```shell
dart run basic_message:gen_msg_registry
```

再接着生成GUI端的信息供应者，示例如下：
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


**CLI 应用初始化，也是最后一步：**
```dart
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

九、完整示例项目说明

完整示例项目源代码参见 https://github.com/huanguan1978/messages

示例项目，涉及到工作空间(workspace: messages)下，致四个包，分别为：
1. name: basic_message, desc: 核心约定包，已发pub.dev.
2. name: share_message, desc: 你自已的共享信息定义.
3. name: cli_example,   desc: CLI端完整示例
4. name: gui_example,   desc: GUI端完整示例

为了减少终端命令行手工操作，已把CLI示例中的两步重要操作用`ft:FileTools`工具进行了封装，封装如下：

1. CLI端，业务信息生成ARB文件，`ft shell . --config=ft-messages-multilanguage.yaml --blocks=gen_arb_scripts`
2. CLI端，ARB文件生生多语言库，`ft shell . --config=ft-messages-multilanguage.yaml --blocks=gen_from_arb_scripts`
3. GUI端，基于`l10n.yaml`配置和`flutter gen-l10n`，生成映射表，`ft shell --config=ft-messages-multilanguage.yaml --blocks=flutter_gen_scripts`

为什么要用`ft:FileTools`，请参阅下述：

- [Why ft? Beyond Shell Scripts and Standard Toolchains](https://github.com/huanguan1978/ft/blob/main/doc/en/FAQ.md)
- [ft: FileTools - High-Performance Cross-Platform File Management & Automation](https://pub.dev/packages/filetools)

- Dart和Flutter用户，一键安装：`dart pub global activate --executable=ft filetools`

---

性能优化：排除生成代码 (`lib/generated`)

为避免开发时对自动生成的代码进行格式化与索引，建议进行如下配置：

**1. 禁用 VS Code 自动格式化**
在 `.vscode/settings.json` 添加：
```json
{ "dart.formatExclude": ["lib/generated/**"] }
```

**2. 排除 Dart 静态分析**
在 `analysis_options.yaml` 添加：
```yaml
analyzer:
  exclude: [lib/generated/**]
```

**3. 强制锁定格式 (生成器模板专用)**
在生成器模板**文件顶部**添加：
```dart
// dart format off
```

---
**原因说明：**
* **`formatExclude`**：防止保存时编辑器触发格式化导致卡顿。
* **`analyzer.exclude`**：防止 IDE 频繁扫描生成文件，提升运行响应速度。
* **`// dart format off`**：从根源上锁定格式，防止任何环境（IDE 或命令行）意外修改代码。


十、架构优势总结

1.  **工程化路径明确**：基于 `MessageEnum` 实现自已的`AppMessage`定义 -> `gen_msg_resource` 生成中间资源 -> `intl` 原生工具链 -> `gen_msg_registry` 映射绑定，这是一个完整的闭环。
2.  **协议极简**：`MessageEngine` 本身不需要知道翻译的具体实现，只负责调度。
3.  **兼容性极强**：通过 `Provider` 模式，既能跑在 `intl` 体系下，也能在单母语模式下作为“静态资源常量池”使用。
