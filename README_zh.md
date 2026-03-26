[English](https://github.com/huanguan1978/messages) | [Chinese
](https://github.com/huanguan1978/messages/blob/master/README_zh.md)

# Messages (Multi-Language Architecture)

这是一个基于 **Dart** 开发的多语言（I18n）构建方案，旨在通过结构化工程手段，解决 Flutter (GUI) 和 Dart (CLI) 环境下跨平台国际化的痛点。

本项目不仅是一个核心包（`basic_message`），更是一套完整的 **“定义一次，多端复用，类型安全，编译时映射”** 的多语言工程方案。

---

## 核心架构设计

我们认为，国际化不应只是简单的字符串查找，而应是一种**工程化的数据驱动机制**。

1.  **统一协议**：在核心包中定义 `MessageEnum` 接口，提供编译时类型安全检查。
2.  **解耦实现**：通过 `MessageProvider` 模式，屏蔽 GUI（需要 Context）与 CLI（无需 Context）的底层实现差异。
3.  **工程化映射**：利用 ARB 标准作为协作枢纽，结合代码生成工具，实现业务文案与代码逻辑的彻底解耦。

---

## 学习指南

建议开发者按照以下顺序，从“理论架构”逐步过渡到“工程实战”：

### 第一步：理解架构思想
在深入源码之前，请务必先阅读方案文档：
*   **[多语言构建方案 (Design Guide)](packages/basic_message/doc/en/L10N_DESIGN_GUIDE.md)**
    *   *必读*：这里详细阐述了方案的底层逻辑、工程化流程以及如何处理复杂的参数渲染。
*   **[多语言命名规范 (Naming Guide)](packages/basic_message/doc/en/L10N_NAMING_GUIDE.md)**
    *   *规范*：掌握四级命名法，确保你的多语言 Key 在团队协作中条理清晰。

### 第二步：掌握核心用法
阅读 `basic_message` 包的详细文档，这是你开发工作的起点：
*   **[基础说明 (README)](packages/basic_message/doc/en/README.md)**：了解包的功能定位与安装说明。
*   **[最佳实践 (EXAMPLE)](packages/basic_message/doc/en/EXAMPLE.md)**：通过详细代码片段，掌握如何定义消息枚举及如何实现各端的 `Provider`。

### 第三步：查阅源码实现细节
当理解了上述方案的逻辑后，你可以查看本工作空间内的示例包：
*   `/share_message`：查看如何集中定义业务消息枚举。
*   `/cli_example`：查看如何在纯 Dart 环境中实现 `CliMessageProvider`。
*   `/gui_example`：查看如何在 Flutter 环境中利用 `gen_msg_registry` 与 `AppLocalizations` 协同工作。

---

## 关于本方案

本项目配套的工具链与示例，均是为验证 `basic_message` 架构的健壮性而设计的。我们鼓励开发者在理解上述设计思想后，根据你的具体业务场景，在 `share_message` 这一层级构建属于你的多语言资源中心。

---

**由 [basic_message](https://pub.dev/packages/basic_message) 核心方案驱动**

*如有工程化需求，请优先阅读 [L10N_DESIGN_GUIDE.md](packages/basic_message/doc/en/L10N_NAMING_GUIDE.md)*