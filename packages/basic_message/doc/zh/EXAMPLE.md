# basic_message 实战指南

本文档帮助你**理解 `basic_message` 的工作原理和协作流程**，通过"动眼不动手"看清架构，再进入[示例仓库](https://github.com/huanguan1978/messages)进行实战操作。

## 一、架构全景图

`basic_message` 的核心工作流是一条完整的链路：

```
┌─────────────────────────────────────────────────────────────────┐
│                    消息定义（共享包）                              │
│  enum AppMessage implements MessageEnum {                       │
│    welcomeLabel(1001, 'home_index_welcome_label', ...);         │
│  }                                                              │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│              ARB 文件（多语言协作枢纽）                              
│  {                                                               
│    "home_index_welcome_label": "Welcome, {username}!"            
│  }                                                               
│  • 翻译人员基于此文件进行多语言翻译                                   
│  • 可对接第三方翻译平台进行版本化管理                                 
└────────┬──────────────────────────┬──────────────────────────────┘
         │                          │
         ▼                          ▼
    CLI 端工作流                GUI 端工作流
  ┌───────────────┐           ┌──────────────────┐
  │  CliProvider  │           │ GuiProvider      │
  │ Intl.message  │           │ AppLocalizations │
  └──────┬────────┘           └─────┬────────────┘
         │                          │
         ▼                          ▼
  MessageEngine.tr()         MessageEngine.tr()
  返回当前语言文案              返回当前语言文案
```

**流程解读：**
1. **消息定义** → 在共享包中定义一次，供所有端使用
2. **ARB 生成** → `basic_message:gen_msg_resource` + `intl_translation:extract_to_arb` 生成标准格式
3. **多语言翻译** → 翻译人员基于 ARB 文件翻译（可用翻译管理平台）
4. **端集成** → CLI/GUI 各自实现 Provider，调用 `MessageEngine.tr()` 获取翻译

---

## 二、核心概念深入理解

### 1. MessageEnum - 类型管理器

**角色：** 所有消息的"数据源"和"类型约束"。

```dart
enum AppMessage implements MessageEnum {
  welcomeLabel(
    1001,                                  // code：用户自定义的ID
    'home_index_welcome_label',            // key：ARB 对应 key
    'Welcome, {username}!',                // msg：默认文案（兜底）
    'CI/GUI 共用的欢迎信息',                 // desc：描述
    param: {'username': 'Guest'},          // param：默认参数
  );
  
  // 属性定义...
}
```

**为什么这样设计：**
- `code` 自定义的消息ID，可用于跨端数据跟踪（如：API和CLI及GUI之间数据处理）
- `key` 作为 ARB 唯一标识符，解耦代码与文案
- `msg` 提供默认兜底文案，若翻译缺失不会 Crash
- `param` 定义动态参数的默认值，防止参数漏传
- **编译期类型检查**：`AppMessage.welcomeLabel` 比 `"home_index_welcome_label"` 字符串安全百倍

### 2. MessageProvider - 翻译驱动器

**角色：** 将 `MessageEnum` 转换为实际多语言文案的"适配层"。

```dart
// CLI 端：直接使用 intl 官方工具链
class CliMessageProvider extends MessageProvider<AppMessage> {
  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    // intl 根据 message.key 找到对应的翻译文件中的方法
    // 比如 key='home_index_welcome_label' 对应 messages_en.dart 中的同名方法
    return Intl.message(message.msg, name: message.key, args: args?.values.toList());
  }
}

// GUI 端：基于 Flutter 生成的 AppLocalizations
class GuiMessageProvider extends MessageProvider<AppMessage> {
  final AppLocalizations l10n;
  
  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    // 通过反射或生成的注册表，调用 l10n 中的相应方法
    // 比如 l10n.homeIndexWelcomeLabel(username: 'Alice')
    return resolveL10n(l10n, message.key, args);
  }
}
```

**为什么要分离 Provider：**
- CLI 和 GUI 的翻译源不同；intl 生成的文件（messages_all.dart） vs Flutter 生成的 （app_localizations.dart）
- 通过接口隔离，同一个 `MessageEnum` 可以被多个 Provider 使用
- 新增 Server 端只需再实现一个 Provider，无需修改 `MessageEnum`

### 3. MessageEngine - 翻译分发器

**角色：** 全局的翻译调用入口，屏蔽底层 Provider 差异。

```dart
class MessageEngine {
  static MessageProvider? _provider;
  
  // 初始化时注册 Provider
  static void init(MessageProvider provider) {
    _provider = provider;
  }
  
  // 统一的翻译调用接口
  static String tr<T extends MessageEnum>(T message, {Map<String, Object>? args}) {
    if (_provider == null) {
      return _renderFallback(message.msg, args);  // Provider 未初始化，使用兜底文案
    }
    return _provider!.resolve(message, args: args);
  }
}
```

**工作流程：**
```dart
// 在 main() 初始化一次
MessageEngine.init(CliMessageProvider('zh'));

// 之后任何地方都可以调用
print(MessageEngine.tr(AppMessage.welcomeLabel, args: {'username': 'Alice'}));
// 输出：欢迎，Alice！
```

**为什么设计这样：**
- 避免 Provider 从上到下"钻孔式"传递（Context drilling）
- Provider 是全局单例，初始化一次后全应用共享
- 不同语言切换时，更新 `_provider` 即可，无需重启应用

### 4. ARB 文件 - 多语言协作的通用格式

**角色：** 连接开发者和翻译团队的"桥梁"。

```json
// intl_en.arb
{
  "@@locale": "en",
  "home_index_welcome_label": "Welcome, {username}!",
  "home_index_counter_label": "{count, plural, =0{No items} one{One item} other{# items}}",
  "common_global_gender_label": "{gender, select, male{He} female{She} other{They}}"
}

// intl_zh.arb （翻译人员翻译）
{
  "@@locale": "zh",
  "home_index_welcome_label": "欢迎，{username}！",
  "home_index_counter_label": "{count, plural, =0{没有项目} one{一个项目} other{# 个项目}}",
  "common_global_gender_label": "{gender, select, male{他} female{她} other{他们}}"
}
```

**为什么 ARB 很关键：**
- **标准化格式**：Google 标准，与 Flutter/Dart 工具链原生支持
- **版本管理友好**：翻译平台（如 Crowdin、POEditor）都支持 ARB 格式
- **参数化支持**：原生支持 `{param}`、`plural`、`select` 等复杂本地化需求
- **团队协作**：开发者维护代码，翻译人员维护 ARB，各不相干

---

## 三、端对端的协作示例

### 场景：支持 CLI 和 GUI 的国际化应用

#### Step 1：共享包定义消息

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
  
  // 实现 MessageEnum 接口...
}
```

**关键点：**
- `key` 遵循[统一命名规范](L10N_NAMING_GUIDE.md)（四级结构）
- `msg` 是编程人员写的"英文兜底版本"
- `param` 列出所有可能的动态参数和默认值

#### Step 2：生成 ARB 文件

```bash
# 第一步：消息转资源类
dart run basic_message:gen_msg_resource \
  -i packages/share_message/lib/src/app_message.dart \
  -o packages/share_message/lib/generated/messages_resource.g.dart

