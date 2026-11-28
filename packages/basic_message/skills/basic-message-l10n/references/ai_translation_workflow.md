<!-- Provenance: copy of doc/en/AI_TRANSLATION_GUIDE.md (canonical). Keep in sync when the canonical guide changes. -->

# AI Translation Workflow Guide

> Applicability: the project has fully adopted the `basic_message` package — messages are defined, the generation pipeline for translated files works end to end, and the app already resolves text by active locale. On that basis, the plan is to hand the **actual translation** of all messages to AI.
> Audience: developers doing this for the first time (individuals and small teams), and the AI sessions that execute the translation work.
> Guide availability: this file ships with the package. With a path dependency, AI sessions can read it directly under `doc/en/`; with other dependency modes (pub cache etc.), copy it into the project first (e.g. `doc/`) so every session can reference it.
> Unfamiliar terms: see 1.1. Companion tools: section 6. "SKILL" below refers to `skills/basic-message-l10n/SKILL.md`.

---

## 1. Why you cannot just hand the ARB file to AI

| Problem | Solution (see) |
|---|---|
| AI does not know where each string appears or what triggers it; ambiguous words ("Clear") are pure guesses | Translation context pack: real call-site source snapshots (section 6) |
| Call-site context gets shredded by `dart format` line wrapping; line-based excerpting yields fragments | Context extracted by AST nodes, immune to wrapping (6.1) |
| Terminology drift on long projects (Preset becomes "preset" then "scheme") | Global glossary, approved once, enforced on every batch (3.3) |
| Reviewing hundreds or thousands of messages one by one is impossible for an individual developer, and quality cannot be guaranteed | AI reports only items **it is unsure about**, as multiple-choice questions (3.2) |
| Key-name prefixes and directory names do not reliably match semantics (naming is a convention, not a constraint) | AI does semantic grouping up front; names and paths are only supporting evidence (3.2) |
| Translations break ICU structure (renamed placeholders, dropped select branches) | Machine-check loop + red lines 2/3 (3.5, section 4) |
| Full translation takes a long time and must not block development | Untranslated entries fall back to English at runtime; work can proceed batch by batch (3.1) |

**Division of labor throughout: deterministic steps go to tools and the pipeline; interpretive steps go to AI; product-level decisions stay with the developer.**

### 1.1 Glossary

| Term | Plain meaning |
|---|---|
| Message | A registered entry for one piece of UI text, with a unique numeric code and key |
| ARB file | JSON file holding all message source texts and translations; `intl_en.arb` is the English baseline, `intl_de.arb` etc. hold translations |
| Baseline ARB | `intl_en.arb` — the reference for all translation work |
| Generation pipeline | A chain of automated commands: definitions → English baseline → code the app actually uses. Re-run after any translation change |
| Runtime integration | The app's ability to resolve text by active locale at run time (already wired; no detail needed here) |
| Placeholder | A reserved slot in a message, e.g. `{name}`, filled with a real value at display time |
| ICU expression | Special syntax for plurals and enum choices (`plural`/`select`) with strict structural rules (red lines 2/3) |
| Translation context pack | JSON material produced by the companion tool: each message paired with its real usage sites in the source code |
| Confidence | How sure the AI is about a judgment/translation. High: finalize directly. Medium: decide itself and log the reason. Low: must surface as a multiple-choice question |
| Semantic grouping | AI's global classification after reading all material: which business area (domain) and which lifecycle tier (st/cd/rs) each message belongs to |
| Glossary | Global term table and style rules that keep every message consistent |
| Machine check | Per-batch automated verification: translation structure intact, generation pipeline passes |

---

## 2. Workflow at a glance

```
① Copy baseline     intl_en.arb → intl_de.arb (add @@locale, values stay English for now)
② Semantic grouping AI produces translation_plan.json → developer approves
③ Global glossary   AI produces glossary_de.json → developer approves
④ Batch translation outer order st→cd→rs, inner batches by domain; machine check per batch; decisions feed back into the glossary
⑤ Machine check     structure validation → pipeline re-run → analyze → progress ledger (AI self-check + tools)

When all batches are done, run the acceptance checklist in section 8.
```

