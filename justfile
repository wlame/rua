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

# Validate plugin and marketplace manifests (the missing-version warning is expected)
validate:
    claude plugin validate .

# Run the script tests
test:
    bash tests/test-check-letters.sh
    bash tests/test-print-rules.sh

# Run the gates GitHub CI runs, in the same order
ci: lint validate test

# ─── Model runs (need Claude Code auth, cost usage, vary between runs) ──

# Run the eval cases once each; read the report to judge text quality
eval *args:
    claude plugin eval . --ablation=none --runs=1 --no-publish \
        --allow-tools "Bash(*check-letters.sh *)" "Bash(*print-rules.sh)" {{args}}

# Full pre-push battery: CI gates plus the eval run
check: ci eval
