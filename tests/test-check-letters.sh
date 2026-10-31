#!/usr/bin/env bash
# Tests for scripts/check-letters.sh.
# Compatible with bash 3.2 (macOS default): decomposed characters are written
# as raw UTF-8 bytes because bash 3.2 has no \u escapes.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly REPO_ROOT
readonly CHECKER="$REPO_ROOT/scripts/check-letters.sh"

readonly NFD_YO=$'\xd0\xb5\xcc\x88'          # е + U+0308 COMBINING DIAERESIS
readonly NFD_SHORT_I=$'\xd0\xb8\xcc\x86\xd0\xb4\xd1\x83'  # и + U+0306 COMBINING BREVE + "ду"

failures=0

# expect_check NAME EXPECTED_EXIT EXPECTED_STDOUT_SUBSTRING [ARGS...]
# An empty EXPECTED_STDOUT_SUBSTRING means stdout must be empty.
expect_check() {
    local name="$1" expected_exit="$2" expected_out="$3"
    shift 3
    local out exit_code
    out="$("$CHECKER" "$@" 2>/dev/null)"
    exit_code=$?

    local problem=""
    if [[ "$exit_code" != "$expected_exit" ]]; then
        problem="exit $exit_code, expected $expected_exit"
    elif [[ -z "$expected_out" && -n "$out" ]]; then
        problem="expected empty stdout, got: $out"
    elif [[ -n "$expected_out" && "$out" != *"$expected_out"* ]]; then
        problem="stdout lacks '$expected_out', got: $out"
    fi

    if [[ -n "$problem" ]]; then
        echo "FAIL $name: $problem"
        failures=$((failures + 1))
    else
        echo "ok   $name"
    fi
}

expect_check clean_ru               0 "" "Привет! Сейчас не могу говорить, перезвоню вечером."
expect_check clean_ua               0 "" "Ми вже рушили, будемо хвилин за двадцять."
expect_check latin_digits_emoji_url 0 "" "Встреча в 7-й, адрес https://x.io/a?b=1 👍"
expect_check ru_y                   1 "'ы' U+044B in \"Мы\"" "Мы едем"
expect_check ua_i                   1 "'і' U+0456" "Привіт"
expect_check upper_E                1 "'Э' U+042D" "Это всё"
expect_check upper_Ye               1 "'Є' U+0404" "Є питання"
expect_check yo                     1 "'ё' U+0451" "ещё"
expect_check hard_sign              1 "'ъ'" "объявление"
expect_check ghe                    1 "'ґ'" "ґанок"
expect_check belarusian_u           1 "'ў'" "ўсё"
expect_check apostrophe_ascii       1 "U+0027" "п'ять"
expect_check apostrophe_right       1 "U+2019" "п’ять"
expect_check apostrophe_modifier    1 "U+02BC" "пʼять"
expect_check nfd_yo                 1 "'ё' U+0451" "$NFD_YO"
expect_check nfd_short_i            0 "" "$NFD_SHORT_I"
expect_check mixed_latin_i          1 "mixed Latin and Cyrillic in \"мiсто\"" "мiсто"
expect_check second_variant_index   1 "variant 2:" "чисто" "быстро"
expect_check no_args                2 ""

if (( failures > 0 )); then
    echo "$failures test(s) failed"
    exit 1
fi
echo "all tests passed"
