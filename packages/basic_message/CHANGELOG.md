## 1.1.0

- New CLI tool `gen_msg_analyzer`: builds a per-message translation context pack (call sites with code context) from a project's message definitions, to support AI-driven translation.
- Extend the `basic-message-l10n` skill with the AI translation workflow guide and translation-phase rules; see `doc/zh/AI_TRANSLATION_GUIDE.md` / `doc/en/AI_TRANSLATION_GUIDE.md`.

## 1.0.9

- Add "ICU Expression Isolation" rule: select/plural must occupy the entire msg; split into label + plain-parameter body messages otherwise
- Add WRONG/RIGHT definition examples and workflow/completion checks
- Note that dartEscape-style escaping does not affect ICU parsing

## 1.0.8

- Escape generated Dart string literals to support newlines, quotes, backslashes, and dollar signs in message values, descriptions, and default arguments.

## 1.0.7

- Add the bilingual Tiered Localization Strategy guides for role-based localization scope, skeleton/payload separation, progressive workload, and technical-identifier retention.
- Clarify the complementary responsibilities of the Localization Strategy and the L10N Naming & Workflow Convention.
- Update the AI Agent Skill to require developer-provided component scope, avoid inferred product tiers, and exclude unselected nested or reused components.
- Keep program identifiers and user-facing explanations distinct during Agent-assisted localization.

## 1.0.6

- Standardize the AI Agent Skill layout under `skills/basic-message-l10n` and make its reference content self-contained.
- Expand the L10N v2 guides and Skill with progressive adoption, ICU validation, batched generation, and ARB locale checks.
- Document how conventions, generation scripts, and AI-assisted workflows reduce localization engineering overhead.
- Add focused VS Code Copilot and Antigravity installation guidance for the published AI Skill.

## 1.0.5

- Support Enum values as translation arguments, including ICU `select` messages and generated localization registries.
- Document Enum-based ICU `select` arguments across English and Chinese guides.
- Update CLI and Flutter examples to demonstrate Enum translation arguments.

## 1.0.4

- Add an AI Agent Skill for `basic_message` L10N v2 workflows.
- Add optional VS Code/Copilot instructions for message definition files.
- Document Skill installation from the Dart Pub cache on macOS, Linux, and Windows.

## 1.0.3
  - Improved the README Flutter integration guide with `GuiMessageInitializer` and the `gui_example` reference.

## 1.0.2
- **Documentation & Specification Upgrade (v2)**:
  - Introduced the **5-Level Semantic Coordinate Architecture** to standardize localization keys and improve maintainability.
  - Adopted a **Late-Binding** workflow, allowing for more flexible development cycles before final localization.
  - Added `L10N_NAMING_GUIDE2.md` as the new standard for naming conventions.
  - Added real-world implementation references (`chapose` and `chabox`) to the README to demonstrate best practices for CLI and GUI integration.

## 1.0.1
Fix: refine parameter discovery in gen_msg_resource.dart
 
- Strictly derive parameters from the param map in message enums.
- Prevent false positives when parsing complex ICU message strings (e.g., select labels).
- Improve AST visitor to correctly identify the param argument regardless of its position.
- Use robust string literal parsing for better content extraction.

## 1.0.0

- Initial version.
