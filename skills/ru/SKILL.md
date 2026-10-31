---
name: ru
description: Rephrase a short chat message into Russian using only the Cyrillic letters shared by the Russian and Ukrainian keyboard layouts.
argument-hint: "<text>"
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/print-rules.sh) Bash(${CLAUDE_PLUGIN_ROOT}/scripts/check-letters.sh *)
---

!`${CLAUDE_PLUGIN_ROOT}/scripts/print-rules.sh`

## This command

**Mode:** Russian only. Output the `RU` block and nothing else. The whole
input is the text, whatever its first word is.

**Empty text.** If there is no text, reply with exactly this line and nothing
else:

```text
/rua:ru <текст>
```

**Checker command:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-letters.sh 'variant one' 'variant two'
```

Input: $ARGUMENTS
