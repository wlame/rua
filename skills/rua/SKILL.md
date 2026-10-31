---
name: rua
description: Rephrase a short chat message into Russian and Ukrainian using only the Cyrillic letters shared by both keyboard layouts. An optional first word ru or ua limits the output to one language.
argument-hint: "[ru|ua] <text>"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/print-rules.sh) Bash(${CLAUDE_PLUGIN_ROOT}/scripts/check-letters.sh *)
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/print-rules.sh`

## This command

**Mode.** Look at the first whitespace-separated word of the input below. If
it is exactly `ru` or `ua` (any letter case), it is the mode and the rest of
the input is the text. Otherwise the whole input is the text and you answer
in both languages.

| Mode | Output |
|---|---|
| none | `RU` block, then `UA` block |
| `ru` | `RU` block only |
| `ua` | `UA` block only |

**Empty text.** If there is no text, reply with exactly this line and nothing
else:

```text
/rua:rua [ru|ua] <текст>
```

**Checker command:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-letters.sh 'variant one' 'variant two'
```

Input: $ARGUMENTS
