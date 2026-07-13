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

## 更多资源

### 文档

- [详细设计指南](L10N_DESIGN_GUIDE.md)：深入了解架构设计、工程化流程和完整的代码示例
- [统一命名规范](L10N_NAMING_GUIDE2.md)：统一的多语言 Key 命名规范，保证团队协作的一致性

### 示例项目

查看完整可运行的示例项目：[messages 示例仓库](https://github.com/huanguan1978/messages)

该仓库包含：
- `basic_message`：核心库
- `share_message`：共享的消息定义包
- `cli_example`：CLI 应用完整示例
- `gui_example`：Flutter 应用完整示例

