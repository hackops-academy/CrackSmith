#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
╔═══════════════════════════════════════════════════════════════╗
║          CrackSmith v3.0 — Advanced Wordlist Generator        ║
║          For authorized security testing & education only     ║
║          License: MIT                                         ║
╚═══════════════════════════════════════════════════════════════╝
"""

import sys
import os
import itertools
import time
import signal
import argparse
import hashlib
import re
import random
import string
from pathlib import Path
from typing import Generator, Iterator

# ──────────────────────────────────────────────────────────────
# ANSI Colors
# ──────────────────────────────────────────────────────────────
class C:
    RED    = '\033[91m'
    GREEN  = '\033[92m'
    YELLOW = '\033[93m'
    BLUE   = '\033[94m'
    CYAN   = '\033[96m'
    MAGENTA= '\033[95m'
    BOLD   = '\033[1m'
    DIM    = '\033[2m'
    END    = '\033[0m'

VERSION = "3.0"

# ──────────────────────────────────────────────────────────────
# Banner
# ──────────────────────────────────────────────────────────────
def banner():
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"{C.GREEN}{C.BOLD}")
    print(r"""
 ██████╗██████╗  █████╗  ██████╗██╗  ██╗███████╗███╗   ███╗██╗████████╗██╗  ██╗
██╔════╝██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝████╗ ████║██║╚══██╔══╝██║  ██║
██║     ██████╔╝███████║██║     █████╔╝ ███████╗██╔████╔██║██║   ██║   ███████║
██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║██║╚██╔╝██║██║   ██║   ██╔══██║
╚██████╗██║  ██║██║  ██║╚██████╗██║  ██╗███████║██║ ╚═╝ ██║██║   ██║   ██║  ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝
    """)
    print(f"   {C.CYAN}v{VERSION} | Advanced Wordlist Engine | github: hackops-academy{C.END}")
    print(f"\n{C.YELLOW}  ⚠  AUTHORIZED USE ONLY — Unauthorized access is illegal.{C.END}")
    print(f"{C.DIM}  For penetration testing and security research only.{C.END}")
    print(f"\n{'─' * 72}\n")


# ──────────────────────────────────────────────────────────────
# Leet Speak Engine (v2: full permutation up to configurable depth)
# ──────────────────────────────────────────────────────────────
LEET_MAP = {
    'a': ['4', '@', 'a'],
    'e': ['3', 'e'],
    'i': ['1', '!', 'i'],
    'o': ['0', 'o'],
    's': ['$', '5', 's'],
    't': ['7', '+', 't'],
    'b': ['8', 'b'],
    'g': ['9', 'g'],
    'l': ['1', 'l'],
    'z': ['2', 'z'],
}

def leet_variations(word: str, max_variants: int = 20) -> set:
    """Full leet permutation, capped to avoid combinatorial explosion."""
    word = word.lower()
    # Build list of options per character
    options = []
    for ch in word:
        if ch in LEET_MAP:
            options.append(LEET_MAP[ch])
        else:
            options.append([ch])

    results = set()
    for combo in itertools.product(*options):
        results.add("".join(combo))
        if len(results) >= max_variants:
            break
    return results


# ──────────────────────────────────────────────────────────────
# Casing Engine
# ──────────────────────────────────────────────────────────────
def casing_variations(word: str) -> set:
    """All standard casing variants + title-case hybrid."""
    variants = {
        word,
        word.lower(),
        word.upper(),
        word.capitalize(),
        word.swapcase(),
        word.title(),
    }
    # camelCase-like: first char lower, rest capitalized per word
    if ' ' in word:
        parts = word.split()
        variants.add(parts[0].lower() + "".join(p.capitalize() for p in parts[1:]))
    return variants


# ──────────────────────────────────────────────────────────────
# Common Pattern Appendages
# ──────────────────────────────────────────────────────────────
SUFFIXES = [
    "", "1", "12", "123", "1234", "12345", "!", "!!", ".", "@",
    "01", "007", "69", "99", "100",
    "2020", "2021", "2022", "2023", "2024", "2025", "2026",
    "#1", "$1", "abc", "pass", "pwd",
]

# Complexity-aware suffixes: guarantee digit + symbol in one append
# Used when strict complexity filters are active
COMPLEX_SUFFIXES = [
    "1!", "1@", "12!", "12@", "123!", "123@", "1#", "1$",
    "2!", "2@", "0!", "0@", "01!", "01@",
    "2024!", "2024@", "2025!", "2025@", "2026!", "2026@",
    "007!", "007@", "99!", "99$", "69!", "69@",
    "#1!", "$1!", "1!A", "0!A", "@123", "!123",
    "1!a", "0!a", "@12", "!12", "#12", "$12",
]

PREFIXES = [
    "", "the", "my", "i", "mr", "ms", "dr",
    "super", "mega", "1", "01",
]

SEPARATORS = ["", "_", ".", "-", "@", "!", "#"]


# ──────────────────────────────────────────────────────────────
# Profile Generator
# ──────────────────────────────────────────────────────────────
def expand_word(word: str, leet: bool = True) -> set:
    """Expand a single word into all case + leet variants."""
    results = set()
    for cased in casing_variations(word):
        if leet:
            results.update(leet_variations(cased))
        else:
            results.add(cased)
    return results


def profile_generator(data: dict, leet: bool = True, combos: int = 2) -> Generator:
    """
    Yields wordlist entries from profile data.
    combos: max number of words to combine (2 = pairs, 3 = triplets)
    """
    raw = [v.strip() for v in data.values() if v and v.strip()]
    if not raw:
        print(f"{C.RED}[!] No profile data entered.{C.END}")
        return

    # --- Expand each raw token into case + leet variants ---
    expanded_pool = set()
    for word in raw:
        expanded_pool.update(expand_word(word, leet=leet))

    # Also keep original raw tokens (unexpanded) for combos — important
    # so short tokens like "X", "Y", "1234" still participate in pairs
    for word in raw:
        expanded_pool.add(word)
        expanded_pool.add(word.lower())
        expanded_pool.add(word.capitalize())
        expanded_pool.add(word.upper())

    pool = list(expanded_pool)

    # 1. Singles + all suffixes (plain + complex)
    all_suffixes = SUFFIXES + COMPLEX_SUFFIXES
    for word in pool:
        yield word
        for suf in all_suffixes:
            if suf:
                yield f"{word}{suf}"
        # Also prepend digits/symbols for complexity variety
        for pre in ["1", "01", "!", "@", "#", "$"]:
            yield f"{pre}{word}"
            yield f"{pre}{word}!"
            yield f"{pre}{word}1"

    # 2. Pairs — Word+Sep+Word with complex suffixes
    if combos >= 2:
        pair_suffixes = ["", "1", "!", "123", "!1", "1!", "@1", "2024", "2025",
                         "12!", "1@", "#1", "$1", "!23", "123!", "007", "69!"]
        for a, b in itertools.permutations(pool, 2):
            for sep in SEPARATORS:
                base = f"{a}{sep}{b}"
                yield base
                for suf in pair_suffixes:
                    yield f"{base}{suf}"
            # Capital prefix variant — guarantees uppercase
            yield f"{a.capitalize()}{b}1!"
            yield f"{a.capitalize()}{b}@1"
            yield f"{a.upper()}{b}1!"

    # 3. Triplets — raised pool limit, no cap on raw tokens
    #    We limit combinations to prevent file explosion, not pool size
    if combos >= 3:
        triplet_suffixes = ["1!", "!", "1", "123!", "@1", "#1"]
        # Use raw tokens (not expanded pool) for triplets to keep manageable
        raw_upper = [w.strip() for w in raw if w.strip()]
        raw_pool  = []
        for w in raw_upper:
            raw_pool += [w, w.capitalize(), w.upper(), w.lower()]
        raw_pool = list(set(raw_pool))

        for a, b, c in itertools.permutations(raw_pool, min(3, len(raw_pool))):
            yield f"{a}{b}{c}"
            yield f"{a}_{b}_{c}"
            yield f"{a.capitalize()}{b}{c}1!"
            yield f"{a}{b.capitalize()}{c}@1"
            for suf in triplet_suffixes:
                yield f"{a}{b}{c}{suf}"


# ──────────────────────────────────────────────────────────────
# Mask Generator (Hashcat-compatible)
# ──────────────────────────────────────────────────────────────
MASK_CHARSET = {
    '?d': '0123456789',
    '?l': 'abcdefghijklmnopqrstuvwxyz',
    '?u': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    '?s': '!@#$%^&*()-_=+[]{}|;:,.<>?',
    '?a': string.printable.strip(),
    '?h': '0123456789abcdef',
    '?H': '0123456789ABCDEF',
}

def parse_mask(mask: str) -> list:
    """Parse a hashcat-style mask into a list of character sets."""
    tokens = []
    i = 0
    while i < len(mask):
        if mask[i] == '?' and i + 1 < len(mask):
            key = mask[i:i+2]
            if key in MASK_CHARSET:
                tokens.append(MASK_CHARSET[key])
                i += 2
                continue
        tokens.append([mask[i]])  # literal
        i += 1
    return tokens

def mask_generator(mask: str) -> Generator:
    """Yields all combinations defined by a hashcat-style mask."""
    tokens = parse_mask(mask)
    if not tokens:
        return
    total = 1
    for t in tokens:
        total *= len(t)
    print(f"  {C.CYAN}[i] Mask space: {total:,} combinations{C.END}")
    for combo in itertools.product(*tokens):
        yield "".join(combo)


# ──────────────────────────────────────────────────────────────
# Numeric Range Generator
# ──────────────────────────────────────────────────────────────
def numeric_range_generator(start: int, end: int, pad: int = 0) -> Generator:
    for n in range(start, end + 1):
        yield str(n).zfill(pad) if pad else str(n)


# ──────────────────────────────────────────────────────────────
# Wordlist Mutator (mutate an existing wordlist file)
# ──────────────────────────────────────────────────────────────
def mutate_wordlist(filepath: str, leet: bool = True, rules: list = None) -> Generator:
    """
    Reads an existing wordlist and applies mutation rules.
    Rules: list of strings — 'leet', 'case', 'suffix', 'prefix', 'reverse', 'duplicate'
    """
    if rules is None:
        rules = ['leet', 'case', 'suffix']

    path = Path(filepath)
    if not path.exists():
        print(f"{C.RED}[!] File not found: {filepath}{C.END}")
        return

    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        for raw_line in f:
            word = raw_line.strip()
            if not word:
                continue

            yield word  # Always yield original

            if 'case' in rules:
                yield from casing_variations(word)

            if 'leet' in rules:
                yield from leet_variations(word)

            if 'reverse' in rules:
                yield word[::-1]

            if 'duplicate' in rules:
                yield word + word
                yield word[0].upper() + word[1:] + word

            if 'suffix' in rules:
                for suf in SUFFIXES:
                    if suf:
                        yield f"{word}{suf}"

            if 'prefix' in rules:
                for pre in PREFIXES:
                    if pre:
                        yield f"{pre}{word}"


# ──────────────────────────────────────────────────────────────
# Pattern-Based Generator (dates, phones, PINs, etc.)
# ──────────────────────────────────────────────────────────────
def pattern_generator(pattern_type: str, **kwargs) -> Generator:
    """Generates common pattern families."""

    if pattern_type == 'dates':
        start_year = kwargs.get('start', 1970)
        end_year   = kwargs.get('end', 2026)
        for y in range(start_year, end_year + 1):
            for m in range(1, 13):
                for d in range(1, 32):
                    date_str = f"{d:02d}{m:02d}{y}"
                    yield date_str
                    yield f"{d:02d}/{m:02d}/{y}"
                    yield f"{y}{m:02d}{d:02d}"
                    yield f"{m:02d}{d:02d}{y}"

    elif pattern_type == 'pins':
        length = kwargs.get('length', 4)
        for combo in itertools.product('0123456789', repeat=length):
            yield "".join(combo)

    elif pattern_type == 'phones':
        # Common format stubs — user provides country prefix
        prefix = kwargs.get('prefix', '')
        for n in range(1000000000, 9999999999):
            yield f"{prefix}{n}"  # Caution: huge range

    elif pattern_type == 'keyboard_walks':
        rows = [
            "qwertyuiop", "asdfghjkl", "zxcvbnm",
            "1234567890", "qwerty", "asdf", "zxcv",
        ]
        for row in rows:
            yield row
            yield row[::-1]
            yield row.capitalize()
            yield row.upper()
            for i in range(len(row) - 2):
                yield row[i:i+4]
                yield row[i:i+6]


# ──────────────────────────────────────────────────────────────
# Deduplication Filter (streaming, memory-efficient)
# ──────────────────────────────────────────────────────────────
def dedup_generator(gen: Iterator, use_bloom: bool = False) -> Generator:
    """
    Stream-deduplicates a generator.
    For huge sets: use_bloom=True uses a hash-based approximation (no false negatives guaranteed).
    """
    seen = set()
    for item in gen:
        if item not in seen:
            seen.add(item)
            yield item


# ──────────────────────────────────────────────────────────────
# Min/Max Length Filter
# ──────────────────────────────────────────────────────────────
def length_filter(gen: Iterator, min_len: int = 0, max_len: int = 9999) -> Generator:
    for item in gen:
        if min_len <= len(item) <= max_len:
            yield item


# ──────────────────────────────────────────────────────────────
# Charset Filter (only output words containing required charsets)
# ──────────────────────────────────────────────────────────────
def complexity_filter(gen: Iterator, require_upper: bool = False,
                      require_digit: bool = False, require_special: bool = False) -> Generator:
    for item in gen:
        if require_upper and not any(c.isupper() for c in item):
            continue
        if require_digit and not any(c.isdigit() for c in item):
            continue
        if require_special and not any(c in string.punctuation for c in item):
            continue
        yield item


# ──────────────────────────────────────────────────────────────
# Output Writer with Progress
# ──────────────────────────────────────────────────────────────
def write_wordlist(gen: Iterator, filename: str, dedup: bool = True,
                   min_len: int = 0, max_len: int = 9999,
                   require_upper: bool = False, require_digit: bool = False,
                   require_special: bool = False):

    print(f"\n{C.YELLOW}[*] Building pipeline...{C.END}")

    pipeline = gen
    pipeline = length_filter(pipeline, min_len, max_len)
    pipeline = complexity_filter(pipeline, require_upper, require_digit, require_special)
    if dedup:
        pipeline = dedup_generator(pipeline)

    print(f"{C.YELLOW}[*] Writing to: {os.path.abspath(filename)}{C.END}\n")

    count = 0
    start = time.time()
    bar_width = 40

    try:
        with open(filename, 'w', encoding='utf-8', errors='ignore') as f:
            for line in pipeline:
                f.write(line + '\n')
                count += 1
                if count % 100_000 == 0:
                    elapsed = time.time() - start
                    rate = count / elapsed if elapsed > 0 else 0
                    filled = min(bar_width, int((count / 5_000_000) * bar_width))
                    bar = '█' * filled + '░' * (bar_width - filled)
                    sys.stdout.write(
                        f"\r  {C.CYAN}[{bar}]{C.END} {count:>10,} lines | "
                        f"{rate:>10,.0f}/s | {elapsed:.1f}s"
                    )
                    sys.stdout.flush()

    except KeyboardInterrupt:
        print(f"\n\n{C.RED}[!] Interrupted — partial file saved.{C.END}")

    elapsed = time.time() - start
    size_kb = os.path.getsize(filename) / 1024
    print(f"\n\n{'─'*60}")

    if count == 0:
        print(f"  {C.RED}✘  WARNING: 0 lines generated!{C.END}")
        print(f"  {C.YELLOW}   Your filters are too strict for the generated words.{C.END}")
        print(f"  {C.YELLOW}   Suggestions:{C.END}")
        print(f"  {C.YELLOW}   • Loosen min/max length (e.g. 6–16 instead of 8–8){C.END}")
        print(f"  {C.YELLOW}   • Remove require_upper / require_digit / require_symbol{C.END}")
        print(f"  {C.YELLOW}   • Add more profile tokens (name, nick, pet, etc.){C.END}")
        print(f"  {C.YELLOW}   • Use combos=2 first to verify output, then add filters{C.END}")
    else:
        print(f"  {C.GREEN}✔  Lines  : {count:,}{C.END}")
        print(f"  {C.GREEN}✔  Size   : {size_kb:,.1f} KB{C.END}")
        print(f"  {C.GREEN}✔  Time   : {elapsed:.2f}s{C.END}")
        if elapsed > 0:
            print(f"  {C.GREEN}✔  Speed  : {count/elapsed:,.0f} lines/sec{C.END}")
        print(f"  {C.GREEN}✔  File   : {os.path.abspath(filename)}{C.END}")
    print(f"{'─'*60}\n")


# ──────────────────────────────────────────────────────────────
# Interactive Profile Menu
# ──────────────────────────────────────────────────────────────
def interactive_profile() -> dict:
    print(f"\n{C.BLUE}{'─'*50}")
    print(f"  PROFILE MODE  —  Leave blank to skip")
    print(f"{'─'*50}{C.END}\n")
    fields = [
        ('first',   'First Name      '),
        ('last',    'Last Name       '),
        ('nick',    'Nickname/Handle '),
        ('bday',    'Birth Year      '),
        ('bmonth',  'Birth Month (MM)'),
        ('bday2',   'Birth Day (DD)  '),
        ('partner', 'Partner Name    '),
        ('pet',     'Pet Name        '),
        ('company', 'Company / City  '),
        ('hobby',   'Hobby / Interest'),
        ('phone',   'Phone (last 4)  '),
    ]
    data = {}
    for key, label in fields:
        val = input(f"  {C.CYAN}{label}{C.END}: ").strip()
        if val:
            data[key] = val
    return data


# ──────────────────────────────────────────────────────────────
# Output Settings Menu
# ──────────────────────────────────────────────────────────────
def get_output_settings() -> dict:
    print(f"\n{C.BLUE}{'─'*50}")
    print(f"  OUTPUT FILTERS (press Enter for defaults)")
    print(f"{'─'*50}{C.END}")
    
    filename   = input(f"  Output file    [wordlist.txt]: ").strip() or "wordlist.txt"
    min_len    = input(f"  Min length     [6]:            ").strip()
    max_len    = input(f"  Max length     [20]:           ").strip()
    dedup_in   = input(f"  Deduplicate?   [Y/n]:          ").strip().lower()
    upper_in   = input(f"  Require upper? [y/N]:          ").strip().lower()
    digit_in   = input(f"  Require digit? [y/N]:          ").strip().lower()
    special_in = input(f"  Require symbol?[y/N]:          ").strip().lower()

    return {
        'filename':        filename,
        'min_len':         int(min_len)  if min_len.isdigit()  else 6,
        'max_len':         int(max_len)  if max_len.isdigit()  else 20,
        'dedup':           dedup_in != 'n',
        'require_upper':   upper_in == 'y',
        'require_digit':   digit_in == 'y',
        'require_special': special_in == 'y',
    }


# ──────────────────────────────────────────────────────────────
# CLI Argument Parser (non-interactive mode)
# ──────────────────────────────────────────────────────────────
def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog='cracksmith',
        description='CrackSmith v3.0 — Advanced Wordlist Generator',
        formatter_class=argparse.RawTextHelpFormatter
    )
    sub = p.add_subparsers(dest='mode', help='Generation mode')

    # Profile mode
    prof = sub.add_parser('profile', help='Smart profile-based generation')
    prof.add_argument('--first',   help='First name')
    prof.add_argument('--last',    help='Last name')
    prof.add_argument('--nick',    help='Nickname')
    prof.add_argument('--bday',    help='Birth year')
    prof.add_argument('--pet',     help='Pet name')
    prof.add_argument('--company', help='Company or city')
    prof.add_argument('--no-leet', action='store_true', help='Skip leet transforms')
    prof.add_argument('--combos',  type=int, default=2, help='Combo depth (2=pairs, 3=triplets)')

    # Mask mode
    mask = sub.add_parser('mask', help='Hashcat-style mask (e.g. ?l?l?l?d?d)')
    mask.add_argument('mask', help='Mask string')

    # Numeric mode
    num = sub.add_parser('numeric', help='Numeric range')
    num.add_argument('start', type=int)
    num.add_argument('end',   type=int)
    num.add_argument('--pad', type=int, default=0, help='Zero-pad to N digits')

    # Mutate mode
    mut = sub.add_parser('mutate', help='Mutate an existing wordlist')
    mut.add_argument('input', help='Input wordlist path')
    mut.add_argument('--rules', nargs='+',
                     choices=['leet', 'case', 'suffix', 'prefix', 'reverse', 'duplicate'],
                     default=['leet', 'case', 'suffix'],
                     help='Mutation rules to apply')

    # Pattern mode
    pat = sub.add_parser('pattern', help='Pattern families (dates, pins, keyboard)')
    pat.add_argument('type', choices=['dates', 'pins', 'keyboard_walks'],
                     help='Pattern family')
    pat.add_argument('--start', type=int, default=1970, help='Start year (dates only)')
    pat.add_argument('--end',   type=int, default=2026, help='End year (dates only)')
    pat.add_argument('--length',type=int, default=4,    help='PIN length')

    # Shared output flags for all modes
    for sp in [prof, mask, num, mut, pat]:
        sp.add_argument('-o', '--output',  default='wordlist.txt', help='Output filename')
        sp.add_argument('--min-len',       type=int, default=0,    help='Minimum password length')
        sp.add_argument('--max-len',       type=int, default=9999, help='Maximum password length')
        sp.add_argument('--no-dedup',      action='store_true',    help='Skip deduplication')
        sp.add_argument('--require-upper', action='store_true',    help='Require uppercase char')
        sp.add_argument('--require-digit', action='store_true',    help='Require digit')
        sp.add_argument('--require-special',action='store_true',   help='Require special char')

    return p


# ──────────────────────────────────────────────────────────────
# Interactive Menu
# ──────────────────────────────────────────────────────────────
def interactive_menu():
    banner()
    print(f"  {C.BOLD}GENERATION MODES{C.END}\n")
    print(f"  {C.GREEN}1{C.END}. Profile Generator  — Combine personal info into smart wordlists")
    print(f"  {C.GREEN}2{C.END}. Mask Attack        — Hashcat-style (e.g. pass?d?d?d?s)")
    print(f"  {C.GREEN}3{C.END}. Numeric Range      — 000000 → 999999 with padding")
    print(f"  {C.GREEN}4{C.END}. Mutate Wordlist    — Apply rules to an existing list")
    print(f"  {C.GREEN}5{C.END}. Pattern Generator  — Dates, PINs, keyboard walks")
    print(f"  {C.RED}6{C.END}. Exit\n")

    choice = input(f"  {C.BOLD}Select mode [1-6] >{C.END} ").strip()
    settings = get_output_settings()

    gen = None

    if choice == '1':
        data = interactive_profile()
        leet_on = input(f"\n  Enable leet transforms? [Y/n]: ").strip().lower() != 'n'
        depth   = input(f"  Combo depth [2=pairs / 3=triplets]: ").strip()
        depth   = int(depth) if depth in ('2', '3') else 2
        gen = profile_generator(data, leet=leet_on, combos=depth)

    elif choice == '2':
        print(f"\n  {C.CYAN}Mask keys: ?l lower | ?u upper | ?d digit | ?s symbol | ?a all | ?h hex{C.END}")
        mask = input("  Mask > ").strip()
        gen = mask_generator(mask)

    elif choice == '3':
        start = int(input("  Start: ").strip())
        end   = int(input("  End:   ").strip())
        pad   = int(input("  Pad digits (0 = no pad): ").strip() or 0)
        gen = numeric_range_generator(start, end, pad)

    elif choice == '4':
        fp = input("  Input wordlist path: ").strip()
        print(f"  Rules: leet, case, suffix, prefix, reverse, duplicate")
        rules_raw = input("  Rules (space-separated, Enter for defaults): ").strip()
        rules = rules_raw.split() if rules_raw else ['leet', 'case', 'suffix']
        gen = mutate_wordlist(fp, rules=rules)

    elif choice == '5':
        print(f"  Patterns: dates | pins | keyboard_walks")
        ptype = input("  Type: ").strip()
        if ptype == 'dates':
            sy = int(input("  Start year [1970]: ").strip() or 1970)
            ey = int(input("  End year [2026]: ").strip() or 2026)
            gen = pattern_generator('dates', start=sy, end=ey)
        elif ptype == 'pins':
            l = int(input("  PIN length [4]: ").strip() or 4)
            gen = pattern_generator('pins', length=l)
        elif ptype == 'keyboard_walks':
            gen = pattern_generator('keyboard_walks')
        else:
            print(f"{C.RED}[!] Unknown pattern type.{C.END}")
            return

    elif choice == '6':
        print(f"\n{C.DIM}  Goodbye.{C.END}\n")
        sys.exit(0)
    else:
        print(f"{C.RED}[!] Invalid choice.{C.END}")
        return

    if gen:
        write_wordlist(
            gen,
            filename=settings['filename'],
            dedup=settings['dedup'],
            min_len=settings['min_len'],
            max_len=settings['max_len'],
            require_upper=settings['require_upper'],
            require_digit=settings['require_digit'],
            require_special=settings['require_special'],
        )


# ──────────────────────────────────────────────────────────────
# CLI Entry Point
# ──────────────────────────────────────────────────────────────
def cli_entry(args):
    """Non-interactive CLI mode."""
    banner()
    gen = None
    settings = {
        'filename':        args.output,
        'min_len':         args.min_len,
        'max_len':         args.max_len,
        'dedup':           not args.no_dedup,
        'require_upper':   args.require_upper,
        'require_digit':   args.require_digit,
        'require_special': args.require_special,
    }

    if args.mode == 'profile':
        data = {k: v for k, v in vars(args).items()
                if k in ('first','last','nick','bday','pet','company') and v}
        gen = profile_generator(data, leet=not args.no_leet, combos=args.combos)

    elif args.mode == 'mask':
        gen = mask_generator(args.mask)

    elif args.mode == 'numeric':
        gen = numeric_range_generator(args.start, args.end, args.pad)

    elif args.mode == 'mutate':
        gen = mutate_wordlist(args.input, rules=args.rules)

    elif args.mode == 'pattern':
        gen = pattern_generator(args.type, start=args.start, end=args.end, length=args.length)

    if gen:
        write_wordlist(gen, **settings)


# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────
def main():
    signal.signal(signal.SIGINT, lambda *_: (print(f"\n{C.RED}[!] Aborted.{C.END}"), sys.exit(0)))

    parser = build_arg_parser()

    # If args passed → CLI mode; else → interactive
    if len(sys.argv) > 1:
        args = parser.parse_args()
        if args.mode:
            cli_entry(args)
        else:
            parser.print_help()
    else:
        interactive_menu()


if __name__ == "__main__":
    main()
