# rua

A [Claude Code](https://code.claude.com) plugin that rephrases a short chat
message into Russian and Ukrainian using only the Cyrillic letters that exist
on **both** keyboard layouts.

## Why

You speak both languages, but the device in front of you has only one
Cyrillic layout installed, Russian or Ukrainian. You want to answer someone in
their language without installing a second layout. Simple letter replacement
does not work (`він` is not `вин`), so the plugin uses Claude to find other
words and sentence structures that keep the meaning and read naturally.

## Install

```bash
claude plugin marketplace add wlame/rua
claude plugin install rua@rua
```

Or inside a Claude Code session:

```text
/plugin marketplace add wlame/rua
/plugin install rua@rua
```

## Usage

| Command | Output |
|---|---|
| `/rua:rua <text>` | Russian and Ukrainian variants |
| `/rua:rua ru <text>` | Russian only |
| `/rua:rua ua <text>` | Ukrainian only |
| `/rua:ru <text>` | Russian only |
| `/rua:ua <text>` | Ukrainian only |

Claude Code always prefixes plugin commands with the plugin name, so there is
no bare `/rua`.

Example:

```text
/rua:rua Мы уже выехали, будем минут через двадцать.
```

Output (2-3 variants per language, each in its own copyable block):

````text
RU

```text
Уже едем, будем минут через двадцать.
```

UA

```text
Ми вже рушили, будемо хвилин за двадцять.
```
````

## The alphabet

Allowed (both layouts):

```text
а б в г д е ж з и й к л м н о п р с т у ф х ц ч ш щ ь ю я
```

Never used: `ё ъ ы э` (Russian layout only), `і ї є ґ` (Ukrainian layout
only), apostrophes. Digits, Latin letters, punctuation, emoji and links pass
unchanged. A proper noun that cannot be written without a forbidden letter,
such as «Київ», is kept as it is when rephrasing around it would lose meaning.

Every variant is checked by a deterministic script before you see it, because
language models often slip a `і` or a `ы` into the text.

## Updates

`plugin.json` has no `version` field, so Claude Code treats each commit on
`main` as a new version. Update with `/plugin` or
`claude plugin update rua@rua`.

## Development

Requires [just](https://github.com/casey/just), bash and perl 5.
[shellcheck](https://www.shellcheck.net) is optional locally.

| Recipe | What it does |
|---|---|
| `just test` | Tests for the letter checker and the rules printer |
| `just lint` | shellcheck on all scripts |
| `just validate` | `claude plugin validate .` |
| `just ci` | `lint`, `validate`, `test`: the same gates as GitHub CI |
| `just eval` | Runs the eval cases through Claude once each (needs Claude Code login, costs usage) |
| `just check` | `ci` plus `eval` |

Try the plugin from a working copy:

```bash
claude --plugin-dir=.
```

## RU / UA

Плагин для Claude Code. Пишет короткое сообщение для чата по-русски и
по-украински только теми буквами, что есть на обеих раскладках.

Додаток для Claude Code, щоб переписати короткий текст для чату двома мовами
лише тими буквами, котрими можна писати на обох розкладках.

```text
/rua:rua текст   - текст на русском и украинском / текст двома мовами
/rua:ru текст    - только русский / лише RU
/rua:ua текст    - только украинский / лише UA
```

## License

MIT
