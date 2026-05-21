# CrackSmith v3.0 — Advanced Wordlist Generator

```
 ██████╗██████╗  █████╗  ██████╗██╗  ██╗███████╗███╗   ███╗██╗████████╗██╗  ██╗
██╔════╝██╔══██╗██╔══██╗██╔════╝██║ ██╔╝██╔════╝████╗ ████║██║╚══██╔══╝██║  ██║
██║     ██████╔╝███████║██║     █████╔╝ ███████╗██╔████╔██║██║   ██║   ███████║
██║     ██╔══██╗██╔══██║██║     ██╔═██╗ ╚════██║██║╚██╔╝██║██║   ██║   ██╔══██║
╚██████╗██║  ██║██║  ██║╚██████╗██║  ██╗███████║██║ ╚═╝ ██║██║   ██║   ██║  ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝
```

> **⚠ LEGAL NOTICE:** CrackSmith is developed for **authorized penetration testing, CTF competitions, and security education only.** Using this tool against systems you do not own or have explicit written permission to test is **illegal** under the Computer Fraud and Abuse Act (CFAA), the UK Computer Misuse Act, and equivalent laws worldwide. The authors assume no liability for misuse.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Modes](#modes)
  - [1. Profile Generator](#1-profile-generator)
  - [2. Mask Attack](#2-mask-attack)
  - [3. Numeric Range](#3-numeric-range)
  - [4. Mutate Wordlist](#4-mutate-wordlist)
  - [5. Pattern Generator](#5-pattern-generator)
- [Output Filters](#output-filters)
- [CLI Reference](#cli-reference)
- [Mask Charset Reference](#mask-charset-reference)
- [Pipeline Architecture](#pipeline-architecture)
- [Performance](#performance)
- [Comparison with Similar Tools](#comparison-with-similar-tools)
- [Examples & Use Cases](#examples--use-cases)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

CrackSmith is a high-performance, Python-based wordlist generator designed for security professionals conducting authorized password auditing and penetration testing. It generates targeted, intelligent wordlists by combining personal profile data, hashcat-style masks, mutation rules, and pattern families — all filtered through a configurable output pipeline.

Unlike generic tools that dump massive unfiltered lists, CrackSmith focuses on **quality over quantity**: smarter combinations, real leet-speak permutations, and a composable filter system that outputs wordlists tuned to your target's password policy.

---

## Features

| Feature | Description |
|---|---|
| **Profile Generator** | Combines personal info (name, DOB, pet, company) into smart targeted wordlists |
| **Full Leet Engine** | Cartesian permutation of all leet substitutions, not just a single pass |
| **Hashcat-style Masks** | Supports `?l ?u ?d ?s ?a ?h ?H` with literal characters |
| **Wordlist Mutator** | Apply rules (leet, case, suffix, prefix, reverse, duplicate) to any existing list |
| **Pattern Generator** | Date formats, PINs of any length, keyboard walk sequences |
| **Numeric Range** | Zero-padded numeric sequences |
| **Filter Pipeline** | Length, complexity (uppercase/digit/symbol), and deduplication filters |
| **Dual Interface** | Interactive menu + full CLI for scripting and automation |
| **Real-time Progress** | Live progress bar with lines/sec speed and file size reporting |
| **Graceful Interrupt** | `Ctrl+C` saves partial output cleanly |

---

## Requirements

- Python **3.7+**
- No external dependencies — standard library only

```bash
python3 --version  # Must be 3.7 or higher
```

---

## Installation

```bash
# Clone the repository
git clone https://github.com/hackops-academy/cracksmith.git
cd cracksmith

# Make executable (Linux/macOS)
chmod +x CrackSmith.py

# Optional: add to PATH
sudo ln -s $(pwd)/CrackSmith.py /usr/local/bin/cracksmith
```

---

## Quick Start

**Interactive mode** (recommended for beginners):
```bash
python3 CrackSmith.py
```

**CLI mode** (recommended for scripting):
```bash
python3 CrackSmith.py profile --first john --last doe --bday 1990 -o output.txt
```

---

## Modes

### 1. Profile Generator

Generates a targeted wordlist from personal information about the target. The most powerful mode for real-world password auditing because it mirrors how humans actually create passwords.

**How it works:**
1. Each input word is expanded through all casing variants (lower, upper, capitalize, title, swapcase)
2. Each cased variant is passed through the full leet-speak engine (cartesian permutation)
3. All expanded tokens receive prefixes and suffixes from common pattern lists
4. Tokens are combined in pairs (and optionally triplets) across all separators

**Interactive:**
```
python3 CrackSmith.py

> Select mode: 1
> First Name:       john
> Last Name:        smith
> Nickname/Handle:  johnny
> Birth Year:       1990
> Birth Month (MM): 06
> Birth Day (DD):   15
> Partner Name:     sarah
> Pet Name:         max
> Company / City:   google
> Hobby / Interest: gaming
> Phone (last 4):   4521
```

**CLI:**
```bash
python3 CrackSmith.py profile \
  --first john \
  --last smith \
  --nick johnny \
  --bday 1990 \
  --pet max \
  --company google \
  --combos 2 \
  -o john_smith.txt
```

**Sample output:**
```
john
John
JOHN
j0hn
j0hn123
john1990
john_smith
John.Smith
j0hn_$m1th!
johnny2025
John$mith!
```

**Options:**

| Flag | Default | Description |
|---|---|---|
| `--no-leet` | off | Skip leet-speak transformations |
| `--combos` | `2` | Combination depth: `2` = pairs, `3` = triplets |

> **Tip:** Use `--combos 3` only when the base word pool is small (< 10 tokens). Triplets on large pools generate enormous files.

---

### 2. Mask Attack

Generates every combination defined by a hashcat-style mask. Ideal when you know the password structure (e.g., from a leaked policy document or breach analysis).

**Interactive:**
```
python3 CrackSmith.py

> Select mode: 2
> Mask: Pass?d?d?d?s
```

**CLI:**
```bash
python3 CrackSmith.py mask 'Pass?d?d?d?s' -o mask_out.txt
```

**Sample output for `?u?l?l?l?d?d`:**
```
Aaaa00
Aaaa01
Aaaa02
...
Zzzz99
```

The tool prints the total combination space before generating so you can estimate file size and abort if needed.

```
[i] Mask space: 11,881,376 combinations
```

See the full [Mask Charset Reference](#mask-charset-reference) below.

---

### 3. Numeric Range

Generates a sequential number range with optional zero-padding. Useful for PIN lists, account IDs, and numeric suffix attacks.

**Interactive:**
```
python3 CrackSmith.py

> Select mode: 3
> Start:       0
> End:         999999
> Pad digits:  6
```

**CLI:**
```bash
python3 CrackSmith.py numeric 0 999999 --pad 6 -o pins_6digit.txt
```

**Output:**
```
000000
000001
000002
...
999999
```

---

### 4. Mutate Wordlist

Takes an existing wordlist (e.g., `rockyou.txt`, a company-specific list, or a CeWL-scraped list) and applies transformation rules to each word. This is the fastest way to enrich an existing wordlist without regenerating from scratch.

**Available rules:**

| Rule | Effect | Example input → outputs |
|---|---|---|
| `leet` | Leet-speak permutations | `pass` → `p@ss`, `p4ss`, `p@$s` |
| `case` | All casing variants | `pass` → `Pass`, `PASS`, `pAsS` |
| `suffix` | Common suffixes appended | `pass` → `pass123`, `pass!`, `pass2024` |
| `prefix` | Common prefixes prepended | `pass` → `mypass`, `thepass`, `1pass` |
| `reverse` | Reversed string | `pass` → `ssap` |
| `duplicate` | Word doubled | `pass` → `passpass` |

**Interactive:**
```
python3 CrackSmith.py

> Select mode: 4
> Input wordlist path: /usr/share/wordlists/rockyou.txt
> Rules: leet case suffix
```

**CLI:**
```bash
python3 CrackSmith.py mutate /usr/share/wordlists/rockyou.txt \
  --rules leet case suffix reverse \
  -o rockyou_mutated.txt
```

**Piping with other tools:**
```bash
# Scrape target site → mutate → ready to use
cewl https://example.com -w cewl_out.txt
python3 CrackSmith.py mutate cewl_out.txt --rules leet case suffix -o final.txt
```

---

### 5. Pattern Generator

Generates structured pattern families that cover common password archetypes.

#### Dates

Generates all date combinations between two years in multiple formats:

| Format | Example |
|---|---|
| DDMMYYYY | 15061990 |
| DD/MM/YYYY | 15/06/1990 |
| YYYYMMDD | 19900615 |
| MMDDYYYY | 06151990 |

```bash
python3 CrackSmith.py pattern dates --start 1980 --end 2000 -o dates.txt
```

#### PINs

All numeric combinations of a given length. Covers every possible PIN of that digit count.

```bash
python3 CrackSmith.py pattern pins --length 6 -o pins_6.txt
# Generates 1,000,000 entries (000000–999999)
```

#### Keyboard Walks

Common keyboard-walk patterns and their variants (reversed, capitalized, sliced into substrings):

```
qwerty, ytrewq, Qwerty, qwer, asdf, asdfgh, zxcv, 1234, 0987...
```

```bash
python3 CrackSmith.py pattern keyboard_walks -o walks.txt
```

---

## Output Filters

Every mode passes output through a composable filter pipeline before writing to disk. These can be combined freely.

| Filter | Flag | Description |
|---|---|---|
| Min length | `--min-len N` | Drop words shorter than N characters |
| Max length | `--max-len N` | Drop words longer than N characters |
| Require uppercase | `--require-upper` | Only output words containing ≥1 uppercase letter |
| Require digit | `--require-digit` | Only output words containing ≥1 digit |
| Require symbol | `--require-special` | Only output words containing ≥1 symbol |
| Deduplication | on by default | Remove duplicate entries; use `--no-dedup` to skip |

**Example — generate a list matching a strict 8–16 char policy:**
```bash
python3 CrackSmith.py profile --first alice --last jones \
  --min-len 8 --max-len 16 \
  --require-upper --require-digit \
  -o policy_filtered.txt
```

**Pipeline order:**

```
Generator → Length Filter → Complexity Filter → Deduplicator → File
```

---

## CLI Reference

```
usage: cracksmith <mode> [options]

Modes:
  profile       Smart profile-based generation
  mask          Hashcat-style mask (e.g. ?l?l?l?d?d)
  numeric       Numeric range
  mutate        Mutate an existing wordlist
  pattern       Pattern families (dates, pins, keyboard_walks)

Shared output flags (all modes):
  -o, --output FILE       Output filename (default: wordlist.txt)
  --min-len N             Minimum password length (default: 0)
  --max-len N             Maximum password length (default: 9999)
  --no-dedup              Skip deduplication
  --require-upper         Require at least one uppercase character
  --require-digit         Require at least one digit
  --require-special       Require at least one special character

profile flags:
  --first NAME            First name
  --last NAME             Last name
  --nick NAME             Nickname or handle
  --bday YEAR             Birth year
  --pet NAME              Pet name
  --company NAME          Company or city
  --no-leet               Skip leet-speak transforms
  --combos N              Combination depth: 2=pairs, 3=triplets (default: 2)

mask flags:
  mask MASK               Mask string (e.g. 'pass?d?d?d')

numeric flags:
  start N                 Start number
  end N                   End number
  --pad N                 Zero-pad to N digits (default: 0)

mutate flags:
  input FILE              Path to input wordlist
  --rules RULE [RULE...]  Rules: leet case suffix prefix reverse duplicate

pattern flags:
  type TYPE               Pattern type: dates | pins | keyboard_walks
  --start YEAR            Start year for dates (default: 1970)
  --end YEAR              End year for dates (default: 2026)
  --length N              PIN digit length (default: 4)
```

---

## Mask Charset Reference

| Token | Character Set | Count |
|---|---|---|
| `?l` | `abcdefghijklmnopqrstuvwxyz` | 26 |
| `?u` | `ABCDEFGHIJKLMNOPQRSTUVWXYZ` | 26 |
| `?d` | `0123456789` | 10 |
| `?s` | `!@#$%^&*()-_=+[]{}|;:,.<>?` | 27 |
| `?a` | All printable ASCII | 95 |
| `?h` | `0123456789abcdef` | 16 |
| `?H` | `0123456789ABCDEF` | 16 |

Literal characters are also supported — anything that is not a `?X` token is treated as a literal.

**Examples:**

| Mask | Meaning | Space |
|---|---|---|
| `?d?d?d?d` | 4-digit PIN | 10,000 |
| `?u?l?l?l?d?d` | Capital + 3 lower + 2 digits | 17,576,000 |
| `Pass?d?d?d` | Literal "Pass" + 3 digits | 1,000 |
| `?l?l?l?l?l?l?l?l` | 8 lowercase chars | 208,827,064,576 |
| `?u?l?l?l?l?d?d?s` | Mixed 8-char | ~1.5 billion |

---

## Pipeline Architecture

```
┌──────────────────────────────────────────────────────────┐
│                     INPUT SOURCES                        │
│   Profile Data │ Mask String │ Wordlist File │ Pattern   │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                    EXPANSION ENGINE                      │
│   Casing Variants → Leet Permutations → Token Pool       │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                  COMBINATION ENGINE                      │
│   Singles + Suffixes → Pairs (sep) → Triplets            │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                   FILTER PIPELINE                        │
│   Length Filter → Complexity Filter → Deduplicator       │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                   OUTPUT WRITER                          │
│   Buffered file write with real-time progress bar        │
└──────────────────────────────────────────────────────────┘
```

The entire pipeline is **generator-based** — no data is held in memory beyond what is currently being processed. This allows CrackSmith to generate wordlists of unlimited theoretical size without RAM constraints.

---

## Performance

Tested on a standard laptop (Intel i5, Python 3.11):

| Mode | Output Size | Time | Speed |
|---|---|---|---|
| Numeric range (0–9,999,999) | 80 MB | ~12s | ~800,000 lines/sec |
| Mask `?l?l?l?l?d?d` | 456 MB | ~55s | ~720,000 lines/sec |
| Profile (10 tokens, combos=2) | ~15 MB | ~3s | ~500,000 lines/sec |
| Mutate rockyou.txt (leet+case+suffix) | ~4 GB | ~8 min | ~600,000 lines/sec |

Speed varies by mode. Deduplication adds memory overhead proportional to unique entry count.

---

## Comparison with Similar Tools

| Feature | CrackSmith v3 | Crunch | CeWL | Mentalist |
|---|---|---|---|---|
| Profile-based generation | ✅ | ❌ | ❌ | ✅ |
| Leet permutations | ✅ Full | ❌ | ❌ | Partial |
| Hashcat mask support | ✅ | ✅ | ❌ | ❌ |
| Wordlist mutation | ✅ | ❌ | ❌ | ❌ |
| Date pattern generation | ✅ All formats | ❌ | ❌ | Partial |
| Keyboard walks | ✅ | ❌ | ❌ | ❌ |
| Complexity filters | ✅ | ❌ | ❌ | ❌ |
| Length filters | ✅ | ✅ | ❌ | ✅ |
| CLI scriptable | ✅ | ✅ | ✅ | ❌ |
| Zero dependencies | ✅ | ✅ | ❌ | ❌ |
| Generator-based (low RAM) | ✅ | ✅ | ❌ | ❌ |

---

## Examples & Use Cases

### CTF / Box: Generate targeted list from OSINT
```bash
# Found target info from LinkedIn + social media
python3 CrackSmith.py profile \
  --first michael --last scott \
  --nick mscott --bday 1964 \
  --pet "mr. sprinkles" --company dundermifflin \
  --combos 2 --min-len 8 --max-len 20 \
  -o michael_scott.txt
```

### Audit internal policy compliance (8+ char, upper + digit required)
```bash
python3 CrackSmith.py mutate company_users.txt \
  --rules leet case suffix \
  --min-len 8 --require-upper --require-digit \
  -o compliant_mutations.txt
```

### Generate all 4-digit PINs for a padlock audit
```bash
python3 CrackSmith.py numeric 0 9999 --pad 4 -o pins4.txt
```

### WPA2 handshake — router default password pattern
```bash
# Many routers use pattern: 8 lowercase + 2 digits
python3 CrackSmith.py mask '?l?l?l?l?l?l?l?l?d?d' \
  --min-len 10 --max-len 10 \
  -o router_default.txt
```

### Enrich CeWL output with mutations
```bash
cewl https://target-company.com -d 2 -w cewl_raw.txt
python3 CrackSmith.py mutate cewl_raw.txt \
  --rules leet case suffix prefix reverse \
  -o cewl_enriched.txt
```

### Date-based passwords (common in South Asia / corporate)
```bash
python3 CrackSmith.py pattern dates \
  --start 1975 --end 2005 \
  --min-len 8 \
  -o dates_filtered.txt
```

---

## Contributing

Pull requests are welcome. Please ensure:

1. All new code is type-hinted and uses generators where possible
2. No external dependencies are introduced
3. New modes include both interactive and CLI support
4. The ethics warning is preserved in all forks

---

## License

MIT License — see `LICENSE` for details.

```
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
THE AUTHORS ARE NOT RESPONSIBLE FOR MISUSE OF THIS TOOL.
USE ONLY ON SYSTEMS YOU OWN OR HAVE EXPLICIT WRITTEN PERMISSION TO TEST.
```

---

*Made with ❤ by Hackops Academy | `_hack_ops_`*
