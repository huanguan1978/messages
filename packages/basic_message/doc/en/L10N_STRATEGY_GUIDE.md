# Tiered Localization Strategy: Skeleton vs. Payload

> **Core principle: Beginners should complete the main workflow in their own language, while advanced users may work with English terminology when fine-tuning parameters.**

## 1. Background and Practical Constraints

In UI development and internationalization (i18n/l10n), treating localization as "translate every string immediately" creates two practical problems:

1. **Users need different levels of understanding to complete different tasks**
   - **Beginners / everyday users** rely on sensible defaults and recommended workflows. They should not need to study technical documentation first.
   - **Experienced / advanced users** enter advanced areas to fine-tune domain-specific parameters, often by referring to specifications or API documentation.
2. **Advanced parameters change quickly and are expensive to translate**
   - Advanced parameters are frequently added, removed, or renamed as product capabilities and underlying protocols evolve. Translating all of them early creates a substantial maintenance burden.
   - Algorithm names, protocol identifiers, data formats, and configuration keys often already have widely recognized names. Translating them too literally can reduce precision and make it harder to search for or compare against source documentation.

Localization therefore does not have to begin with exhaustive coverage of the interface. It can begin by enabling each user role to complete its task:

> **First, let beginners complete the recommended workflow in their own language. Then decide which advanced settings should retain their original technical names and which explanatory content needs translation.**

This strategy and the [L10N Naming & Workflow Convention](L10N_NAMING_GUIDE2.md) solve different problems: this guide determines **what to translate first**, while the naming convention defines **how text that enters the localization system is organized**. Use the two documents together; neither replaces the other.

| Guide | Primary question | Scope |
| :--- | :--- | :--- |
| This strategy guide | Which content should be localized first? Which technical names may remain in their original form? | User roles, skeleton vs. payload, localization priorities |
| Naming and workflow convention | How should localized messages be classified, named, and generated? | `st` / `cd` / `rs`, five-level semantic coordinates, message generation |

Use this strategy first to decide whether text belongs in localization resources. Once it does, apply the naming and workflow convention to it. User roles and interface responsibilities define the scope; lifecycle partitions define the message name. Even when content belongs to an advanced payload, it must follow the naming convention once it enters the localization system.

---

## 2. Tier 1: User Roles Drive the Strategy

A "role" describes the depth of use required for the current task, not a permanent label for the person. The same person may act as a beginner while following the default workflow and as an expert while tuning advanced settings.

### 2.1 Beginners / Everyday Users

To support beginners, the interface must at least:

- explain the current page and section without requiring English;
- allow recommended options and default settings to be used without external technical documentation;
- communicate primary actions, task status, and results;
- explain how to go back, retry, or recover from common errors.

The beginner workflow should therefore form a complete in-language loop:

```text
Open the page → Understand the current location → Use recommended settings → Run the action → Understand the result → Retry or go back if needed
```

### 2.2 Experienced / Advanced Users

The goal for advanced users is accurate fine-tuning, not translating every technical name into the local language. Advanced areas may:

- retain widely established English industry terms;
- retain protocol names, algorithm names, API parameter names, configuration keys, and enum values;
- use localized text for navigation, actions, risks, and recovery;
- provide original names that match official documentation and are easy to copy and search.

The central principle is:

> **Beginners should complete the main workflow in their own language, while advanced users may work with English terminology when fine-tuning parameters.**

This role-based split determines localization priority. It does not change how messages are classified as `st`, `cd`, or `rs` under the [naming and workflow convention](L10N_NAMING_GUIDE2.md). A beginner workflow may contain static text, validation messages, and execution results; classify each message by where it occurs.

---

## 3. Tier 2: Separate the Skeleton from the Payload

To put role-based localization into practice, distinguish two interface responsibilities. The skeleton provides orientation and controls; the payload carries the actual business or technical content.

