#!/usr/bin/env bash
# ========================================================================
# CrackSmith v3.0 – Professional Wordlist Generator (HackOps Edition)
# Author: Lucky (Cyber Ghost) | Powered by HackOps Academy
# License: MIT
# ========================================================================
# Features:
# - Multiple modes: 4-digit, 8-digit, personal patterns, strong passphrases
# - Dictionary-based pattern generator
# - Metadata header in output
# - Duplicate remover + sorter
# - Safe file overwrite with confirmation
# - Progress counter for large lists
# - Works on Kali Linux, Termux, Ubuntu
# ========================================================================

# Trap Exit
trap 'echo -e "\n[!] Interrupted. Exiting CrackSmith..."; exit 1' 2

# Colors
RED="\e[1;91m"
GRN="\e[1;92m"
YEL="\e[1;93m"
BLU="\e[1;94m"
RST="\e[0m"

# Banner
banner() {
    clear
    echo -e "\e[1;92m"
    echo " @@@@@@@  @@@@@@@    @@@@@@    @@@@@@@  @@@  @@@   @@@@@@   @@@@@@@@@@   @@@  @@@@@@@  @@@  @@@"
    echo "@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@  @@@  @@@@@@@   @@@@@@@@@@@  @@@  @@@@@@@  @@@  @@@"
    echo "!@@       @@!  @@@  @@!  @@@  !@@       @@!  !@@  !@@       @@! @@! @@!  @@!    @@!    @@!  @@@"
    echo "!@!       !@!  @!@  !@!  @!@  !@!       !@!  @!!  !@!       !@! !@! !@!  !@!    !@!    !@!  @!@"
    echo "!@!       @!@!!@!   @!@!@!@!  !@!       @!@@!@!   !!@@!!    @!! !!@ @!@  !!@    @!!    @!@!@!@!"
    echo "!!!       !!@!@!    !!!@!!!!  !!!       !!@!!!     !!@!!!   !@!   ! !@!  !!!    !!!    !!!@!!!!"
    echo ":!!       !!: :!!   !!:  !!!  :!!       !!: :!!        !:!  !!:     !!:  !!:    !!:    !!:  !!!"
    echo ":!:       :!:  !:!  :!:  !:!  :!:       :!:  !:!      !:!   :!:     :!:  :!:    :!:    :!:  !:!"
    echo " ::: :::  ::   :::  ::   :::   ::: :::   ::  :::  :::: ::   :::     ::    ::     ::    ::   :::"
    echo " :: :: :   :   : :   :   : :   :: :: :   :   :::  :: : :     :      :    :       :      :   : :"
    echo -e "\e[0m"
    echo -e "\e[1;91m[~] CrackSmith v2.0 | Powered by HackOps Academy | @hack_ops\e[0m"
}


# Safe file creation
prepare_output() {
    read -p "Enter output filename (e.g., wordlist.txt): " outfile
    if [[ -f "$outfile" ]]; then
        read -p "[!] File exists. Overwrite? (y/n): " ans
        [[ "$ans" != "y" ]] && echo "[*] Aborted." && return 1
    fi
    > "$outfile"
    echo "# CrackSmith v3.0 Generated Wordlist" >> "$outfile"
    echo "# Created on: $(date)" >> "$outfile"
    echo "# =====================================" >> "$outfile"
    return 0
}

# Progress feedback
progress() {
    local count=0
    while read -r line; do
        echo "$line" >> "$outfile"
        ((count++))
        if (( count % 5000 == 0 )); then
            echo -ne "[+] Generated $count passwords...\r"
        fi
    done
    echo -e "\n[✔] Wordlist completed. Total: $count"
}

# 4-digit generator
generate_4digit() {
    seq -w 0000 9999 | progress
}

# 8-digit generator
generate_8digit() {
    seq -w 00000000 99999999 | progress
}

# Personal info-based patterns
generate_8word() {
    echo "[*] Collecting personal info..."
    read -p "Name: " name
    read -p "Nickname: " nickname
    read -p "Birth Year: " birthyear
    read -p "Pet Name: " pet
    read -p "Special Word: " special

    for word in "$name" "$nickname" "$birthyear" "$pet" "$special"; do
        echo "$word" 
        echo "${word}123" 
        echo "${word}1234" 
        echo "${word}2025"
        echo "${word}@123" 
        echo "${word^^}" 
        echo "${word,,}" 
        echo "${word^}" 
        echo "${word}!@#" 
        echo "${word}${birthyear}" 
        echo "${birthyear}${word}" 
        echo "${word}_007" 
        echo "${word}king"
        echo "${word}boss"
    done | progress
}

# Stronger passphrases
generate_12word() {
    read -p "Name: " name
    read -p "Nickname: " nickname
    read -p "Birth Year: " birthyear
    read -p "Pet: " pet
    read -p "Special: " special

    for n1 in "$name" "$nickname" "$pet" "$special"; do
        for n2 in "$name" "$nickname" "$pet" "$special"; do
            [[ "$n1" != "$n2" ]] && {
                echo "${n1}${n2}${birthyear}"
                echo "${n1}_${n2}@${birthyear}"
                echo "${n1^}${n2^}#${birthyear}"
                echo "${n1,,}.${n2,,}123!"
                echo "${n1}007${n2}786"
                echo "${birthyear}${n1}${n2}"
            }
        done
    done | progress
}

# Dictionary-based patterns
generate_common_patterns() {
    if [[ ! -f "words.txt" ]]; then
        echo "[!] Missing words.txt dictionary. Place it in script folder."
        return
    fi
    while read -r word; do
        echo "${word}123"
        echo "${word}1234"
        echo "${word}2025"
        echo "${word}!@#"
        echo "123${word}"
        echo "${word}007"
    done < words.txt | progress
}

# Cleanup function: sort + remove duplicates
finalize_wordlist() {
    sort -u "$outfile" -o "$outfile"
    echo "[✔] Final wordlist saved as: $outfile"
}

# Menu
menu() {
    while true; do
        echo -e "\n${YEL}Choose an option:${RST}"
        echo "1) Generate 4-digit passwords"
        echo "2) Generate 8-digit passwords"
        echo "3) Generate personal patterns (8-word)"
        echo "4) Generate strong passphrases (12-word)"
        echo "5) Generate common dictionary-based patterns"
        echo "6) Remove duplicates & sort wordlist"
        echo "0) Exit"
        read -p "Enter choice: " choice

        case $choice in
            1) prepare_output && generate_4digit && finalize_wordlist ;;
            2) prepare_output && generate_8digit && finalize_wordlist ;;
            3) prepare_output && generate_8word && finalize_wordlist ;;
            4) prepare_output && generate_12word && finalize_wordlist ;;
            5) prepare_output && generate_common_patterns && finalize_wordlist ;;
            6) finalize_wordlist ;;
            0) echo "[*] Exiting CrackSmith. Stay sharp, Hacker!"; exit ;;
            *) echo "[!] Invalid choice. Try again." ;;
        esac
    done
}

# Run
banner
menu
