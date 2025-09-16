#!/usr/bin/env bash
# CrackSmith CUpp-like friendly tool
# Author: Hinata (refined for Lucky)
# Version: 1.0
# Works on: Kali / Ubuntu / Termux
# License: MIT
#
# Usage: ./cracksmith_cupp.sh
# Interactive. Designed to be readable, safe, and powerful.

set -o errexit
set -o nounset
set -o pipefail

# Colors
RED="\e[1;31m"; GRN="\e[1;32m"; YEL="\e[1;33m"; BLU="\e[1;34m"; RST="\e[0m"

# Globals
OUTFILE=""
TMPFILE=""
WORKDIR="$(pwd)"
MAX_WARN=5000000   # warn above this many entries
PV="$(command -v pv || true)"
GZIP="$(command -v gzip || true)"

ethics() {
    cat <<EOF

${YEL}ETHICS & LEGAL NOTICE:${RST}
This tool generates password lists. Use it only for:
 - authorized penetration tests,
 - recovering your own passwords,
 - lab exercises you control.

Unauthorized use against systems you do not own is illegal and unethical.
Always keep written permission when testing others.

EOF
}

banner() {
    clear
    echo -e "${GRN}CrackSmith — CUpp-style friendly wordlist generator v1.0${RST}"
    echo "Simple • Safe • Powerful"
    ethics
}

ensure_tmp() {
    TMPFILE="$(mktemp "${WORKDIR}/cracksmith.XXXXXX")" || { echo "mktemp failed"; exit 1; }
    # header
    {
        echo "# CrackSmith CUpp-style wordlist"
        echo "# Generated: $(date --iso-8601=seconds 2>/dev/null || date)"
    } > "$TMPFILE"
}

finalize() {
    sort -u "$TMPFILE" -o "$TMPFILE.sorted"
    mv -f "$TMPFILE.sorted" "$OUTFILE"
    rm -f "$TMPFILE" || true
    echo -e "${GRN}[✔] Final wordlist saved to: $OUTFILE${RST}"
    if [[ -n "$GZIP" ]]; then
        read -r -p "Compress output with gzip? (y/N): " c
        if [[ "${c,,}" == "y" ]]; then
            "$GZIP" -f "$OUTFILE"
            OUTFILE="${OUTFILE}.gz"
            echo -e "${GRN}[✔] Compressed -> $OUTFILE${RST}"
        fi
    fi
}

check_disk_for_estimate() {
    # estimate bytes = entries * avg_len (approx 16)
    local entries="$1"
    local needed=$(( entries * 16 ))
    local avail_kb
    avail_kb=$(df -P . --output=avail | tail -n1 2>/dev/null || echo 0)
    avail_bytes=$(( avail_kb * 1024 ))
    if (( avail_bytes < needed )); then
        echo -e "${RED}[!] Not enough disk space (need approx $(printf '%d' "$needed") bytes). Aborting.${RST}"
        return 1
    fi
    return 0
}

progress_echo() {
    # simple progress counter (call manually if needed)
    local n="$1"
    printf "\r[+] Generated %d entries..." "$n" >&2
}

# --- Generators ----------------------------------------------------------

gen_profile_variants() {
    # Input tokens -> generate lots of human-like variants
    local -a toks=("$@")
    local n=0
    for t in "${toks[@]}"; do
        [[ -z "$t" ]] && continue
        # basic variants
        echo "$t" >> "$TMPFILE"; ((n++))
        echo "${t,,}" >> "$TMPFILE"; ((n++))
        echo "${t^^}" >> "$TMPFILE"; ((n++))
        echo "${t^}" >> "$TMPFILE"; ((n++))
        echo "${t}123" >> "$TMPFILE"; ((n++))
        echo "${t}1234" >> "$TMPFILE"; ((n++))
        echo "${t}2025" >> "$TMPFILE"; ((n++))
        echo "${t}!@#" >> "$TMPFILE"; ((n++))
        echo "${t}007" >> "$TMPFILE"; ((n++))
        echo "${t}_01" >> "$TMPFILE"; ((n++))
        # leet sample
        l="${t//o/0}"; l="${l//a/4}"; l="${l//e/3}"; l="${l//i/1}"; l="${l//s/5}"
        echo "$l" >> "$TMPFILE"; ((n++))
        echo "${l}123" >> "$TMPFILE"; ((n++))
    done
    # combine tokens pairwise
    local len="${#toks[@]}"
    for ((i=0;i<len;i++)); do
        for ((j=0;j<len;j++)); do
            [[ $i -eq $j ]] && continue
            a="${toks[i]}"; b="${toks[j]}"
            [[ -z "$a" || -z "$b" ]] && continue
            echo "${a}${b}" >> "$TMPFILE"; ((n++))
            echo "${a}_${b}" >> "$TMPFILE"; ((n++))
            echo "${a}${b}123" >> "$TMPFILE"; ((n++))
        done
    done
    echo -e "${GRN}[+] Created approx $n profile variants${RST}"
}

