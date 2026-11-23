# Tiered Localization Strategy for Authorized Components

Use this reference only after the developer has explicitly identified the component or components to process.

## Scope Ownership

Localization tiering is a product decision owned by the developer:

- Do not infer which pages, actions, or controls form the beginner workflow.
- Do not infer which area is intended for advanced users.
- Do not infer localization priority from names, routes, UI styling, comments, or component nesting.
- Do not treat an unspecified or ambiguous component as an advanced area.
- Work only on components explicitly named by the developer.
- A named parent component does not authorize changes to nested or reused child components. Request separate authorization for each child component.

If the developer has not provided an explicit component scope, ask for it before editing.

## Within an Authorized Component

Apply the project's requested behavior to the user-facing text directly owned by the authorized component:

1. Localize human-readable text in the authorized scope.
2. Preserve program identifiers when the code or the developer requires an exact value, including:
   - API parameter names;
   - configuration keys;
   - enum values;
   - error codes;
   - code, JSON, schemas, commands, and regular expressions.
3. Do not preserve an entire English sentence merely because it mentions a technical identifier.
4. Keep user-facing explanations, actions, status, risk warnings, and recovery instructions as localization messages.

Example:

```text
temperature                  Technical identifier; may remain unchanged
Controls output randomness   User-facing explanation; localize
High values may be unstable  User-facing risk warning; localize
```

## Relationship to the Naming Convention

The strategy and naming convention solve separate problems:

- This strategy defines the boundary between program identifiers and user-facing text within an authorized component.
- The naming convention defines how localized messages are classified, named, generated, and maintained.

Once text enters localization resources, classify it as `st`, `cd`, or `rs` and apply the five-level semantic coordinate rules from `naming_guide.md`.

## Scope Checks

Before editing, verify:

- the authorized component or components are explicitly named;
- nested and reused child components are separately authorized;
- no localization tier has been inferred by the agent;
- the requested work stays within the authorized ownership boundary.
