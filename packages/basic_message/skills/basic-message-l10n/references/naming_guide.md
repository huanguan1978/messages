# L10N Naming & Workflow Convention v2

### 1. Core Philosophy: Pragmatism, Rigor, and Semantic Coordinates
*   **Late-Binding**: Focus on logic implementation during the development phase, allowing for temporary placeholder text. Perform unified localization refactoring only after the feature is stable and before release.
*   **Lifecycle Partitioning**: Categorize text based on when it appears in the interaction flow (Static, Conditional, Result) to ensure logical archiving.
*   **5-Level Semantic Coordinates**: Use a 5-segment path to precisely locate the "physical coordinate" and "business intent" of each text string.

---

### 2. Text Lifecycle Stages (Partition)
The first level of naming must explicitly define the partition:

| Partition | Full Name | Business Logic Criteria | Core Mindset |
| :--- | :--- | :--- | :--- |
| **st** | Static | **Pre-rendering phase**: Text determined immediately upon UI component loading. | **Instantly Visible** |
| **cd** | Conditional | **Logic Guard phase**: Validation of input, state, or environment before executing core business logic. | **Access Denied** |
| **rs** | Result | **Feedback phase**: Execution results (success or exception) generated after crossing the core business boundary. | **Final Verdict** |

#### General Rules:

1.  **"Core Execution" as the Boundary**:
    *   Core execution typically refers to methods with physical/logical side effects, such as file I/O, encryption, network requests, or database changes.
    *   **Conditional (cd)**: All pre-checks intended to ensure operational validity (e.g., `validate()`, conflict checks, permission checks). If the process returns before triggering the core method, it is `cd`.
    *   **Result (rs)**: All feedback generated after triggering the core method, regardless of whether it succeeds or throws an exception, is `rs`.

2.  **Granular Error Handling**:
    *   **Validation errors** (e.g., "Invalid username format"): Belong to **`cd`**.
    *   **Execution errors** (e.g., "Failed to write to disk", "IO Exception"): Belong to **`rs`**.

3.  **Consistency**:
    *   Text triggered by the same interaction should ideally be grouped into the same partition. If a feature requires both `cd` and `rs` due to different trigger stages, use the Element-level naming (5th coordinate) to distinguish them.

---

### 3. Recommended Progressive Adoption
When using `basic_message` for the first time, there is no need to migrate every text in the project at once. If you have not yet studied the full examples, start with a relatively isolated page or feature and complete a minimal end-to-end flow in the following order. This builds familiarity with `MessageEnum`, ARB resources, and code generation through increasingly complex scenarios.

1. **Start with static presentation text (`st`)**
   Begin with titles, buttons, labels, and explanatory text that are known when the page is rendered.
   These messages usually do not depend on business execution results and rarely need complex parameters, making them well suited for verifying resource definitions, message mappings, and code generation.

2. **Continue with validation and guard text (`cd`)**
   Next migrate input validation, permission checks, conflict detection, and other pre-execution messages.
   The deciding factor is whether the message is produced before the core operation, not whether it contains parameters. At this stage, introduce simple parameters such as usernames, paths, counts, or limits and become familiar with ICU parameter syntax.

3. **Then identify menus and other closed sets of options**
   Review menu items, display modes, status choices, and other text with a well-defined range of values. If these options are represented by hard-coded branches or repeated strings, consider modeling finite, stable sets as Dart `Enum`s.
   `basic_message` supports Dart `Enum` values in ICU `select` parameters: callers can pass an enum instance directly, and `MessageEngine` or the generated registry resolves its `.name`. Prefer `Enum` for stable, closed sets; do not force dynamic or externally supplied open sets into enums.

This adoption order is intended to reduce the initial learning cost and does not change the lifecycle rules. Classify every message as `st`, `cd`, or `rs` according to when it occurs. Menu options must be classified by their lifecycle before deciding whether to use an `Enum`; a finite set is not automatically `st`.

Start with a minimal working scope. After completing the cycle of defining messages, generating resources, generating the registry, and running static analysis, expand gradually to other pages and more complex `rs` messages.

---

