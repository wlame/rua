#!/usr/bin/env bash
# Tests for scripts/print-rules.sh: it must print skills/rua/rules.md exactly,
# from any working directory (skills run it with the user's cwd).
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly REPO_ROOT

failures=0

check() {
    local name="$1" problem="$2"
    if [[ -n "$problem" ]]; then
        echo "FAIL $name: $problem"
        failures=$((failures + 1))
    else
        echo "ok   $name"
    fi
}

expected="$(cat "$REPO_ROOT/skills/rua/rules.md")"

actual="$(cd / && "$REPO_ROOT/scripts/print-rules.sh")"
exit_code=$?
problem=""
[[ "$exit_code" == 0 ]] || problem="exit $exit_code"
[[ -z "$problem" && "$actual" != "$expected" ]] && problem="output differs from rules.md"
check prints_rules_from_other_cwd "$problem"

if (( failures > 0 )); then
    echo "$failures test(s) failed"
    exit 1
fi
echo "all tests passed"