# 第二步：从资源类提取 ARB
dart run intl_translation:extract_to_arb \
  --output-dir=packages/share_message/lib/l10n \
  packages/share_message/lib/generated/messages_resource.g.dart
```

**生成的文件：**
```
packages/share_message/lib/l10n/
├── intl_messages.arb        # 中间文件
├── intl_en.arb              # 英文（开发者维护）
└── intl_zh.arb              # 中文（翻译人员维护）
```

**关键点：**
- ARB 现在可以提交到版本控制系统
- 翻译人员基于这些文件翻译
- `basic_message` 提供的工具自动化了这个流程

#### Step 3：CLI 端集成

```dart
// packages/cli_example/lib/cli_message_provider.dart
import 'package:intl/intl.dart';
import 'package:share_message/share_message.dart';

class CliMessageProvider extends MessageProvider<AppMessage> {
  final String locale;
  
  CliMessageProvider(this.locale);
  
  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    // intl 自动在 messages_<locale>.dart 中查找同名方法
    return Intl.message(
      message.msg,
      name: message.key,
      args: args?.values.toList(),
      locale: locale,
    );
  }
}

// CLI 应用入口
void main() async {
  await initializeMessages('zh');  // 加载 messages_zh.dart
  MessageEngine.init(CliMessageProvider('zh'));
  
  // 现在可以调用翻译
  print(MessageEngine.tr(AppMessage.homeIndexHeaderWelcomeLabel, args: {'username': 'Alice'}));
  // 输出（中文）：欢迎，Alice！
}
```

**协作流程：**
```
AppMessage.homeIndexHeaderWelcomeLabel
    ↓
CliMessageProvider.resolve()
    ↓ (根据 key='home_index_header_welcome_label' 查找)
messages_zh.dart 中对应的方法
    ↓
返回翻译后的文案："欢迎，Alice！"
```

#### Step 4：GUI 端集成

```dart
// packages/gui_example/lib/gui_message_provider.dart
import 'package:flutter/widgets.dart';
import 'package:share_message/share_message.dart';
import 'package:gui_example/l10n/app_localizations.dart';
import 'package:gui_example/l10n/messages_registry.g.dart';  // 由 gen_msg_registry 生成

class GuiMessageProvider extends MessageProvider<AppMessage> {
  final AppLocalizations l10n;
  
  GuiMessageProvider(this.l10n);
  
  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    // 通过注册表映射 key 到 AppLocalizations 的方法
    // 比如 key='home_index_header_welcome_label' 映射到 l10n.homeIndexHeaderWelcomeLabel(username)
    return resolveL10n(l10n, message.key, args);
  }
}

