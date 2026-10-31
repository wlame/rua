# AGENTS.md

Guide for coding agents working on this repository.

## What this is

`rua` is a Claude Code plugin. Its skills take a short chat message
(Russian, Ukrainian or mixed) and return 2-3 rephrased variants in Russian
and/or Ukrainian that use only the 29 Cyrillic letters present on both
keyboard layouts. There is no runtime code besides two small shell scripts:
the product is the instruction text in `skills/` plus a deterministic checker.

## Core concepts

- **Shared alphabet**: `а б в г д е ж з и й к л м н о п р с т у ф х ц ч ш щ ь ю я`
  in both cases. Any other Cyrillic letter (`ё ъ ы э і ї є ґ ў` ...) and the
  apostrophes `'` `’` `ʼ` are forbidden in output. Everything else passes.
- **Modes**: both languages (default), `ru`, `ua`. `/rua:rua` reads an optional
  first word `ru`/`ua`; `/rua:ru` and `/rua:ua` have the mode fixed.
- **The model proposes, the script checks**: the model writes variants, then
  runs `scripts/check-letters.sh` on them and rewrites only failing variants,
  at most 3 rounds.

## How the pieces fit

```
skills/rua/SKILL.md  ─┐
skills/ru/SKILL.md   ─┼─ !`${CLAUDE_PLUGIN_ROOT}/scripts/print-rules.sh`  →  skills/rua/rules.md
skills/ua/SKILL.md   ─┘
                         model output → scripts/check-letters.sh 'v1' 'v2' ...
```

- `skills/rua/rules.md` holds everything shared: alphabet, rephrasing rules,
  typical moves, workflow, output format, examples. Edit rules here only.
- Each `SKILL.md` holds what differs: mode handling, the empty-input usage
  line, the checker command, and `Input: $ARGUMENTS`.
- `scripts/check-letters.sh <variant>...` prints
  `variant <N>: '<char>' U+<HEX> in "<word>"`,
  `variant <N>: mixed Latin and Cyrillic in "<run>"` or
  `variant <N>: Latin '<letter>' used as a Cyrillic word`; exit 0 clean,
  1 problems, 2 no arguments. Allowed letters, apostrophes and Latin
  look-alike words are data at the top of the file. Links (`://`, `www.`,
  `host.tld/`) are skipped because they are copied from the message unchanged.
- The model checks apostrophes itself before calling the checker: an
  apostrophe inside a single-quoted argument is silently eaten by the shell.

## Principles

- Meaning and natural language over literal wording; never add or drop facts.
- Output is only copy-ready variants, no commentary.
- Deterministic checks wherever a rule is mechanical.
- No runtime dependencies beyond bash and perl 5 core modules.

## Build, run, test

| Command | Purpose |
|---|---|
| `just test` | script tests (bash 3.2 compatible, no framework) |
| `just lint` | shellcheck, skipped with a warning if missing |
| `just validate` | `claude plugin validate .` |
| `just ci` | `lint` → `validate` → `test`, exactly what GitHub CI runs |
| `just eval` | `claude plugin eval` over `evals/`, regex graders only; needs login, costs usage |
| `claude --plugin-dir=.` | load the working copy interactively, then `/reload-plugins` after edits |

Text quality (grammar, naturalness, meaning) is judged by a human reading the
eval report. There is no LLM judge on purpose.

## Gotchas

- Plugin commands are always namespaced: `/rua:rua`, never `/rua`.
- Skills must not `cat` plugin files in `!` injections: Claude Code blocks
  `cat` on paths outside the session working directory, and an installed
  plugin is always outside it. That is why `scripts/print-rules.sh` exists.
- `${CLAUDE_PLUGIN_ROOT}` is substituted in `SKILL.md` text and in
  `allowed-tools` Bash rules. Do not rely on it inside `rules.md`.
- Use `$ARGUMENTS`, never `$0`: indexed arguments use shell-style splitting and
  break on quotes and apostrophes in the message.
- `plugin.json` has no `version` on purpose: every commit on `main` is an update
  for users. Keep unfinished work off `main`.
- The checker normalizes to NFC first: `е` + U+0308 is `ё` and fails.
- `/bin/bash` on macOS is 3.2: no `\u` escapes, no associative arrays.
- Text written in this repo in Russian or Ukrainian for users (README section,
  examples) must itself pass `scripts/check-letters.sh`.

## Map

```
.claude-plugin/plugin.json       plugin manifest (no version)
.claude-plugin/marketplace.json  single-plugin marketplace, source "./"
skills/rua/SKILL.md              /rua:rua, mode from first word
skills/rua/rules.md              shared rules and examples
skills/ru/SKILL.md, skills/ua/SKILL.md   fixed-mode commands
scripts/check-letters.sh         deterministic letter checker
scripts/print-rules.sh           prints rules.md for ! injection
tests/                           script tests
evals/<case>/                    claude plugin eval cases and regex graders
justfile                         all dev entrypoints
```
