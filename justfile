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
        --allow-tools "Bash({{justfile_directory()}}/scripts/check-letters.sh *)" \
        "Bash({{justfile_directory()}}/scripts/print-rules.sh)" {{args}}

# Full pre-push battery: CI gates plus the eval run
check: ci eval

# ─── Release ──────────────────────────────────────────────────────

# Print the version a release would carry
version:
    @echo {{version}}

# Tag release X.Y.Z after the CI gates; prints the publish commands instead of running them
release new_version: ci
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! "{{new_version}}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "error: '{{new_version}}' is not a semantic version X.Y.Z" >&2
        exit 1
    fi
    if [[ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]]; then
        echo "error: releases are tagged on main" >&2
        exit 1
    fi
    if [[ -n "$(git status --porcelain)" ]]; then
        echo "error: working tree is not clean" >&2
        exit 1
    fi
    tag="v{{new_version}}"
    git tag -a "$tag" -m "Release $tag."
    echo "Tagged $tag. To publish, run:"
    echo "  git push origin $tag"
    origin="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "$origin" == *github.com* ]] && command -v gh >/dev/null; then
        echo "  gh release create $tag --generate-notes"
    fi

# Release the next patch, minor or major version
bump part:
    #!/usr/bin/env bash
    set -euo pipefail
    current="$(git describe --tags --abbrev=0 2>/dev/null || echo v0.0.0)"
    IFS=. read -r major minor patch <<< "${current#v}"
    case "{{part}}" in
        patch) patch=$((patch + 1)) ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        major) major=$((major + 1)); minor=0; patch=0 ;;
        *) echo "error: part must be patch, minor or major" >&2; exit 1 ;;
    esac
    just release "$major.$minor.$patch"
