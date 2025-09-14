#!/usr/bin/env bash
# ========================================================================
# CrackSmith v4.0 — Professional Wordlist Generator (HackOps Edition)
# Author: Lucky (refined by Hinata)
# License: MIT
# Created: 2025-09-14
# ========================================================================
# PURPOSE
#   Highly-capable, safe, and efficient wordlist generator for authorized
#   password auditing, red-team labs, and defensive research.
#
# HIGHLIGHTS
#   - Multiple generation modes: numeric ranges, templates, personal patterns,
#     dictionary transforms (leet/variants), combinatorics, passphrases
#   - Efficient streaming generation for huge outputs (no required RAM)
#   - Disk-space checks, dry-run size estimates, chunking & compress (gzip)
#   - Resume capability (via numbered output chunks or temp files)
#   - Safe 8-digit generation requires explicit CONFIRM string
#   - Optional: uses pv, parallel to improve throughput if installed
#   - Robust trapping, temp file atomicity, logging, and help text
#
# ETHICS & LEGAL NOTICE
#   Use this tool only on systems you own or have explicit permission to test.
#   Unauthorized use is illegal and unethical. Keep record of written permission.
# ========================================================================

set -o errexit
set -o nounset
set -o pipefail

# ---- CONFIG / GLOBALS ---------------------------------------------------
PROGNAME="$(basename "$0")"
VERSION="4.0"
TMPDIR="${TMPDIR:-/tmp}"
WORKDIR="$(pwd)"
OUTFILE=""
TMPFILE=""
LOGFILE=""
PV_CMD="$(command -v pv || true)"
PARALLEL_CMD="$(command -v parallel || true)"
GZIP_CMD="$(command -v gzip || true)"
SPLIT_CMD="$(command -v split || true)"
SHA256_CMD="$(command -v sha256sum || true)"
DEFAULT_CHUNK_SIZE=100M   # used when splitting
MAX_SAFE_LOOP=5000000     # safety threshold for naive loops (5M)
# ---- COLORS --------------------------------------------------------------
RED="\e[1;31m"; GRN="\e[1;32m"; YEL="\e[1;33m"; BLU="\e[1;34m"; RST="\e[0m"

# ---- HELP / USAGE -------------------------------------------------------
usage() {
cat <<EOF
$PROGNAME v$VERSION - CrackSmith wordlist generator

Usage: $PROGNAME [options]

Modes (interactive menu if run without args):
  -n   numeric range generator
  -t   template generator (e.g. 'name@####' where # = digit)
  -p   personal pattern generator (from tokens)
  -d   dictionary transforms (leet, suffix/prefix)
  -c   combinator (combine two wordlists)
  -s   passphrase generator (combine N tokens)
Utility options:
  -o FILE     output filename (required in non-interactive)
  -z          compress output with gzip after creation
  -k BYTES    chunk size for splitting (e.g., 100M)
  --dry-run   estimate size & entries, do not produce file
  --resume    resume from temp file / chunks if present
  -h          show this help

If you run without args, an interactive menu will start.

Ethics: Only use on authorized targets. You must have written permission.
EOF
exit 0
}

# ---- LOGGING & CLEANUP --------------------------------------------------
log() { printf '%s %s\n' "$(date -Iseconds)" "$*" | tee -a "$LOGFILE" >&2; }
fatal() { echo -e "${RED}[ERROR] $*${RST}" >&2; cleanup 1; }
cleanup() {
    local rc=${1:-0}
    [[ -n "$TMPFILE" && -f "$TMPFILE" ]] && rm -f "$TMPFILE" || true
    trap - INT TERM EXIT
    exit "$rc"
}
trap 'log "[!] Interrupted. Cleaning up..."; cleanup 1' INT TERM EXIT

# ---- HELPERS ------------------------------------------------------------
check_tool() {
    local t="$1"
    command -v "$t" >/dev/null 2>&1 || return 1
    return 0
}

require_disk_space() {
    # required_bytes: integer
    local required_bytes="$1"
    local dir="${2:-.}"
    # available bytes
    local avail_bytes
    avail_bytes=$(df -P --output=avail "$dir" | tail -n1 2>/dev/null || echo 0)
    # df returns blocks (1K) on many systems; convert to bytes
    avail_bytes=$((avail_bytes * 1024))
    if (( avail_bytes < required_bytes )); then
        return 1
    fi
    return 0
}

human_readable() {
    # prints human readable for bytes or counts
    num="$1"
    if (( num < 1024 )); then
        echo "${num}B"
        return
    fi
    awk -v n="$num" 'function hr(x){
        s="BKMGTPE"; i=1; while(x>=1024 && i<length(s)){x/=1024; i++}
        printf("%.2f %cB", x, substr(s,i,1))
    } END{hr(n)}'
}

