#!/usr/bin/env bash
# Check that text uses only characters typable on both the Russian and the
# Ukrainian keyboard layout.
#
# Usage: check-letters.sh <variant>...
#   One argument is one variant. Prints one line per problem:
#     variant <N>: '<char>' U+<HEX> in "<word>"
#     variant <N>: mixed Latin and Cyrillic in "<word>"
#   Exit codes: 0 = clean, 1 = problems found, 2 = no arguments.
#
# Only Cyrillic letters and apostrophes are restricted. Digits, Latin,
# punctuation, emoji and URL characters pass.
set -euo pipefail

# The 29 Cyrillic letters present on both layouts (lowercase; uppercase is
# derived). Any other Cyrillic letter is a problem.
readonly ALLOWED_CYRILLIC="абвгдежзийклмнопрстуфхцчшщьюя"

# Apostrophes: the Russian layout has none, so Ukrainian words that need one
# cannot be typed. U+0027 APOSTROPHE, U+2019 RIGHT SINGLE QUOTATION MARK,
# U+02BC MODIFIER LETTER APOSTROPHE.
readonly FORBIDDEN_APOSTROPHES="'’ʼ"

if (( $# == 0 )); then
    echo "usage: $(basename "$0") <variant>..." >&2
    exit 2
fi

# perl reads arguments and writes output as UTF-8 because of -CSA, so the
# locale does not matter. LC_ALL=C avoids perl warnings on machines with a
# misconfigured locale.
export LC_ALL=C
export RUA_ALLOWED_CYRILLIC="$ALLOWED_CYRILLIC"
export RUA_FORBIDDEN_APOSTROPHES="$FORBIDDEN_APOSTROPHES"

# shellcheck disable=SC2016  # $-signs below are perl variables, not shell.
exec perl -CSA -Mstrict -Mwarnings -MEncode=decode -MUnicode::Normalize=NFC -e '
    # Environment values arrive as UTF-8 bytes; -CSA covers only @ARGV and stdio.
    my $allowed     = decode("UTF-8", $ENV{RUA_ALLOWED_CYRILLIC});
    my $apostrophes = decode("UTF-8", $ENV{RUA_FORBIDDEN_APOSTROPHES});
    my %is_allowed  = map { $_ => 1 } split //, $allowed . uc($allowed);
    my %is_apostrophe = map { $_ => 1 } split //, $apostrophes;

    my $has_problem = 0;
    my $index = 0;
    for my $variant (@ARGV) {
        $index++;
        # NFC first: "е" + U+0308 must be seen as "ё", "и" + U+0306 as "й".
        for my $token (split /\s+/, NFC($variant)) {
            # Trim punctuation around the word but keep apostrophes inside it.
            (my $word = $token) =~ s/^[^\p{L}$apostrophes]+|[^\p{L}$apostrophes]+$//g;
            next if $word eq "";

            for my $char (split //, $word) {
                my $is_bad_cyrillic = $char =~ /\p{Cyrillic}/ && !$is_allowed{$char};
                next unless $is_bad_cyrillic || $is_apostrophe{$char};
                printf "variant %d: %s%s%s U+%04X in \"%s\"\n",
                    $index, chr(39), $char, chr(39), ord($char), $word;
                $has_problem = 1;
            }

            # A Latin letter inside a Cyrillic word is a look-alike
            # substitution such as "мiсто" with Latin "i".
            if ($word =~ /\p{Latin}/ && $word =~ /\p{Cyrillic}/) {
                print "variant $index: mixed Latin and Cyrillic in \"$word\"\n";
                $has_problem = 1;
            }
        }
    }
    exit($has_problem ? 1 : 0);
' -- "$@"
