---
name: basic-message-l10n
description: "Use when a Dart or Flutter project depends on basic_message and an agent adds, changes, reviews, or generates MessageEnum definitions, ARB localization resources, message keys, ICU messages, or localization code."
---

# basic_message L10N v2

Follow this workflow when the project uses `basic_message`.

## Authoritative specification

Before editing localization resources, locate and read the installed package's
`doc/en/L10N_NAMING_GUIDE2.md`. For a path dependency, it is inside the
`basic_message` package directory. For a hosted dependency, resolve the package
directory through `.dart_tool/package_config.json` or the Dart pub cache.

That document is authoritative. Existing message definitions may predate v2 and
must not override the guide.

## Definition rules

- Classify text by lifecycle: `st` for static pre-render text, `cd` for
  validation or guard text before core execution, and `rs` for feedback after
  core execution.
- Allocate a unique code in the matching range: `20xxx` for `st`, `21xxx` for
  `cd`, and `22xxx` for `rs`. Check the existing enum before allocating one.
- Use the five-level key format:
  `[partition]_[module]_[page]_[position]_[element...]`.
- Separate coordinate levels with underscores. Use CamelCase inside a level.
  Prefer one word in each of the first four levels.
- Make the element level self-descriptive; avoid vague names such as `type`,
  `mode`, or `data`.
- Derive the Dart enum member by converting the full snake_case key to
  CamelCase.
- Add a `///` documentation comment containing the original key. This is
  mandatory when any coordinate level contains multiple words.
- Provide complete `desc` metadata: where the text appears, parameter meanings,
  and translation context.
- Keep ICU message syntax valid. Every declared parameter needs a representative
  default value in `param`.

## Workflow

1. Read the v2 naming guide and identify the text lifecycle stage.
2. Search nearby definitions for code conflicts and relevant key coordinates.
3. Add or update the `MessageEnum` definition with the required metadata.
4. Run the project's message-resource generation commands.
5. Run focused Dart or Flutter analysis for the changed definition files.

Late-Binding is permitted: temporary hardcoded text may be used while a feature
is under active development. Before localization refactoring or release, replace
it with a v2-compliant message definition.