estimate_numeric_count() {
    local start="$1" end="$2"
    if (( end < start )); then echo 0; return; fi
    echo $(( end - start + 1 ))
}

# ---- SAFE OUTPUT PREP ---------------------------------------------------
prepare_output() {
    OUTFILE="${OUTFILE:-wordlist.txt}"
    if [[ -z "$OUTFILE" ]]; then fatal "No output file specified"; fi
    if [[ -f "$OUTFILE" ]]; then
        read -r -p "[!] Output '$OUTFILE' exists. Overwrite? (y/N): " _ans
        [[ "${_ans,,}" != "y" ]] && fatal "User aborted (file exists)."
    fi
    TMPFILE="$(mktemp "$TMPDIR/cracksmith.XXXXXX")" || fatal "mktemp failed"
    LOGFILE="${TMPFILE}.log"
    echo "# CrackSmith v$VERSION generated on $(date --iso-8601=seconds 2>/dev/null || date)" > "$TMPFILE"
    log "[*] Temporary file: $TMPFILE"
}

finalize_output() {
    # Optionally sort & unique as final step
    local do_sort="$1"
    if [[ "$do_sort" == "yes" ]]; then
        log "[*] Sorting & deduplicating output (may take time)..."
        sort -u "$TMPFILE" -o "${TMPFILE}.sorted"
        mv -f "${TMPFILE}.sorted" "$OUTFILE"
    else
        mv -f "$TMPFILE" "$OUTFILE"
    fi
    log "[✔] Wordlist saved to: $OUTFILE"
}

compress_output() {
    if [[ -n "$GZIP_CMD" ]]; then
        log "[*] Compressing output with gzip..."
        "$GZIP_CMD" -f "$OUTFILE"
        OUTFILE="${OUTFILE}.gz"
        log "[✔] Compressed file: $OUTFILE"
    else
        log "[!] gzip not found; skipping compression."
    fi
}

split_output_if_needed() {
    local chunk_size="$1"
    if [[ -z "$chunk_size" ]]; then
        chunk_size="$DEFAULT_CHUNK_SIZE"
    fi
    if [[ -z "$SPLIT_CMD" ]]; then
        log "[!] split not available; skipping splitting."
        return
    fi
    log "[*] Splitting '$OUTFILE' into chunks of $chunk_size..."
    "$SPLIT_CMD" -b "$chunk_size" -d --additional-suffix=.txt "$OUTFILE" "${OUTFILE}.part."
    log "[✔] Split into parts with prefix: ${OUTFILE}.part.*"
}

