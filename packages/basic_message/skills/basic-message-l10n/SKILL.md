---
name: basic-message-l10n
description: "Use when a Dart or Flutter project depends on basic_message and an agent processes explicitly selected components for localization, reviews localization scope, or adds, changes, reviews, or generates MessageEnum definitions, ARB resources, message keys, ICU messages, or localization code."
---

# basic_message L10N v2

Follow this workflow when working on a project that depends on `basic_message`.

## Authoritative specification

Before editing or adding localization resources, read both authoritative references bundled within this skill:
- [references/localization_strategy.md](references/localization_strategy.md)
- [references/naming_guide.md](references/naming_guide.md)

Existing message definitions in user projects may predate v2 and must not override these references.

## Explicit scope and ownership

- Do not make product-level localization tiering decisions.
- Do not infer beginner workflows, recommended actions, skeletons, or advanced areas from file names, routes, UI styling, comments, defaults, or component structure.
- Work only on components explicitly selected by the developer.
- A selected parent component does not authorize recursive work on nested or reused child components. Process each child component only when it is separately selected.
- If no explicit component scope is available and the scope affects localization behavior, ask the developer to identify the component or components before editing.

Once the developer specifies the scope, the agent is responsible for applying the localization, naming, generation, and validation rules within that scope.

## Key Definition Rules

- **Text Lifecycle**: Classify text into three stages:
  - `st`: Static pre-render text (titles, button labels, static UI text).
  - `cd`: Conditional validation or guard text (input validation, pre-execution checks).
  - `rs`: Result feedback text after core execution (success notifications, error banners).
- **Code Allocation**: Allocate a unique 5-digit code in the matching range:
  - `20xxx` for `st`
  - `21xxx` for `cd`
  - `22xxx` for `rs`
  Check existing enum members to prevent code collisions.
- **Key Coordinate Format**: Use the 5-level snake_case key:
  `[partition]_[module]_[page]_[position]_[element...]`
  Each level should use CamelCase internally if it contains multiple words.
- **Dart Enum Member**: Convert the full 5-level snake_case key directly to CamelCase.
- **Doc Comments**: Mandatory `///` comment containing the original key if any coordinate has multiple words.
- **Metadata**: Provide complete `desc` (display context, parameters) and valid ICU formatting.
- **Parameter Completeness**: Every placeholder used by `msg` must have a matching representative value in `param`. `gen_msg_resource` discovers generated function parameters from `param`, not from placeholders alone.
- **ICU Syntax**: `select` and `plural` messages must include an `other` branch. Use a stable string or enum member name that matches every declared `select` branch.
- **ICU Expression Isolation (pipeline constraint)**: An ICU `select` or `plural` expression must be the entire `msg` value — no leading or trailing plain text, no surrounding words. `intl_translation` 0.21.0's PEG parser only takes the ICU path when the message starts with the expression; otherwise it falls back to `nonIcuMessageParse`, misreads `{words}` inside branch values as placeholder variables, and generation fails with `Cannot find parameter named 'XXX'`. If a sentence needs both fixed text and an ICU expression, split it into two messages: a pure select/plural label message plus a plain-parameter body message that receives the label's evaluated value. Escaping (`dartEscape` etc.) does not help — it operates on the Dart string literal, not on how the ICU parser reads the resolved value.
- **Enum Parameters**: For ICU `select` parameters backed by a Dart `Enum`, callers can pass the enum instance directly. `MessageEngine` and generated registries natively resolve `.name`.

## Minimal definition pattern

Use the target project's existing enum structure and naming when available. A v2-compliant definition should contain the code, key, default message, description, representative parameters, and original-key documentation:

```dart
/// st_profile_home_header_welcomeLabel
profileHomeHeaderWelcomeLabel(
  20001,
  'st_profile_home_header_welcomeLabel',
  'Welcome, {username}!',
  'Welcome text on the profile home page; username is the displayed name.',
  param: {'username': 'Guest'},
)
```

Representative ICU patterns:

```icu
{count, plural, =0{No items} =1{One item} other{{count} items}}
```

```icu
{mode, select, home{Home} settings{Settings} other{Other}}
```

For the `select` example, callers may pass a Dart enum instance whose `name` is `home`, `settings`, or another supported branch. Do not force open-ended or externally supplied option sets into enums.

When fixed text must accompany an ICU expression, use the two-message pattern (label message + body message), never wrap the expression in surrounding text:

