set shell := ["bash", "-uc"]

version := `git describe --tags --dirty --always 2>/dev/null || echo dev`
shell_scripts := "scripts/*.sh tests/*.sh"

# List available recipes
default:
    @just --list --unsorted

# ─── Quality gates ────────────────────────────────────────────────

# Lint shell scripts with shellcheck (warns and skips if it is not installed)
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v shellcheck >/dev/null; then
        echo "warning: shellcheck not installed, skipping lint" >&2
        exit 0
    fi
    shellcheck {{shell_scripts}}

# Run the letter checker tests
test:
    bash tests/test-check-letters.sh