gen_dictionary_transforms() {
    local dict="$1"
    if [[ ! -f "$dict" ]]; then
        echo -e "${RED}[!] Dictionary file not found: $dict${RST}"; return 1
    fi
    local count=0
    while IFS= read -r w; do
        [[ -z "$w" ]] && continue
        echo "$w" >> "$TMPFILE"; ((count++))
        echo "${w}123" >> "$TMPFILE"; ((count++))
        echo "${w}2025" >> "$TMPFILE"; ((count++))
        echo "${w^^}" >> "$TMPFILE"; ((count++))
        echo "${w^}" >> "$TMPFILE"; ((count++))
        # leet
        l="${w//o/0}"; l="${l//a/4}"; l="${l//e/3}"; l="${l//i/1}"; l="${l//s/5}"
        echo "$l" >> "$TMPFILE"; ((count++))
    done < "$dict"
    echo -e "${GRN}[+] Processed $count transformed entries from $dict${RST}"
}

gen_numeric_range() {
    local start="$1"; local end="$2"; local pad="$3"
    if (( end < start )); then echo "[!] Invalid range"; return 1; fi
    local count=$((end - start + 1))
    echo -e "${YEL}[!] Numeric generation count: $count${RST}"
    if (( count > MAX_WARN )); then
        echo -e "${RED}[!] This will generate a lot of lines. Type CONFIRM to proceed.${RST}"
        read -r ans
        [[ "$ans" != "CONFIRM" ]] && { echo "Aborted."; return 1; }
    fi
    check_disk_for_estimate "$count" || return 1
    local i=0
    for ((n=start;n<=end;n++)); do
        if (( pad > 0 )); then
            printf "%0${pad}d\n" "$n" >> "$TMPFILE"
        else
            printf "%d\n" "$n" >> "$TMPFILE"
        fi
        ((i++))
        (( i % 50000 == 0 )) && progress_echo "$i"
    done
    echo
    echo -e "${GRN}[+] Numeric generation produced $i entries${RST}"
}