```dart
// WRONG: leading text breaks the ICU parse path in intl_translation 0.21.0
entityDeleteTitle(
  20128,
  'st_entity_list_row_deleteTitle',
  'Delete {type, select, file{File} preset{Preset} other{Item}}',
  param: {'type': 'file'},
)

// RIGHT: pure select label message ...
entityTypeLabel(
  20185,
  'st_entity_list_row_typeLabel',
  '{type, select, file{File} preset{Preset} other{Item}}',
  param: {'type': 'file'},
)
// ... plus a plain-parameter body that receives the evaluated label
entityDeleteTitle(
  20128,
  'st_entity_list_row_deleteTitle',
  'Delete {type}',
  param: {'type': 'File'},
)
```

## Toolchain onboarding order

When onboarding a new project, this order helps a developer learn the toolchain without migrating everything at once:

1. Start with static presentation text (`st`), such as titles, buttons, labels, and explanatory text.
2. Continue with pre-execution validation and guard text (`cd`), introducing simple ICU parameters when needed.
3. Then identify menu items and other finite, stable option sets. Prefer Dart `Enum` values for closed sets, especially when used with ICU `select`.

This is a toolchain onboarding order, not a product localization priority. It does not authorize choosing the pages, components, beginner path, or advanced area. The developer must provide that scope. Always classify each message by when it occurs. A finite option set or enum is not automatically `st`, and dynamic or externally supplied open sets should not be forced into enums.

## Workflow

1. Confirm the explicit component scope. If it is missing or ambiguous, ask the developer to provide it.
2. Exclude nested and reused child components unless the developer separately selected them.
3. Read [references/localization_strategy.md](references/localization_strategy.md). Distinguish technical identifiers from user-facing text without making localization tiering decisions.
4. Read [references/naming_guide.md](references/naming_guide.md) and classify each included message by lifecycle (`st`/`cd`/`rs`).
5. Search nearby definitions in the target project for coordinate consistency, established file paths, and code availability. Do not copy a legacy format merely because it appears in older definitions, and do not migrate unrelated existing messages unless requested.
6. Define or update the `MessageEnum` member with all required metadata (`code`, `msg`, `desc`, `param`).
7. Verify that every `msg` placeholder has a representative `param` value, that ICU `select`/`plural` syntax contains `other`, and that any `select`/`plural` expression occupies the entire `msg` with no surrounding text (see **ICU Expression Isolation** above).
8. Do not automatically generate after every individual message edit. Users commonly batch several localization changes before generation. If generation was not explicitly requested and more edits may follow, ask whether to generate now.
9. When the user requests generation or confirms that the batch is ready:
   - Reuse the project's established input and output paths.
   - `gen_msg_resource` requires both `-i` and `-o`; do not invoke it without them:
     ```bash
     dart run basic_message:gen_msg_resource \
       -i <message-enum-file> \
       -o <generated-resource-file>
     ```
   - Continue with the target project's normal ARB extraction or synchronization step.
10. Before using ARB files to generate localized Dart resources, inspect every target ARB and ensure its root metadata contains a valid `@@locale`:
   ```json
   {
     "@@locale": "en"
   }
   ```
   Infer the locale from an unambiguous filename or existing project configuration. Add a missing value when it is certain; ask the user if the locale cannot be determined safely.
11. Continue according to the project type:
   - For Dart CLI projects, follow the project's `intl_translation` ARB-to-Dart generation workflow.
   - For Flutter projects, run `flutter gen-l10n` first. Run `gen_msg_registry` only when the project has `l10n.yaml` and generated `AppLocalizations` output:
     ```bash
     dart run basic_message:gen_msg_registry
     ```
12. Review generated diffs and do not hand-edit generated `*.g.dart` files. Run formatting, focused tests where available, and static analysis:
   ```bash
   dart analyze
   ```

## Completion checks

Before finishing, verify:

- The work stays within explicitly selected components.
- No unselected nested or reused child component was modified.
- No beginner workflow, recommended action, skeleton, or advanced area was inferred by the agent.
- Human-readable text and technical identifiers are kept distinct within the authorized scope.
- User-facing explanations, safety warnings, and recovery instructions were not retained merely because they accompany a technical identifier.
- The key has the required five-level coordinate structure.
- The code is unique and belongs to the correct `20xxx`, `21xxx`, or `22xxx` range.
- The enum member name and any required original-key documentation match the key.
- Every ICU placeholder appears in `param`, with a representative value suitable for extraction.
- Every ICU `select`/`plural` includes `other`.
- Every ICU `select`/`plural` is the entire `msg` value, with fixed wording split into a separate plain-parameter message when needed.
- Every generated ARB has an unambiguous, valid `@@locale`.
- Only the generation steps required by the CLI or Flutter project were run.
- Generated files reflect the intended message batch and contain no unintended rewrites.

Late-Binding is permitted during active prototyping. Before release, replace temporary user-facing strings in the explicitly authorized component scope with v2-compliant localization resources. Intentionally retained technical identifiers may remain unchanged.