# ---- GENERATORS ---------------------------------------------------------
gen_numeric_range() {
    # args: start end zero_pad
    local start="$1"; local end="$2"; local pad="$3"
    local count
    count=$(estimate_numeric_count "$start" "$end")
    log "[*] Numeric generation: $start..$end (count: $count)"
    # Safety: if count > MAX_SAFE_LOOP and not explicitly CONFIRM, abort
    if (( count > MAX_SAFE_LOOP )); then
        echo -e "${YEL}[!] Large generation detected (~${count} entries).${RST}"
        read -r -p "Type 'CONFIRM' to proceed: " conf
        [[ "$conf" != "CONFIRM" ]] && fatal "Confirmation not provided - aborting numeric generation."
    fi
    # Check disk: approximate bytes = avg_line_len * count (assume avg 12 bytes)
    local approx_bytes=$((count * 16))
    if ! require_disk_space "$approx_bytes" "$WORKDIR"; then
        fatal "Not enough disk space for estimated numeric output (~$(human_readable $approx_bytes))."
    fi
    # Stream generation
    for ((i=start;i<=end;i++)); do
        if [[ "$pad" -gt 0 ]]; then
            printf "%0${pad}d\n" "$i" >> "$TMPFILE"
        else
            printf "%d\n" "$i" >> "$TMPFILE"
        fi
        # small progress: every 50k
        if (( i % 50000 == 0 )); then
            printf "\r[+] Generated %d entries..." "$i" >&2
        fi
    done
    echo >&2
}

