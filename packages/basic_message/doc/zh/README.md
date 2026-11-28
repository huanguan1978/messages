# basic_message

[![pub package](https://img.shields.io/pub/v/basic_message.svg)](https://pub.dev/packages/basic_message)

一套"定义一次，多端复用，类型安全，编译时映射"的 Dart 多语言构建方案，专为 Flutter (GUI) 和 Dart (CLI) 双环境设计。通过结构化工程架构，实现跨平台的多语言共享，确保类型安全和编译时映射。

## 为什么选择 basic_message？

在开发 Dart/Flutter 全栈项目时，当你需要在 CLI、GUI、Server 等多个端之间共享多语言文案，你可能会面临以下问题：

- **代码重复**：多语言定义散落在各个端，无法有效共享和维护。
- **类型不安全**：依靠字符串 Key 来引用翻译，编译期无法发现缺失的翻译。
- **跨平台适配困难**：Flutter 需要 Context，CLI 不需要 Context，如何用一套代码同时支持两种场景？
- **文案管理混乱**：多语言资源缺乏统一标准，无法与第三方翻译平台集成。
- **参数渲染复杂**：支持变量、复数、性别等复杂的本地化需求变得很困难。
- **工程化成本高**：自动生成代码容易与手工修改产生冲突，维护成本大。

### 多语言开发真正繁琐的是什么？

多语言处理的难点，往往不只在于翻译一段文字，还在于如何管理整套消息工程：

- 如何为消息设计稳定且有意义的 Key。
- 如何区分静态文本、条件校验与执行结果。
- 如何同步消息代码、参数、ICU 表达式和 ARB 资源。
- 如何同时支持 CLI 与 Flutter。
- 如何避免手工修改生成文件、遗漏语言文件或重复执行生成步骤。

当项目逐渐变大时，这些操作会反复出现。开发者不仅要关注文案本身，还必须不断处理文件路径、命名规则、生成顺序和平台差异，真正复杂且容易出错的部分也正是这些重复工作。

`basic_message` 通过三种方式降低这部分成本：

1. **通过规范减少判断成本**：使用统一的消息生命周期、五级语义坐标、代码区间和参数约定，让开发者及团队对每一条消息形成一致理解。
2. **通过脚本减少重复劳动**：将 `MessageEnum`、ARB 资源和多语言代码之间的转换交给生成工具，避免手工维护映射，并让修改后的结果可以被验证和重复执行。
3. **通过 AI Skill 提供工作流辅助**：当开发者使用 AI 编程助手时，Skill 可以协助识别待本地化文本、判断 `st`/`cd`/`rs`，检查 ICU 参数、复用正确的生成命令，并在批量修改完成后再询问是否执行生成流程。

最终，`basic_message` 并不试图替代开发者或翻译人员，而是把重复、机械且容易遗漏的工程工作交给约定与工具。使用者可以将更多精力集中在真正重要的部分：消息的业务含义、出现时机、参数设计，以及不同语言中的表达是否准确自然。

`basic_message` 通过"统一接口包 (Core) + 平台适配层 (Provider)"的设计模式，系统性地解决了上述所有问题：

- **定义一次，多端复用**：在独立的共享包中定义一次消息枚举，CLI/GUI/Server 均可复用，彻底消除代码重复。
- **类型安全**：基于 `MessageEnum` 接口和 Dart 的 `enum`，编译期就能捕获缺失的翻译 Key，从源头保证类型安全。
- **跨平台解耦**：通过 `MessageProvider` 接口，一套逻辑同时支持需要 Context 的 Flutter 和无需 Context 的 CLI，无缝跨平台。
- **标准化文案管理**：集成 `ARB` 国际化标准，与官方 `intl_translation` 包无缝配合，支持第三方翻译平台进行版本化管理。
- **灵活的参数渲染**：统一的参数机制，底层支持动态参数、复数和性别本地化，屏蔽 `intl` 的复杂性。
- **工程化隔离**：提供 CLI 工具自动生成映射表，不修改自动生成的代码，通过代码工具实现编译时映射，无运行开销。

这是目前多语言共享的最优解，方案的执行效果取决于开发者的实施情况。

## 快速入门

### 工作流概览

`basic_message` 的核心工作流如下：

创建共享包定义消息 → 生成 ARB 文件（多语言基础）→ 在 CLI/GUI 项目中集成 → 通过 `MessageEngine.tr()` 调用翻译

以下是详细的集成步骤：

### 1. 安装

```bash
dart pub add basic_message
```

### 2. 定义消息枚举（共享包）

建议创建一个独立的包（例如 `share_message`）来定义消息枚举，这样可以在 CLI、GUI、Server 等多个应用中共享消息定义，实现代码层面的数据共享。

**在共享包的 pubspec.yaml 中添加依赖：**

```yaml
dependencies:
  basic_message: ^1.0.0
```

然后在该包中创建 `enum` 实现 `MessageEnum`：

```dart
// packages/share_message/lib/src/share_message_base.dart
import 'package:basic_message/basic_message.dart';

enum AppMessage implements MessageEnum {
  welcomeLabel(
    1001,
    'home_index_header_welcome_label',
    'Welcome, {username}!',
    '欢迎信息',
    param: {'username': 'Guest'},
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

### 3. 生成 ARB 多语言资源文件（核心步骤）

**为什么这一步很关键：** ARB (Application Resource Bundle) 是 Google 标准化的多语言格式，是你整个本地化工作流的基础。一旦生成了 ARB 文件，你就可以轻松对接第三方翻译平台（如翻译管理系统）进行版本化管理。

`basic_message` 提供 CLI 工具和与 `intl_translation` 包的集成，自动生成标准 ARB 格式文件：

1. 使用 `basic_message:gen_msg_resource` 生成中间资源类
2. 结合 `intl_translation:extract_to_arb` 从资源类提取 ARB 文件
3. 翻译人员基于 ARB 文件进行多语言翻译
4. 使用 `intl_translation:generate_from_arb` 生成多语言 Dart 代码

> 第 3 步若要交给 AI 完成整盘翻译，请阅读 [AI 多语言翻译作业指引](AI_TRANSLATION_GUIDE.md)。
> 适用前提：① 已按本节步骤完成接入——消息都定义好了、翻译文件的自动生成流程跑通了、程序能按语言切换显示文案了；② 英文底稿 `intl_en.arb` 已稳定不再改动——底稿没稳就开翻，之后每轮改动都可能引起重译。

**自动化支持：** 完整的自动化流程和脚本示例，请参考[详细设计指南](L10N_DESIGN_GUIDE.md)。你也可以使用 [ft:FileTools](https://pub.dev/packages/filetools) 结合示例仓库的配置，实现完全自动化的代码生成工作流。

### 4. CLI 端集成

**在你的 CLI 项目中：** 添加对共享包的依赖，然后实现 `CliMessageProvider`（复制示例仓库的样板代码），最后初始化引擎：

```dart
import 'package:basic_message/basic_message.dart';

void main() {
  MessageEngine.init(CliMessageProvider('en'));
  print(MessageEngine.tr(AppMessage.welcomeLabel, args: {'username': 'Alice'}));
}
```

注意：以上为语义代码，不完整且不可执行。完整可运行的 `CliMessageProvider` 样板代码，请参考示例仓库。

翻译参数也可以直接传入 Dart `Enum` 值。`MessageEngine` 会自动使用枚举成员名，
因此 ICU `select` 分支无需调用方手动转换 `.name`：

```dart
enum MenuEntity { home, settings }

MessageEngine.tr(
  AppMessage.navigationLabel,
  args: {'label': MenuEntity.home},
);
```

### 5. Flutter 端集成

**在你的 Flutter 项目中：** 添加对共享包的依赖，运行 `flutter gen-l10n` 生成本地化类，然后实现 `GuiMessageProvider`（复制示例仓库的样板代码），最后初始化引擎：

```dart
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

注意：以上为语义代码，不完整且不可执行。完整可运行的 `GuiMessageProvider` 样板代码，请参考示例仓库。

## AI 编码助手 Skill

`basic_message` 提供 `basic-message-l10n` Skill，用于帮助 AI 编码助手遵循 L10N v2 命名规范，正确处理消息分类、ICU 参数、ARB 资源和代码生成流程。

### 为 VS Code Copilot 安装

在已经添加 `basic_message` 依赖的 Dart 或 Flutter 项目根目录中运行：

```bash
dart pub get
dart run skills@ get -p basic_message --agent copilot
```

`-p basic_message` 会将发现范围限制为 `basic_message` 提供的 Skill。命令仍会显示交互式选择列表，请在列表中选择：

```text
basic-message-l10n
```

Skill 将被安装到项目的 `.github/skills/` 目录中，这是 VS Code GitHub Copilot 使用的项目级 Skill 目录。仅添加依赖或运行 `dart pub get` 不会自动安装 Skill。

安装完成后，重新打开项目或创建新的 Copilot Chat 会话。Skill 通常可以通过 `/` 菜单查看，也可以让 Copilot 根据当前请求尝试选择。能够发现 Skill 并不代表每次相关请求都会自动触发它。

### 其他 AI 编码助手

`skills` CLI 也支持 Antigravity 等其他 AI 编码助手。对于同一个 `basic_message` Skill，只需将 Agent 参数替换为：

```bash
dart run skills@ get -p basic_message --agent antigravity
```

不同编码助手会使用不同的项目级 Skill 目录。可通过以下命令查看当前 `skills` CLI 支持的 Agent：

```bash
dart run skills@ get --help
```

支持列表可能随 CLI 版本更新，详细说明请参阅 [skills CLI 文档](https://pub.dev/packages/skills)。

## 更多资源

### 文档

- [详细设计指南](L10N_DESIGN_GUIDE.md)：深入了解架构设计、工程化流程和完整的代码示例
- [统一命名规范](L10N_NAMING_GUIDE2.md)：统一的多语言 Key 命名规范，保证团队协作的一致性
- [分层本地化策略](L10N_STRATEGY_GUIDE.md)：按用户角色规划本地化优先级，区分新手主线、专家负载与技术标识符
- [AI 多语言翻译作业指引](AI_TRANSLATION_GUIDE.md)：完成上述接入步骤、且英文底稿 `intl_en.arb` 稳定后，用 AI 完成整盘语言翻译的作业协议（AI 先全局归类分批、定术语表，再逐批翻译并逐批自动检查），含配套工具 `gen_msg_analyzer` 用法与可直接复制的 AI 会话模板

### 示例项目

查看完整可运行的示例项目：[messages 示例仓库](https://github.com/huanguan1978/messages)

该仓库包含：
- `basic_message`：核心库
- `share_message`：共享的消息定义包
- `cli_example`：CLI 应用完整示例
- `gui_example`：Flutter 应用完整示例
