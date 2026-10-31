#!/usr/bin/env bash
# Print the shared rua rules so skills can inject them with !`...`.
#
# Skills cannot `cat` the file directly: Claude Code blocks `cat` on paths
# outside the session's working directory, and an installed plugin always
# lives outside it. Running this script is allowed by the skills'
# `allowed-tools` rule instead.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR

cat "$SCRIPT_DIR/../skills/rua/rules.md"