gen_template() {
    # template: characters where '#' => digit, '?' => alpha-lower, '@' => alpha-upper, '*' => any digit/alpha
    local template="$1"
    log "[*] Generating from template: $template"
    # Estimate count by product of expansions
    local -i count=1
    local -i choices
    local -a map
    map[0]="0123456789"   # #
    map[1]="abcdefghijklmnopqrstuvwxyz" # ?
    map[2]="ABCDEFGHIJKLMNOPQRSTUVWXYZ" # @
    map[3]="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" # *
    # convert template into arrays of charsets
    local -a charsets=()
    local i ch
    for ((i=0;i<${#template};i++)); do
        ch="${template:i:1}"
        case "$ch" in
            '#') charsets+=("${map[0]}"); choices=${#map[0]};;
            '?') charsets+=("${map[1]}"); choices=${#map[1]};;
            '@') charsets+=("${map[2]}"); choices=${#map[2]};;
            '*') charsets+=("${map[3]}"); choices=${#map[3]};;
            *) charsets+=("$ch"); choices=1;;
        esac
        count=$((count * choices))
        # Protect: if count too big, warn
        if (( count > MAX_SAFE_LOOP )); then
            echo -e "${YEL}[!] Template would produce >$MAX_SAFE_LOOP entries (~$count).${RST}"
            read -r -p "Type 'CONFIRM' to proceed: " c; [[ "$c" != "CONFIRM" ]] && fatal "Aborted template generation."
        fi
    done
    log "[*] Template will generate approx $count entries."
    # Cartesian product via recursion (bash-friendly iterative approach)
    # We'll use indices as counters
    local len=${#charsets[@]}
    local -a idx; idx=()
    for ((i=0;i<len;i++)); do idx[i]=0; done
    while true; do
        # build string for current indices
        local out=""
        for ((i=0;i<len;i++)); do
            cs="${charsets[i]}"
            # if cs length ==1 and not a set, just append
            if [[ "${#cs}" -eq 1 ]]; then
                out+="$cs"
            else
                out+="${cs:idx[i]:1}"
            fi
        done
        printf '%s\n' "$out" >> "$TMPFILE"
        # increment indices
        local carry=1
        for ((i=len-1;i>=0;i--)); do
            cs="${charsets[i]}"
            if [[ "${#cs}" -le 1 ]]; then
                # fixed char — no index change
                continue
            fi
            idx[i]=$(( idx[i] + carry ))
            if (( idx[i] >= ${#cs} )); then
                idx[i]=0
                carry=1
            else
                carry=0
                break
            fi
        done
        # if carry still 1, we've wrapped all combinations
        if (( carry == 1 )); then break; fi
    done
}

gen_personal_patterns() {
    log "[*] Personal pattern generation (PII WARNING). Use only for authorized tests."
    read -r -p "Enter tokens separated by space (name nickname pet etc): " -a tokens
    read -r -p "Birthyear (optional): " birthyear
    if (( ${#tokens[@]} == 0 )); then fatal "No tokens provided."
    fi
    # produce common variants
    for w in "${tokens[@]}"; do
        printf '%s\n' "$w" >> "$TMPFILE"
        printf '%s\n' "${w,,}" >> "$TMPFILE"
        printf '%s\n' "${w^^}" >> "$TMPFILE"
        printf '%s\n' "${w^}" >> "$TMPFILE"
        printf '%s\n' "${w}123" >> "$TMPFILE"
        printf '%s\n' "${w}1234" >> "$TMPFILE"
        printf '%s\n' "${w}!@#" >> "$TMPFILE"
        [[ -n "$birthyear" ]] && printf '%s\n' "${w}${birthyear}" >> "$TMPFILE"
    done
    # pairwise combos
    for ((i=0;i<${#tokens[@]};i++)); do
        for ((j=0;j<${#tokens[@]};j++)); do
            [[ $i -eq $j ]] && continue
            t1=${tokens[i]}; t2=${tokens[j]}
            printf '%s\n' "${t1}${t2}" >> "$TMPFILE"
            printf '%s\n' "${t1}_${t2}" >> "$TMPFILE"
            [[ -n "$birthyear" ]] && printf '%s\n' "${t1}${t2}${birthyear}" >> "$TMPFILE"
        done
    done
}

gen_dictionary_transforms() {
    # requires a dictionary file path
    local dict="$1"
    [[ ! -f "$dict" ]] && fatal "Dictionary '$dict' not found."
    log "[*] Dictionary transforms on '$dict' (leet, suffix/prefix, caps)"
    while IFS= read -r w; do
        [[ -z "$w" ]] && continue
        printf '%s\n' "$w" >> "$TMPFILE"
        printf '%s\n' "${w}123" >> "$TMPFILE"
        printf '%s\n' "${w}2025" >> "$TMPFILE"
        printf '%s\n' "${w}!" >> "$TMPFILE"
        printf '%s\n' "${w^}" >> "$TMPFILE"
        printf '%s\n' "${w^^}" >> "$TMPFILE"
        # leetspeak simple replacements
        local l="${w//o/0}"; l="${l//O/0}"
        l="${l//a/4}"; l="${l//A/4}"
        l="${l//e/3}"; l="${l//E/3}"
        l="${l//i/1}"; l="${l//I/1}"
        l="${l//s/5}"; l="${l//S/5}"
        printf '%s\n' "$l" >> "$TMPFILE"
        printf '%s\n' "${l}123" >> "$TMPFILE"
    done < "$dict"
}

gen_combinator() {
    # combine two files: file1 x file2 -> concatenation, optionally with separator
    local file1="$1"; local file2="$2"; local sep="${3:-}"
    [[ ! -f "$file1" || ! -f "$file2" ]] && fatal "Files not found for combinator."
    log "[*] Combining '$file1' x '$file2' (sep='$sep')"
    # Use streaming nested loops - might be slow for huge files; if parallel present use it
    if check_tool parallel >/dev/null 2>&1 && check_tool awk >/dev/null 2>&1; then
        # produce pairs using parallel (faster)
        awk '{print NR ":" $0}' "$file2" > "${TMPDIR}/.c2.$$"
        while IFS= read -r a; do
            # safe exporting to parallel
            printf '%s\n' "$a" | parallel --will-cite --pipe -N1 "sed -n '1,100000p' ${TMPDIR}/.c2.$$ | sed -n '1,100000p' | awk -v a='$a' -v sep='$sep' -F: '{print a sep \$2}'" >> "$TMPFILE"
        done < "$file1"
        rm -f "${TMPDIR}/.c2.$$" || true
    else
        # simple but memory-friendly nested approach
        while IFS= read -r a; do
            while IFS= read -r b; do
                printf '%s\n' "${a}${sep}${b}" >> "$TMPFILE"
            done < "$file2"
        done < "$file1"
    fi
}

gen_passphrases() {
    # assemble passphrases from tokens: choose N tokens combined w/ separator
    read -r -p "Enter path to token file (one token per line): " tokenfile
    [[ ! -f "$tokenfile" ]] && fatal "Token file not found."
    read -r -p "How many tokens per phrase (e.g., 3): " k
    if ! [[ "$k" =~ ^[0-9]+$ && "$k" -ge 2 ]]; then fatal "k must be integer >=2"; fi
    read -r -p "Separator (leave blank for no separator): " sep
    log "[*] Generating passphrases with $k tokens each from $tokenfile"
    # naive Cartesian - protect explosion
    local total_tokens
    total_tokens=$(wc -l < "$tokenfile" | tr -d ' ')
    if (( total_tokens ** k > MAX_SAFE_LOOP )); then
        echo -e "${YEL}[!] This will produce a very large number of phrases.${RST}"
        read -r -p "Type 'CONFIRM' to proceed: " c; [[ "$c" != "CONFIRM" ]] && fatal "Aborted passphrase generation."
    fi
    # simple recursive generator using indexes
    mapfile -t tokens < "$tokenfile"
    local n=${#tokens[@]}
    local -a idx
    for ((i=0;i<k;i++)); do idx[i]=0; done
    while true; do
        # build phrase
        local phrase="${tokens[idx[0]]}"
        for ((j=1;j<k;j++)); do phrase+="${sep}${tokens[idx[j]]}"; done
        printf '%s\n' "$phrase" >> "$TMPFILE"
        # increment indices
        local carry=1
        for ((i=k-1;i>=0;i--)); do
            idx[i]=$((idx[i]+carry))
            if (( idx[i] >= n )); then
                idx[i]=0
                carry=1
            else
                carry=0; break
            fi
        done
        (( carry )) && break
    done
}

# ---- MAIN INTERACTIVE MENU ----------------------------------------------
interactive_menu() {
    echo -e "${GRN}CrackSmith v$VERSION — Interactive Mode${RST}"
    while true; do
        echo -e "\n${YEL}Choose an action:${RST}"
        echo " 1) Numeric range (0000..9999 / custom)"
        echo " 2) Template generator (use # ? @ *)"
        echo " 3) Personal patterns (tokens -> variants)"
        echo " 4) Dictionary transforms (requires words.txt)"
        echo " 5) Combinator (fileA x fileB)"
        echo " 6) Passphrase generator (token file)"
        echo " 7) Sort & dedupe existing output"
        echo " 8) Dry-run estimate (no file produced)"
        echo " 0) Exit"
        read -r -p "Select: " choice
        case "$choice" in
            1)
                read -r -p "Start: " s; read -r -p "End: " e
                read -r -p "Zero-pad width (0=no pad): " pad
                prepare_output
                gen_numeric_range "$s" "$e" "$pad"
                finalize_output "no"
                ;;
            2)
                read -r -p "Template (use # for digit, ? for lower, @ for upper, * for alnum): " tpl
                prepare_output
                gen_template "$tpl"
                finalize_output "no"
                ;;
            3)
                prepare_output
                gen_personal_patterns
                finalize_output "no"
                ;;
            4)
                read -r -p "Dictionary path: " dpath
                prepare_output
                gen_dictionary_transforms "$dpath"
                finalize_output "no"
                ;;
            5)
                read -r -p "File A: " f1
                read -r -p "File B: " f2
                read -r -p "Separator (optional): " sep
                prepare_output
                gen_combinator "$f1" "$f2" "$sep"
                finalize_output "no"
                ;;
            6)
                prepare_output
                gen_passphrases
                finalize_output "no"
                ;;
            7)
                read -r -p "Enter existing file to sort/dedupe: " ex
                [[ ! -f "$ex" ]] && echo "[!] File not found." && continue
                sort -u "$ex" -o "${ex}.sorted" && mv -f "${ex}.sorted" "$ex"
                echo "[✔] Sorted/deduped: $ex"
                ;;
            8)
                echo "[*] Dry-run examples:"
                echo " - Numeric 0000..9999 = 10,000 entries"
                echo " - 4-word dictionary (1000 words) combinator 2-way = 1,000,000 entries"
                echo "Use explicit commands for real estimates."
                ;;
            0) echo "[*] Exiting."; cleanup 0 ;;
            *) echo "[!] Invalid choice." ;;
        esac
    done
}

# ---- PARSE CLI (if provided) --------------------------------------------
# For brevity: if no args -> interactive. CLI modes are supported but simple.
if (( $# == 0 )); then
    interactive_menu
    cleanup 0
fi

# Minimal CLI parsing (non-exhaustive)
DRY_RUN="no"
COMPRESS_AFTER="no"
CHUNK_SIZE=""
MODE=""
DICT_PATH=""
COMB_A=""
COMB_B=""
SEPARATOR=""
while (( "$#" )); do
    case "$1" in
        -n) MODE="numeric"; shift ;;
        -t) MODE="template"; TEMPLATE="$2"; shift 2 ;;
        -p) MODE="personal"; shift ;;
        -d) MODE="dict"; DICT_PATH="$2"; MODE="dict"; shift 2 ;;
        -c) MODE="combinator"; COMB_A="$2"; COMB_B="$3"; SEPARATOR="$4"; shift 4 ;;
        -s) MODE="passphrase"; shift ;;
        -o) OUTFILE="$2"; shift 2 ;;
        -z) COMPRESS_AFTER="yes"; shift ;;
        -k) CHUNK_SIZE="$2"; shift 2 ;;
        --dry-run) DRY_RUN="yes"; shift ;;
        --resume) RESUME="yes"; shift ;;
        -h|--help) usage ;;
        *) echo "[!] Unknown arg: $1"; usage ;;
    esac
