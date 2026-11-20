---
name: basic-message-l10n
description: "Use when a Dart or Flutter project depends on basic_message and an agent adds, changes, reviews, or generates MessageEnum definitions, ARB localization resources, message keys, ICU messages, or localization code."
---

# basic_message L10N v2

Follow this workflow when working on a project that depends on `basic_message`.

## Authoritative specification

Before editing or adding localization resources, read the authoritative specification bundled within this skill:
- [references/naming_guide.md](references/naming_guide.md)

Existing message definitions in user projects may predate v2 and must not override the guide.

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

## Recommended adoption order

When onboarding a project incrementally, choose a small isolated page or feature and complete the full generation workflow:

1. Start with static presentation text (`st`), such as titles, buttons, labels, and explanatory text.
2. Continue with pre-execution validation and guard text (`cd`), introducing simple ICU parameters when needed.
3. Then identify menu items and other finite, stable option sets. Prefer Dart `Enum` values for closed sets, especially when used with ICU `select`.

This is an adoption order, not a lifecycle override. Always classify each message by when it occurs. A finite option set or enum is not automatically `st`, and dynamic or externally supplied open sets should not be forced into enums.

## Workflow

1. Read [references/naming_guide.md](references/naming_guide.md) and classify the message lifecycle (`st`/`cd`/`rs`).
2. Search nearby definitions in the target project for coordinate consistency, established file paths, and code availability. Do not copy a legacy format merely because it appears in older definitions, and do not migrate unrelated existing messages unless requested.
3. Define or update the `MessageEnum` member with all required metadata (`code`, `msg`, `desc`, `param`).
4. Verify that every `msg` placeholder has a representative `param` value and that ICU `select`/`plural` syntax contains `other`.
5. Do not automatically generate after every individual message edit. Users commonly batch several localization changes before generation. If generation was not explicitly requested and more edits may follow, ask whether to generate now.
6. When the user requests generation or confirms that the batch is ready:
   - Reuse the project's established input and output paths.
   - `gen_msg_resource` requires both `-i` and `-o`; do not invoke it without them:
     ```bash
     dart run basic_message:gen_msg_resource \
       -i <message-enum-file> \
       -o <generated-resource-file>
     ```
   - Continue with the target project's normal ARB extraction or synchronization step.
7. Before using ARB files to generate localized Dart resources, inspect every target ARB and ensure its root metadata contains a valid `@@locale`:
   ```json
   {
     "@@locale": "en"
   }
   ```
   Infer the locale from an unambiguous filename or existing project configuration. Add a missing value when it is certain; ask the user if the locale cannot be determined safely.
8. Continue according to the project type:
   - For Dart CLI projects, follow the project's `intl_translation` ARB-to-Dart generation workflow.
   - For Flutter projects, run `flutter gen-l10n` first. Run `gen_msg_registry` only when the project has `l10n.yaml` and generated `AppLocalizations` output:
     ```bash
     dart run basic_message:gen_msg_registry
     ```
9. Review generated diffs and do not hand-edit generated `*.g.dart` files. Run formatting, focused tests where available, and static analysis:
   ```bash
   dart analyze
   ```

## Completion checks

Before finishing, verify:

- The key has the required five-level coordinate structure.
- The code is unique and belongs to the correct `20xxx`, `21xxx`, or `22xxx` range.
- The enum member name and any required original-key documentation match the key.
- Every ICU placeholder appears in `param`, with a representative value suitable for extraction.
- Every ICU `select`/`plural` includes `other`.
- Every generated ARB has an unambiguous, valid `@@locale`.
- Only the generation steps required by the CLI or Flutter project were run.
- Generated files reflect the intended message batch and contain no unintended rewrites.

Late-Binding is permitted: temporary hardcoded text may be used during active prototyping, but must be replaced with v2-compliant `MessageEnum` definitions before release.