// 在 Widget 中使用
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

**协作流程：**
```
AppMessage.homeIndexHeaderWelcomeLabel
    ↓
GuiMessageProvider.resolve()
    ↓ (根据 key='home_index_header_welcome_label' 查找)
messages_registry.g.dart 中的映射表
    ↓
AppLocalizations.homeIndexHeaderWelcomeLabel(username)
    ↓
返回翻译后的文案："欢迎，Alice！"
```

---

## 四、常见集成模式

### 模式 1：单语言应用

适用场景：只支持一种语言（如内部工具）。

```dart
void main() {
  // 只初始化一次，不需要动态切换
  MessageEngine.init(CliMessageProvider('en'));
  
  // 所有地方都是英文
  print(MessageEngine.tr(AppMessage.homeIndexHeaderWelcomeLabel, args: {'username': 'Bob'}));
}
```

### 模式 2：多语言应用（动态切换）

适用场景：支持多种语言，用户可动态切换。

**CLI 端：**
```dart
class LanguageSwitcher {
  static String currentLocale = 'en';
  
  static void setLocale(String locale) async {
    currentLocale = locale;
    await initializeMessages(locale);
    MessageEngine.init(CliMessageProvider(locale));
    
    // 切换后，所有 tr() 调用自动返回新语言
  }
}

// 使用
await LanguageSwitcher.setLocale('zh');
print(MessageEngine.tr(AppMessage.homeIndexHeaderWelcomeLabel));  // 输出中文
```

**Flutter 端：**
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
          // Flutter gen-l10n 自动生成当前 locale 对应的 AppLocalizations
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              // 语言切换时，自动重建 Provider
              MessageEngine.init(GuiMessageProvider(AppLocalizations.of(context)!));
              return HomePage();
            },
          ),
        );
      },
    );
  }
}

// 用户切换语言
void changeLanguage(String locale) {
  localeNotifier.value = Locale(locale);
  // Flutter 自动触发页面重建，Provider 自动更新
}
```

### 模式 3：Server + CLI + GUI 三端共享

```
┌─────────────────────┐
│  share_message      │  共享包
└──────┬─────┬────────┘
       │     │
    ┌──▼──┐┌─▼──┐┌──────┐
    │CLI  ││GUI ││Server│  各端依赖共享包
    └──┬──┘└─┬──┘└──┬───┘
       │     │      │
    ┌──▼──┐┌─▼──┐┌──▼────┐
    │CLI  ││GUI ││Server │  各端实现各自的 Provider
    │Prv. ││Prv.││Prv.   │
    └─────┘└────┘└───────┘
```

**关键优势：**
- 同一个 `AppMessage enum` 在三个端使用
- 翻译统一在 ARB 文件中维护
- 新增端只需再实现一个 Provider

---

## 五、后续深入学习路径

现在你已经理解了 `basic_message` 的**核心设计思想和工作流程**，下一步：

### 实战操作（动手）

进入 [messages 示例仓库](https://github.com/huanguan1978/messages)，clone 代码：

```bash
git clone https://github.com/huanguan1978/messages.git
cd messages
```

该仓库包含：
- **basic_message/**：本包的源代码
- **share_message/**：共享消息定义包（参考示例）
- **cli_example/**：CLI 应用完整实现
- **gui_example/**：Flutter GUI 应用完整实现

### 深入细节（参考文档）

- [多语言构建方案](L10N_DESIGN_GUIDE.md)：详细的实现步骤、代码样板、工程化流程
- [多语言命名规范](L10N_NAMING_GUIDE.md)：Key 的命名标准和最佳实践

### 开发循环

1. 在 `share_message` 中定义新消息（修改 enum）
2. 运行 `gen_msg_resource` 生成资源类
3. 运行 `extract_to_arb` 提取 ARB 文件
4. 翻译人员翻译 ARB 文件
5. 运行 `generate_from_arb` 生成多语言 Dart 代码
6. CLI/GUI 中使用 `MessageEngine.tr()` 调用新消息

可参考示例仓库中的 `ft-messages-multilanguage.yaml` 配合 [ft:FileTools](https://pub.dev/packages/filetools) 来自动化这个流程。

---

## 总结

| 组件  | 职责 | 关键作用 |
|------|------|--------|
| **MessageEnum** | 消息定义 | 类型安全 + 编译期检查 |
| **ARB 文件** | 多语言协作中心 | 与翻译平台集成 + 版本化管理 |
| **MessageProvider** | 翻译实现 | 屏蔽 CLI/GUI 差异 |
| **MessageEngine** | 翻译分发 | 全局调用入口 + Provider 切换 |

`basic_message` 的精妙之处在于：通过简单的接口分离和代码生成，解决了 Dart 多端应用中多语言共享的难题。现在，进入[示例仓库](https://github.com/huanguan1978/messages)开始实战吧！