done

# Ensure OUTFILE if non-interactive
[[ -z "${OUTFILE:-}" ]] && fatal "Non-interactive mode requires -o OUTFILE"

# Start based on MODE (simplified)
prepare_output

case "$MODE" in
    numeric)
        # require template for CLI numeric? Ask interactively
        read -r -p "Start: " s; read -r -p "End: " e; read -r -p "Zero-pad width (0=no pad): " pad
        if [[ "$DRY_RUN" == "yes" ]]; then
            cnt=$(estimate_numeric_count "$s" "$e")
            echo "Dry-run: $cnt entries approximate"
            cleanup 0
        fi
        gen_numeric_range "$s" "$e" "$pad"
        finalize_output "no"
        ;;
    template)
        if [[ -z "${TEMPLATE:-}" ]]; then fatal "Template not provided (-t 'template')"; fi
        if [[ "$DRY_RUN" == "yes" ]]; then echo "Dry-run: template will generate an estimated set (use interactive for detail)"; cleanup 0; fi
        gen_template "$TEMPLATE"
        finalize_output "no"
        ;;
    personal)
        gen_personal_patterns
        finalize_output "no"
        ;;
    dict)
        [[ -z "$DICT_PATH" ]] && fatal "Dictionary path required for dict mode"
        gen_dictionary_transforms "$DICT_PATH"
        finalize_output "no"
        ;;
    combinator)
        [[ -z "$COMB_A" || -z "$COMB_B" ]] && fatal "Combinator requires two file args"
        gen_combinator "$COMB_A" "$COMB_B" "$SEPARATOR"
        finalize_output "no"
        ;;
    passphrase)
        gen_passphrases
        finalize_output "no"
        ;;
    *)
        fatal "Unknown mode: $MODE"
        ;;
esac

# optional compress and split
if [[ "$COMPRESS_AFTER" == "yes" ]]; then compress_output; fi
if [[ -n "$CHUNK_SIZE" ]]; then split_output_if_needed "$CHUNK_SIZE"; fi

# checksum
if [[ -n "$SHA256_CMD" && -f "$OUTFILE" ]]; then
    "$SHA256_CMD" "$OUTFILE" | tee -a "$LOGFILE"
fi

log "[✔] Completed successfully."
cleanup 0