### 4. The 5-Level Semantic Coordinate Architecture
**Format**: `[Partition]_[Module]_[Page]_[Position]_[Element...]`

**Naming Rules**:
*   **Level Separator**: Use `_` (underscore) strictly to separate levels.
*   **Word Separator**: If a level contains multiple words, use **CamelCase**. Do not use underscores within a level.
*   **Single-Word Preference**: It is highly recommended that each of the 5 levels (especially the first four) uses only one word. This ensures clear boundaries even when using CamelCase in code.

| Level | Description | Example (Specific/Private) | Example (Abstract/Global) |
| :--- | :--- | :--- | :--- |
| **1. Partition** | Text lifecycle stage | `st` | `rs` |
| **2. Module** | Business module or domain | `vault`, `userProfile` | `common`, `sys` |
| **3. Page** | Specific page or logic domain | `homePage`, `detail` | `global`, `logic` |
| **4. Position** | UI location or execution context | `header`, `dialog` | `any`, `guard` |
| **5. Element** | **Element-level (Self-descriptive)** | `mainTitleLabel` | `ioWriteFailedError` |

---

### 5. Element-Level Naming Details
The fifth level and beyond are referred to as the "Element-level," which is the most flexible and critical part of the naming convention:
*   **No Length Limit**: Element-level names can be as long as necessary.
*   **Eliminate Ambiguity**: Fully describe the core meaning of the text. Avoid vague terms like `type`, `mode`, or `data`.
*   **Self-Documenting**: The goal is for developers to understand the business intent of the enum member without needing to check the original `msg` string.
*   **CamelCase Principle**: Use CamelCase for multiple words within the element level, e.g., `deleteConfirmMessage`.

---

### 6. Semantic Placeholder Substitution (The "Collapse" Formula)
To maintain a consistent 5-level structure, use virtual placeholders for generic text:

| Scenario | Module | Page | Position | Example Key |
| :--- | :--- | :--- | :--- | :--- |
| **Global Static Button** | `common` | `global` | `button` | `st_common_global_button_saveAndExit` |
| **Generic Business Logic** | `[biz]` | `logic` | `guard` | `cd_vault_logic_guard_passwordTooShort` |
| **System Execution Result** | `sys` | `core` | `any` | `rs_sys_core_any_diskSpaceNotEnough` |

---

### 7. Metadata Requirements
Every localization definition must include complete metadata. Do not define only the Key and Msg:
1.  **Code Segmentation**: `20xxx` (st), `21xxx` (cd), `22xxx` (rs).
2.  **Detailed Description (Desc)**:
    *   Describe the specific interaction scenario where the text appears.
    *   Explain the specific meaning of variables (e.g., `{file}`).
    *   Provide translation context/suggestions.

---

### 8. Implementation & Developer Experience (DX)
To maintain consistency in Dart code while ensuring the readability of the 5-level semantic coordinates, follow these standards:

*   **Member Name Derivation**: Enum member names are generated by converting the `Key` string from snake_case to CamelCase.
*   **Mirror Documentation**:
    Each Enum member should include a documentation comment (`///`) containing its original `Key` string.
    *   **Mandatory Rule**: If any level in the 5-level coordinate contains multiple words (i.e., CamelCase was used within that level), the member **must** include a documentation comment.
*   **IDE Assistance**: Through documentation comments, developers can instantly confirm the physical coordinate of the text in the localization system via IDE hover.

---

### 9. Changelog (from v1)
1.  **Structure Expansion**: Upgraded from 4 levels to **5-level semantic coordinates**, adding `Partition` as the first level.
2.  **Workflow Evolution**: Shifted from "No Hardcoding" to a more pragmatic **"Late-Binding"** workflow.
3.  **Separator Standardization**: Explicitly defined `_` as the level separator; use **CamelCase** within levels.
4.  **Element-Level Definition**: Upgraded the `Key` concept to "unlimited length self-descriptive element-level," resolving ambiguity caused by noun stacking.
5.  **Code Mapping Optimization**: Introduced "Single-Word Preference" and "Mirror Documentation" strategies to balance Dart code aesthetics with path transparency.