```text
                [Skeleton: Must be localized]
       Page titles, navigation, tabs, actions, status, feedback
                              │
                              ▼
┌────────────────────────────────────────────────────────┐
│ Task Workspace                                         │
│ [ Basic settings ]   [ Advanced settings ] ← Tab label │
│────────────────────────────────────────────────────────│
│  Temperature: 0.7                                      │
│  Top-P: 0.95                       ← Payload           │
│  Local Files: Sandbox / Base64                         │
│────────────────────────────────────────────────────────│
│ [ Restore defaults ]                         [ Run ]   │
└────────────────────────────────────────────────────────┘
```

### 3.1 The Skeleton Must Be Localized

The skeleton is the interface's navigation and control system. It tells users where they are, what they can do, and what will happen next.

At a minimum, the skeleton includes:

- page titles and global navigation;
- titles for tabs, drawers, expandable sections, and dialogs;
- action labels such as Submit, Save, Run, Reset, and Back;
- progress, success, and failure states;
- errors that affect the next step and the recovery controls that accompany them.

Even when content inside an advanced area remains in English, its section title must be localized. The title acts as a door label: seeing "Advanced settings" tells a beginner that this is outside the recommended path without requiring them to inspect the contents. Planned English content behind a localized label is different from accidental omission—it has a clear, intentional boundary.

### 3.2 The Payload Can Be Handled in Stages

The payload is the business or technical content carried inside the skeleton, including:

- advanced parameter names and technical options;
- JSON, schemas, regular expressions, and code;
- protocol names, algorithm names, API parameter names, configuration keys, and enum values;
- explanations of low-level implementation details.

The payload may be handled in stages, but an entire advanced area must not automatically qualify for exemption. In particular, inspect it for safety, decision-making, risk, and recovery information.

### 3.3 The Skeleton Is Not the Same as the Beginner Workflow

These concepts serve different purposes:

- the **skeleton** describes interface responsibilities;
- the **beginner workflow** describes the path a beginner takes to complete a task;
- beginners use the skeleton and may also encounter a small amount of payload;
- advanced users still depend on a localized skeleton while tuning parameters.

Do not equate skeleton with beginner or payload with expert. The skeleton is the baseline for everyone. The beginner's localization scope consists of that baseline plus the payload they need to understand along the recommended path.

---

## 4. Tier 3: Expand the Work in Stages

Once the skeleton and payload are understood, localization work can be planned in stages without auditing every advanced string first.

### L0: Fully Localize the Skeleton

Translate navigation, section labels, primary actions, task status, and basic feedback. This creates the localized control layer used by every role.

### L1: Complete the Beginner Workflow

Building on the skeleton, localize the payload encountered by beginners:

- the names and meaning of recommended options;
- the purpose and basic constraints of default values;
- conditions that must be understood before running an action;
- results, failure reasons, and recovery steps.

After this stage:

> A beginner following the recommended workflow should not need to understand technical English or consult external documentation.

### L2: Establish a Clear Boundary for Advanced Areas

Localize the entrance to the advanced area, including tabs, panel titles, and action labels, while retaining deep technical payloads where appropriate:

```text
Advanced settings              (localized label)
  ├─ Temperature: 0.7          (technical term retained)
  ├─ Top-P: 0.95               (technical term retained)
  └─ [ Restore defaults ]      (localized action)
```

### L3: Incrementally Localize the Advanced Area

As a feature stabilizes, gains users, or generates comprehension-related feedback, localize the most valuable advanced explanations:

- what each parameter does;
- common combinations and recommended values;
- risks, constraints, and recovery steps;
- help text for frequently used features.

### L4: Retain Technical Text That Must Match Code or Specifications

The following content usually does not need to be replaced with purely localized wording:

- official API parameter names and configuration keys;
- JSON, schemas, code, and regular expressions;
- established industry terms that are easy to search;
- identifiers that must match an implementation or official specification exactly.

The overall progression is:

```text
Localize the skeleton
→ Complete the beginner workflow
→ Establish a clear advanced-area boundary
→ Localize advanced explanations incrementally
→ Preserve technical identifiers
```

---

## 5. User Workflows

### Beginner: The Localized Main Path