gen_template() {
    # chars: # digit, ? lower, @ upper, * alnum
    local template="$1"
    # build charsets array
    local -a sets=()
    for ((i=0;i<${#template};i++)); do
        ch="${template:i:1}"
        case "$ch" in
            '#') sets+=("0123456789") ;;
            '?') sets+=("abcdefghijklmnopqrstuvwxyz") ;;
            '@') sets+=("ABCDEFGHIJKLMNOPQRSTUVWXYZ") ;;
            '*') sets+=("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") ;;
            *) sets+=("$ch") ;;
        esac
    done
    # estimate total
    local total=1
    for s in "${sets[@]}"; do
        if [[ ${#s} -gt 1 ]]; then
            total=$(( total * ${#s} ))
        fi
    done
    echo -e "${YEL}[!] Template will generate approx $total entries${RST}"
    if (( total > MAX_WARN )); then
        echo -e "${RED}[!] Large template expansion. Type CONFIRM to proceed.${RST}"
        read -r ans
        [[ "$ans" != "CONFIRM" ]] && { echo "Aborted."; return 1; }
    fi
    check_disk_for_estimate "$total" || return 1
    # iterative counters
    local len=${#sets[@]}
    local -a idx; for ((i=0;i<len;i++)); do idx[i]=0; done
    while true; do
        local out=""
        for ((i=0;i<len;i++)); do
            s="${sets[i]}"
            if [[ ${#s} -eq 1 ]]; then out+="$s"; else out+="${s:idx[i]:1}"; fi
        done
        echo "$out" >> "$TMPFILE"
        # increment
        local carry=1
        for ((i=len-1;i>=0;i--)); do
            if [[ ${#sets[i]} -eq 1 ]]; then
                continue
            fi
            idx[i]=$(( idx[i] + carry ))
            if (( idx[i] >= ${#sets[i]} )); then
                idx[i]=0
                carry=1
            else
                carry=0; break
            fi
        done
        (( carry )) && break
    done
    echo -e "${GRN}[+] Template generation done${RST}"
}

combine_two_files() {
    local f1="$1"; local f2="$2"; sep="${3:-}"
    if [[ ! -f "$f1" || ! -f "$f2" ]]; then echo "[!] files not found"; return 1; fi
    local count=0
    while IFS= read -r a; do
        while IFS= read -r b; do
            echo "${a}${sep}${b}" >> "$TMPFILE"
            ((count++))
        done < "$f2"
    done < "$f1"
    echo -e "${GRN}[+] Combined into $count entries${RST}"
}

# --- Menu ---------------------------------------------------------------

menu_profile() {
    echo -e "${BLU}Profile mode — answer simple questions${RST}"
    read -r -p "Full name (leave blank to skip): " name
    read -r -p "Nickname: " nick
    read -r -p "Partner name: " partner
    read -r -p "Pet name: " pet
    read -r -p "Birth year (YYYY): " byear
    read -r -p "Important place/city: " city
    tokens=()
    for v in "$name" "$nick" "$partner" "$pet" "$byear" "$city"; do
        [[ -n "$v" ]] && tokens+=("$v")
    done
    if [[ ${#tokens[@]} -eq 0 ]]; then echo "[!] No tokens provided."; return; fi
    ensure_tmp
    gen_profile_variants "${tokens[@]}"
    finalize
}

menu_dict_transforms() {
    read -r -p "Path to dictionary file (one word per line): " dict
    if [[ ! -f "$dict" ]]; then echo "[!] Not found"; return; fi
    ensure_tmp
    gen_dictionary_transforms "$dict"
    finalize
}

menu_numeric() {
    read -r -p "Start (e.g., 0): " s
    read -r -p "End (e.g., 9999): " e
    read -r -p "Zero-pad width (0=no pad, e.g., 4): " pad
    ensure_tmp
    gen_numeric_range "$s" "$e" "$pad"
    finalize
}

menu_template() {
    echo "Template symbols: # digit, ? lower, @ upper, * alnum"
    read -r -p "Template: " tpl
    ensure_tmp
    gen_template "$tpl"
    finalize
}

menu_combine() {
    read -r -p "File A (path): " f1
    read -r -p "File B (path): " f2
    read -r -p "Separator (optional): " sep
    ensure_tmp
    combine_two_files "$f1" "$f2" "$sep"
    finalize
}

menu_sort_unique() {
    read -r -p "Enter file to sort & dedupe: " f
    [[ ! -f "$f" ]] && { echo "[!] not found"; return; }
    sort -u "$f" -o "${f}.sorted" && mv -f "${f}.sorted" "$f"
    echo -e "${GRN}[✔] Sorted & deduped: $f${RST}"
}

main_menu() {
    banner
    while true; do
        echo
        echo -e "${YEL}Choose an option:${RST}"
        echo "1) Profile mode (like cupp) — quick and friendly"
        echo "2) Dictionary transforms (leet, caps, suffixes)"
        echo "3) Numeric generator"
        echo "4) Template generator (# ? @ *)"
        echo "5) Combine two existing wordlists"
        echo "6) Sort & dedupe an existing file"
        echo "0) Exit"
        read -r -p "Select: " opt
        case "$opt" in
            1) read -r -p "Output filename (e.g., mylist.txt): " OUTFILE; menu_profile ;;
            2) read -r -p "Output filename (e.g., dict_out.txt): " OUTFILE; menu_dict_transforms ;;
            3) read -r -p "Output filename (e.g., nums.txt): " OUTFILE; menu_numeric ;;
            4) read -r -p "Output filename (e.g., tpl.txt): " OUTFILE; menu_template ;;
            5) read -r -p "Output filename (e.g., combo.txt): " OUTFILE; menu_combine ;;
            6) menu_sort_unique ;;
            0) echo "Good luck. Stay ethical."; exit 0 ;;
            *) echo "[!] Invalid option." ;;
        esac
    done
}

# --- Entry ---------------------------------------------------------------
main_menu
