# I18N Naming Convention

### 1. Purpose
To maintain a scalable and maintainable localization system, we adopt a **path-based naming strategy**. This ensures:
*   **Zero Ambiguity**: Easily locate any UI element across the app.
*   **IDE Productivity**: Leverage auto-completion to minimize typos.
*   **Decoupled Logic**: Separate the "Location (Area)" from the "Function (Key)".
*   **Consistency**: A shared vocabulary that enables the team to predict naming without checking documentation.

---

### 2. Core Paradigm: `{Module}_{Container}_{Area}_{Key}`
Each level is separated by an underscore (`_`). **Underscores are strictly forbidden in the first three levels.**

| Level | Definition | Rule | Example |
| :--- | :--- | :--- | :--- |
| **Module** | Business Domain | Single word/CamelCase | `auth`, `userProfile`, `common` |
| **Container** | Page or Component | Single word/CamelCase | `login`, `index`, `dialog` |
| **Area** | Logical UI Section | Single word/CamelCase | `header`, `form`, `footer` |
| **Key** | Function + Suffix | Semantic + Suffix | `submit_action`, `welcome_label` |

---

### 3. Suffix Dictionary (Mandatory)
Every `Key` must end with one of the following suffixes to define its UI property:
*   `_label`: Static text or display labels.
*   `_action`: Buttons, links, or any interactive elements.
*   `_hint`: Input placeholders.
*   `_error`: Validation or error messages.
*   `_title`: Page headings or dialog headers.

---

### 4. Best Practices & Tips
*   **Compound Words**: If a module or page name consists of multiple words, **do not use underscores**. Use `camelCase` (e.g., `userProfile` instead of `user_profile`) to keep the underscore reserved exclusively as the level delimiter.
*   **Dynamic Parameters**: When a string contains dynamic variables (e.g., `{username}`), ignore the parameters in the naming. Describe the business meaning only (e.g., `home_index_header_welcome_label` contains "Hello {username}").
*   **Reusability**: Shared components should use the `common` module. Aim to reuse existing keys for identical actions across different pages.

---

### 5. Anti-Patterns (Forbidden)
1.  **Vague Naming**: No `ok`, `btn1`, or `text_a`.
2.  **Delimiter Abuse**: Underscores in the first three levels are strictly prohibited.
3.  **Missing Suffix**: Every key must include a suffix to prevent ambiguity if the UI element type changes (e.g., `Label` to `Button`).
4.  **Hardcoding**: Never hardcode strings in Dart files; always use the corresponding key.

---

### 6. Developer Checklist (PR Review)
Before submitting a pull request, ensure your keys meet these requirements:
- [ ] **Hierarchy**: Is it composed of 4 segments?
- [ ] **Delimiter**: Are there any underscores in the first three segments? (If yes, refactor using camelCase).
- [ ] **Suffix**: Does it follow the defined suffix dictionary?
- [ ] **Semantics**: Is the function clear and intuitive?

---

> **Core Rule**: An underscore (`_`) marks a level transition. If you see an underscore in the first three segments, you have broken the structure. Treat this system as a structured database, not a pile of strings.