```text
Open the page
  ↓ Localized
Understand the page and recommendations
  ↓ Localized
Recognize section labels
  ↓ Localized
Run the action
  ↓ Localized
Understand the result
```

Beginners do not need to enter the advanced area or understand domain-specific English.

### Advanced User: Fine-Tuning

```text
Orient using the localized skeleton
  ↓
Enter the advanced area
  ↓
Review technical terms and official key names
  ↓
Adjust parameters
  ↓
Read localized actions, risks, and feedback
  ↓
Save or run
```

Advanced users can fine-tune with English terminology while continuing to rely on localized navigation, actions, warnings, and recovery controls.

---

## 6. How to Handle Translation in Advanced Areas

Do not audit every advanced string during the first stage. Once the advanced area enters the localization workflow, handle it in this order.

### 6.1 Retain Industry Terms and Code Identifiers First

The following content may remain in English or be shown bilingually:

- widely recognized industry terms;
- official API parameter names, configuration keys, protocol identifiers, and enum values;
- code, schemas, regular expressions, and commands;
- values that users need to copy, search, or compare verbatim with official documentation.

For example, retain `Temperature` and provide localized explanation:

```text
Randomness (Temperature)
Controls how much the output varies.

temperature: 0.7
```

This exemption applies to the technical identifier itself, not to all explanatory text associated with it.

### 6.2 Then Review the Remaining Human-Readable Text

After identifying terms and identifiers that should remain unchanged, inspect the remaining user-facing text:

- **Safety**: permissions, privacy, data protection, cost, and irreversible actions;
- **Decision-making**: options, ranges, and constraints users must understand before choosing;
- **Risk**: configurations that can cause failure, instability, or data loss;
- **Recovery**: going back, retrying, resetting, undoing, and restoring defaults.

Content in any of these categories should be prioritized for localization even when it appears in an advanced area.

### 6.3 Keep Three Types of Content Separate

```text
Specification identifier: Temperature
User-facing name:         Randomness (Temperature)
Purpose and risk:         Controls output variation; excessively high values may produce unstable results.
```

This preserves searchability and direct comparison with source material while avoiding the need for users or support teams to infer the meaning of English-only explanations.

---

## 7. Implementation Rules

1. **Localize every section label**
   Localize anything that provides navigation or groups content, including tab, drawer, expandable-section, and dialog titles.
2. **Maintain clear boundaries**
   Content intentionally retained in English should live in a clearly defined advanced area rather than being mixed randomly with beginner settings.
3. **Localize action verbs**
   Actions such as Apply, Restore Defaults, Copy Configuration, and Run belong to the skeleton. Do not leave them in English merely because nearby parameters are technical.
4. **Distinguish retained terminology from missing translations**
   Use a consistent visual treatment or bilingual labels for terminology that is intentionally retained. Detect and report unplanned missing translations with checks and tests; do not hide omissions behind the "advanced area" concept.
5. **Temporary deferral is not permanent exemption**
   Expand advanced-area localization as features stabilize, usage grows, support costs increase, or the area becomes part of a beginner's workflow.
6. **Program identifiers may remain unchanged, but user-facing explanations must be localized**
   API parameter names such as `temperature`, as well as configuration keys, enum values, and error codes, may retain their original identifiers because code and specifications reference those fixed names.
   Text that explains what a parameter does, what risks it carries, or how to use it belongs in localization resources:

   ```text
   temperature                  ← program identifier that may remain unchanged
   Controls output randomness   ← user-facing explanation that must be localized
   High values may be unstable  ← risk warning that must be localized
   ```

   Retaining `temperature` exempts the parameter name only. It does not exempt a sentence such as "Controls the randomness of output"; do not hard-code that sentence in the interface.

---

## 8. Summary

> **Split users into roles first, then use the skeleton to establish the localization baseline. Complete the skeleton and beginner workflow, retain technical terms in advanced areas, and prioritize translation of safety, decision-making, risk, and recovery content.**

The goal is not to translate every string immediately, nor to leave advanced content untranslated indefinitely:

> **Localized language provides understanding, control, and decision support. Technical source terms preserve precision, searchability, and alignment with specifications.**
