[English](https://github.com/huanguan1978/messages) | [Chinese
](https://github.com/huanguan1978/messages/blob/main/README_zh.md)


# Messages (Multi-Language Architecture)

This repository provides a structured, professional-grade localization (i18n) solution for **Dart** and **Flutter** applications. It is designed to solve the common pain points of cross-platform internationalization—code redundancy, type safety issues, and high maintenance costs—through a "Define Once, Reuse Anywhere" engineering approach.

This workspace contains the **`basic_message`** core library and a set of reference implementation examples, serving as a comprehensive template for scalable multi-language architecture.

---

## Architecture Philosophy

We believe that internationalization should be a **data-driven engineering mechanism** rather than just a collection of string lookups:

1.  **Unified Protocol**: Uses `MessageEnum` to provide compile-time type safety across your entire codebase.
2.  **Platform Decoupling**: Employs a `MessageProvider` pattern to bridge the gap between CLI (context-free) and GUI (context-dependent) environments.
3.  **Engineering Automation**: Integrates with the ARB standard and custom code-generation tools to achieve full decoupling between business logic and UI text.

---

## Learning Path

We recommend following this path to transition from high-level architectural concepts to practical implementation:

### Phase 1: Understand the Architecture
Before diving into the code, please review the architectural design to understand the "why" and "how":
*   **[L10N Design Guide](packages/basic_message/doc/en/L10N_DESIGN_GUIDE.md)**
    *   *Required Reading*: Covers the core logic, engineering workflow, and how to handle complex parameter rendering and pluralization.
*   **[I18N Naming Convention](packages/basic_message/doc/en/L10N_NAMING_GUIDE.md)**
    *   *Standard*: Learn the Four-Level naming hierarchy to ensure consistency and readability in team collaboration.

### Phase 2: Master Core Usage
Start your integration journey by reading the core package documentation:
*   **[README](packages/basic_message/doc/en/README.md)**: Overview of the package's functionality and installation.
*   **[EXAMPLE](packages/basic_message/doc/en/EXAMPLE.md)**: Practical examples on how to define message enums and implement platform-specific `MessageProviders`.

### Phase 3: Explore Source Code Details
Once you have grasped the architectural patterns, you can examine the sample packages in this workspace to see the implementation details:
*   `/share_message`: How to centralize business message definitions.
*   `/cli_example`: Implementation of `CliMessageProvider` for pure Dart environments.
*   `/gui_example`: How to leverage `gen_msg_registry` with `AppLocalizations` for seamless Flutter integration.

---

## About This Solution

The sample packages in this repository are designed to demonstrate the robustness of the `basic_message` architecture. We encourage you to study the design philosophy outlined in the guides above and build your own centralized localization resource center using the `share_message` layer as your foundation.

---

**Powered by [basic_message](https://pub.dev/packages/basic_message)**

*For engineering best practices, please prioritize reading the [L10N_DESIGN_GUIDE.md](packages/basic_message/doc/en/L10N_NAMING_GUIDE.md).*