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

# One-letter Latin words that look like Cyrillic one-letter words (а, с, і, к,
# о, у). Standing alone in Cyrillic text they are a look-alike substitution,
# such as "мама i тато". Uppercase is left out so "витамин C" or "план A" pass;
# "I" is kept because it is the sentence-start form of the Ukrainian "І".
readonly LATIN_LOOKALIKE_WORDS="a c i k o y I"

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
export RUA_LATIN_LOOKALIKE_WORDS="$LATIN_LOOKALIKE_WORDS"

# shellcheck disable=SC2016  # $-signs below are perl variables, not shell.
exec perl -CSA -Mstrict -Mwarnings -MEncode=decode -MUnicode::Normalize=NFC -e '
    # Environment values arrive as UTF-8 bytes; -CSA covers only @ARGV and stdio.
    my $allowed     = decode("UTF-8", $ENV{RUA_ALLOWED_CYRILLIC});
    my $apostrophes = decode("UTF-8", $ENV{RUA_FORBIDDEN_APOSTROPHES});
    my %is_allowed  = map { $_ => 1 } split //, $allowed . uc($allowed);
    my %is_apostrophe = map { $_ => 1 } split //, $apostrophes;
    my %is_lookalike_word = map { $_ => 1 } split / /, $ENV{RUA_LATIN_LOOKALIKE_WORDS};
    my $quoted_apostrophes = quotemeta $apostrophes;

    # Links are copied from the original message unchanged, so they are not
    # checked: "https://...", "www.x.y", or "host.tld/path".
    sub is_link { $_[0] =~ m{://|^www\.|^[\p{L}\d.-]+\.\p{L}{2,}/} }

    my $has_problem = 0;
    my $index = 0;
    for my $variant (@ARGV) {
        $index++;
        # NFC first: "е" + U+0308 must be seen as "ё", "и" + U+0306 as "й".
        my $text = NFC($variant);
        my $has_cyrillic = $text =~ /\p{Cyrillic}/;
        for my $token (split /\s+/, $text) {
            next if is_link($token);
            # Trim punctuation around the word but keep apostrophes inside it.
            (my $word = $token) =~ s/^[^\p{L}$quoted_apostrophes]+|[^\p{L}$quoted_apostrophes]+$//g;
            next if $word eq "";

            for my $char (split //, $word) {
                my $is_bad_cyrillic = $char =~ /\p{Cyrillic}/ && !$is_allowed{$char};
                next unless $is_bad_cyrillic || $is_apostrophe{$char};
                printf "variant %d: %s%s%s U+%04X in \"%s\"\n",
                    $index, chr(39), $char, chr(39), ord($char), $word;
                $has_problem = 1;
            }

            # A Latin letter inside a run of Cyrillic letters is a look-alike
            # substitution such as "мiсто". Runs split on hyphens and other
            # non-letters, so "SMS-ка" and "IT-шник" pass.
            for my $run (split /[^\p{L}$quoted_apostrophes]+/, $word) {
                next unless $run =~ /\p{Latin}/ && $run =~ /\p{Cyrillic}/;
                print "variant $index: mixed Latin and Cyrillic in \"$run\"\n";
                $has_problem = 1;
            }

            if ($has_cyrillic && $is_lookalike_word{$word}) {
                printf "variant %d: Latin %s%s%s used as a Cyrillic word\n",
                    $index, chr(39), $word, chr(39);
                $has_problem = 1;
            }
        }
    }
    exit($has_problem ? 1 : 0);
' -- "$@"