---

## 3. Protocol details

### 3.1 ① Copy the baseline

- Copy `intl_en.arb` to the target-language file (this guide uses German as the running example: `intl_de.arb`; substitute your target's code throughout) and add the root `@@locale` key (`"de"`, `"fr"`, `"pt_BR"`… — use standard forms and avoid ambiguous short forms). **Keep all values as the English source text for now.**
- Why: the generation pipeline keeps passing at any moment, and the app falls back to English for untranslated entries — translation can proceed batch by batch and pause at any time.

### 3.2 ② Semantic grouping

The AI reads the full translation context pack (generated per 6.2), classifies every message, and writes `translation_plan.json`:

```json
{
  "code": 20126,
  "member": "stFbGlobalTitleParametersInspect",
  "msg": "Parameters: {id}{modified}",
  "domain": "preset_params",
  "lifecycle": "st",
  "evidence": "callSites: gen_content_page.dart _onMenuAction (inspect dialog title)",
  "batch": "st-01"
}
```

| Field | Meaning | Basis for judgment (by weight) |
|---|---|---|
| `domain` | Semantic domain: which business area the text serves (e.g. `ai_chat`, `account_auth`, `task_scheduling`, `file_resource`, `app_generic`) | message content > call-site context / owner method name > key prefix, directory path |
| `lifecycle` | `st` static display / `cd` validation guard / `rs` execution feedback | functional shape of the message and its call site (`title:` argument → st; inside a `catch` block → rs); key prefix is only corroboration. Full definitions: `doc/en/L10N_NAMING_GUIDE2.md` |
| `evidence` | Summary of the basis | for fast human review at approval time |

**Zero-call-site entries (`callSites: []`)**: Entries defined in the `-i` message definition file that have zero direct call sites in `-s` are **skipped by default** (`"status": "skipped"` in `translation_plan.json`, keeping their English baseline text in the target ARB) and do not need to be translated or queried one by one. Only include a zero-call-site entry in translation if the developer explicitly designates it as an indirectly consumed entry (e.g. dispatched via an error-code formatter or enum lookup) during grouping approval.

**Low-confidence handling (the human interface of this protocol)**: a low-confidence item is one the AI is **not sure about** and must not guess. Surface it as a multiple-choice question — evidence summary, 2–3 options, a recommended option. The developer only picks an option and never types free-form feedback (open-ended feedback drifts from intent). Iterate until no low-confidence items remain, then the developer approves `translation_plan.json` as a whole.

**Reporting budget (hard rule)**: reported questions must stay under roughly 10% of all messages. Beyond that, the AI must decide itself and log the reasoning instead of dumping questions on the developer.

### 3.3 ③ Global glossary

From the approved semantic groups the AI produces the glossary file, named `glossary_<lang>.json` (running example: `glossary_de.json`) containing:

- **Term table**: translations of frequent domain nouns (German example: Preset→Voreinstellung, MCP Configuration→MCP-Konfiguration, Scheduled Task→Geplante Aufgabe…);
- **No-translate list**: technical words kept in English (MCP, API, ID, URL…) — how to draw the line between technical identifiers and user-facing text: `doc/en/L10N_STRATEGY_GUIDE.md`;
- **Style rules**: global choices (e.g. for German: formal "Sie" vs informal "du" address, button wording "Übernehmen" vs "OK").

After approval the glossary is binding for every batch; **it is a product-level decision and the AI must not change it on its own**. Decisions made during batches may flow back into the glossary, but glossary changes only happen at batch boundaries — finished batches are never disturbed.

### 3.4 ④ Batch translation

**Order: outer loop by lifecycle `st → cd → rs`, inner batches by `domain`.** Three reasons:

1. **Dependency direction**: cd/rs messages take many parameter values from st label messages (`{type}` fed by select labels, `{item}` by ID labels…). Translating st first finalizes every "referenced parameter value" so later batches reuse them without rework;
2. **Difficulty gradient**: st short labels → cd conditional parameters → rs plurals/select and tone nuances;
3. **Protocol dry run**: the first batch also validates the whole work chain (this guide, reporting format, machine check) at the lowest cost.

**Per-batch rules:**

1. Read the glossary first; terminology must align;
2. Translate from msg + desc + parameter examples first; **only open the call-site snapshots for items you are unsure about** — not every message needs source reading; this is the key cost control;
3. Three-level decision: translate directly / derive from the call site / flag as low-confidence (prefer omission over guessing);
4. Collect low-confidence items and report once per batch, with an "accept all recommendations" shortcut;
5. Every answered question is immediately recorded into the glossary so the same scenario never asks twice.

### 3.5 ⑤ Machine check (end of every batch)

1. **Structure validation** (AI self-check): compare each entry between en and the translation — same placeholder set, same select case keys (translate branch values only), same plural categories;
2. **Pipeline re-run**: re-run the project's own configured commands for "translated file → localization code", then `gen_msg_registry` (standard commands and order: 6.5; authoritative reference: SKILL Workflow steps 9–11);
3. **Static analysis**: `flutter analyze` / `dart analyze`;
4. **Progress ledger**: the untranslated-messages list produced by generation is the remaining workload; batch progress is recorded in `translation_plan.json`.

### 3.6 Session templates (copy-paste) and file layout

**File layout** (all inside the project):

| File | Produced by | Role |
|---|---|---|
| `lib/l10n/intl_en.arb` | generation pipeline | English baseline (read-only; changing it = changing requirements) |
| `lib/l10n/intl_de.arb` etc. | ① copy, ④ written per batch | translation file (the only final deliverable) |
| `lib/l10n/messages_analyzer.g.json` | companion tool, computed on demand | translation context pack (ephemeral, regenerable) |
| `lib/l10n/translation_plan.json` | ② grouping | grouping / order / progress ledger (read-only after approval, except batch progress) |
| `lib/l10n/glossary_de.json` | ③ glossary | terms and style rules (read-only after approval; changes only at batch boundaries) |
| Low-confidence reports, medium-confidence log | ②④ | presented in-session; decisions written back to the two files above |

**② Semantic grouping (one-off session):**

```text
Follow section 3.2 of doc/en/AI_TRANSLATION_GUIDE.md to perform semantic grouping:
1. First run the gen_msg_analyzer command from 6.2 to generate the translation
   context pack (if not present yet);
2. Read all material in lib/l10n/messages_analyzer.g.json and produce
   lib/l10n/translation_plan.json (domain / lifecycle / evidence / batch);
3. Report low-confidence items as multiple-choice questions per 3.2
   (with recommendations and evidence); iterate until none remain;
4. Hand the result back for my approval; do not start any translation before that.
```

**③ Global glossary (one-off session):**

```text
Follow section 3.3 of doc/en/AI_TRANSLATION_GUIDE.md to produce the global glossary:
based on the semantic groups in lib/l10n/translation_plan.json,
produce lib/l10n/glossary_de.json (term table / no-translate list / style rules);
report low-confidence terms as multiple-choice questions for my approval.
```

**④ Batch translation (one session per batch, fill in the batch number):**

```text
Follow doc/en/AI_TRANSLATION_GUIDE.md to execute batch <N>:
1. Read entries with batch = "<N>" from lib/l10n/translation_plan.json;
2. Read lib/l10n/glossary_de.json and align terminology strictly;
3. Translate per the per-batch rules in 3.4, writing into lib/l10n/intl_de.arb;
4. Report low-confidence items as multiple-choice questions per 3.2
   (with recommendations and evidence); do not guess;
5. Run the machine check per 3.5 and report results and remaining workload.
```

**Resuming after an interruption**: re-send the template with the next unfinished batch number; batch progress in `translation_plan.json` plus already-translated entries in the ARB are the resume state — no session memory needed.

---

## 4. Red lines (hard constraints)

Any violation means the batch is not finished:

1. **Placeholders stay untouched**: name, count, and position of every `{xx}` placeholder must not change;
2. **ICU expressions own the whole message**: if the source is a pure `select`/`plural` expression, the translation must also be a pure expression with **no text before or after** — the `intl_translation` 0.21.0 parser only takes the ICU path when the message starts with the expression; mixing text with the expression fails with `Cannot find parameter named 'XXX'` (authoritative source: the **ICU Expression Isolation** entry in SKILL; basic syntax examples: `doc/en/L10N_DESIGN_GUIDE.md`);
3. **select/plural must keep their `other` branch**; case keys are never translated;
4. **Terminology follows the glossary**; never invent translations on the spot;
5. **Prefer omission over guessing**: low-confidence items that cannot be resolved stay in English and are flagged pending;
6. **Reported questions ≤10%**; beyond that, decide and log instead of asking;
7. **Never hand-edit generated files**: `*.g.dart` is produced by the pipeline only;
8. **Passing the machine check ≠ semantically correct**: after every batch, spot-check a small sample by reading; route findings back through the 3.4 low-confidence flow.

---

## 5. Troubleshooting quick reference

| Symptom | Cause | Action |
|---|---|---|
| `Cannot find parameter named 'XXX'` | select/plural not occupying the whole message (plain text mixed in) | Split into a pure select/plural label message + a plain-parameter body message |
| select branch missing or case keys translated | AI broke the structure | Caught by machine-check step 1; retranslate the entry (red line 3) |
| Terminology inconsistent after resuming | glossary not enforced or drifted between batches | Re-read `glossary_de.json`; re-check affected batches |
| Generation reports untranslated messages | batch not reached yet — expected | App falls back to English; use the list as the progress ledger |
| One message's call sites spread over several domains | generic copy — normal | Assign to `app_generic`, translate in the earliest batch |
| Tool reports a message with zero call sites | unused/reserved entry in the `-i` definition file, or consumed indirectly via a shared entry point (e.g. an error-code formatter) | Skipped by default (`"status": "skipped"` in `translation_plan.json`, keeping English text); only translate if the developer explicitly designates an indirectly consumed entry during grouping approval; clean up dead keys separately |

---

## 6. Companion tool: gen_msg_analyzer

### 6.1 Purpose and principle

Collects **real call-site** context for every message and produces the translation context pack. Context is extracted at AST level in three layers — L1 the enclosing invocation / L2 the enclosing statement or catch clause / L3 the owning method and class — and since `dart format` only changes whitespace, never syntax, it is **immune to line wrapping**.

### 6.2 Usage

```bash
dart run basic_message:gen_msg_analyzer \
  -i lib/message/definition.dart \
  -s . \
  -o lib/l10n/messages_analyzer.g.json
```

| Option | Meaning |
|---|---|
| `-i, --input` | Message definition file (the file holding the MessageEnum) |
| `-s, --source` | Project root directory (call-site scan scope) |
| `-o, --output` | Output JSON (recommend `lib/l10n/`, next to the ARB files) |
| `-m, --max-snippet` | Max characters per source snapshot; default 2000, **floor 2000** (smaller values are raised with a notice). Value drops off once the semantic unit is fully covered; 2000 is the empirical balance point |

### 6.3 Output structure (per message)

```json
{
  "code": 20110,
  "key": "st_fb_action_failed",
  "member": "stFbGlobalSnackbarActionFailed",
  "msg": "{action} failed: {error}",
  "desc": "...",
  "paramExamples": { "action": "loadPreset", "error": "…" },
  "callSites": [
    {
      "file": "lib/page/publ/talking/chat_page.dart",
      "line": 222,
      "call": "ME.tr(MD.stFbGlobalSnackbarActionFailed, args: {'action': 'loadConversationHistory', 'error': '$e'})",
      "context": "AppGlobal.showSnackBar( ME.tr( … ) );",
      "owner": "_ChatPageState._loadHistory"
    }
  ]
}
```

| Field | Value for translation |
|---|---|
| `call` | Full call expression (argument literals are often semantic clues) |
| `context` | Enclosing semantic unit (`catch` block, `if` branch) — key to telling success from failure paths |
| `owner` | Owning class and method — which feature invokes it |
| `paramExamples` | Representative parameter values — what each parameter means |

Nested calls (a parameter value being another `ME.tr(...)`) are captured whole, never truncated by wrapping.

### 6.4 Behavior notes

- Automatic exclusions: hidden directories, `.dart_tool`/`build`, `*.g.dart`, the definition file itself, the output file itself;
- Cheap text pre-filtering (files not containing a target name are not parsed); hundreds of files finish in seconds;
- Reports the **zero-call-site message list** at the end — both a dead-key detector and a reminder about indirect consumption via shared entry points (last row of section 5);
- Output is **ephemeral material computed fresh each run**: never written into ARB files or persisted into definitions; re-run after code changes and it never rots.

### 6.5 basic_message companion tools

| Tool | Invocation | Role in the translation workflow |
|---|---|---|
| `gen_msg_analyzer` | `dart run basic_message:gen_msg_analyzer` | **Core of this guide**: the translation context pack (material for ②③④) |
| `gen_msg_resource` | `dart run basic_message:gen_msg_resource` | Pipeline step 1: definitions → resource file (must already work before translation; authoritative usage: SKILL Workflow steps 9–11) |
| `gen_msg_registry` | `dart run basic_message:gen_msg_registry` | Pipeline last step: runtime registry (part of the machine check in 3.5) |
| `intl_translation` / `flutter gen-l10n` | external packages | ARB extraction and localization code generation (exact commands per the project's own script configuration) |

---

## 7. Notes

1. **Baseline stability (prerequisite of the whole translation)**: the workflow assumes the baseline ARB (`intl_en.arb`) is stable and unchanged. If the baseline later changes:
   - **Newly added messages**: incremental translation works — translate only the additions;
   - **Changed existing messages**: the model cannot know which translated entries are affected and need retranslation, so incremental translation does **not** cover them — either retranslate everything, or explicitly specify the retranslation scope;
   - How to tell whether the baseline changed: compare `intl_en.arb` against the version used for the last translation (entry count + per-entry diff).
2. **Material freshness**: regenerate the context pack before every session; if definitions or call sites changed, re-run the tool for the affected batches;
3. **Output location**: the file pointed to by `-o` is automatically excluded from scanning — safe to place inside the project;
4. **Never skip glossary approval**: skipping it is the main source of terminology drift;
5. **Medium-confidence log**: reasons for AI's own decisions go into a sidecar log (not into the ARB) for later review;
6. **Multi-language rollout**: get the protocol working on one language (e.g. `de`) first; derive further languages (e.g. `de_AT`, `de_CH`) from the finished one at much lower cost;
7. **Derived translations still pass the machine check**: Traditional Chinese etc. can break ICU structure just the same;
8. **Division from SKILL**: this guide covers the translation phase only; definition-phase rules (five-level key structure, code ranges, ICU constraints) are governed by SKILL;
9. **Version sensitivity**: parsing behavior is bound to `intl_translation` 0.21.0; if a later version parses mixed text + ICU correctly, red line 2 must be revised accordingly.

---

## 8. Completion criteria (when is a language "done")

After all batches, verify every item below before declaring the language finished:

- [ ] The untranslated-messages list produced by generation is empty;
- [ ] All batches in `translation_plan.json` are marked complete, with no unresolved pending items (only explicitly skipped zero-call-site entries may remain in English, and red line 5 leftovers are cleared);
- [ ] Every batch's machine check passed, and **a full pipeline re-run plus static analysis was done at the end** (to catch cross-batch accumulation);
- [ ] The baseline ARB was not changed during translation; if it was, retranslation per note 7.1 (full or specified scope) is complete;
- [ ] The human read-through spot check per red line 8 was done and recorded; all findings were routed back and fixed.

Once accepted, `intl_<lang>.arb` is the official translation for that language; afterwards it only receives incremental maintenance as message definitions evolve (note 7.1).
