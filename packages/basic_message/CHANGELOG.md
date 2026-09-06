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
