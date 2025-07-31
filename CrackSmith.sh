#!/bin/bash

# Trap CTRL+C
trap 'echo -e "\n[!] Interrupted. Exiting CrackSmith..."; exit 1' 2

# Output file
outfile="output.txt"
> "$outfile"

# Banner Function
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
    echo -e "\e[1;91m[~] CrackSmith v1.1 | Powered by HackOps Academy | @_hack_ops_\e[0m\n"
}

# Generator Functions
generate_numeric() {
    len=$1
    max=$((10 ** len - 1))
    for i in $(seq -w 0 $max); do
        echo "$i" >> "$outfile"
    done
}

generate_word_combos() {
    wordlist=$1
    count=$2
    delimiter=$3

    words=($(cat "$wordlist"))

    if [[ $count -eq 2 ]]; then
        for w1 in "${words[@]}"; do
            for w2 in "${words[@]}"; do
                echo "${w1}${delimiter}${w2}" >> "$outfile"
            done
        done
    elif [[ $count -eq 3 ]]; then
        for w1 in "${words[@]}"; do
            for w2 in "${words[@]}"; do
                for w3 in "${words[@]}"; do
                    echo "${w1}${delimiter}${w2}${delimiter}${w3}" >> "$outfile"
                done
            done
        done
    else
        echo "[!] Only 2 or 3 word combos supported."
        exit 1
    fi
}

generate_passphrase() {
    wordlist=$1
    count=$2

    for i in {1..1000}; do
        line=""
        for j in $(seq 1 $count); do
            word=$(shuf -n1 "$wordlist")
            line+="$word "
        done
        echo "$line" >> "$outfile"
    done
}

# Menu UI
menu() {
    banner
    echo -e "\e[1;93mChoose an option:\e[0m"
    echo "1) Generate Numeric Passwords"
    echo "2) Generate Word Combinations (2 or 3 words)"
    echo "3) Generate Passphrase (8 or 12 words)"
    echo "4) Exit"
    echo -n $'\nEnter your choice: '
    read choice

    case $choice in
        1)
            echo -n "Enter number of digits (e.g., 4, 6, 8): "
            read digits
            echo "[~] Generating $digits-digit passwords..."
            generate_numeric "$digits"
            ;;
        2)
            echo -n "Enter path to wordlist (e.g., words.txt): "
            read wordlist
            if [[ ! -f "$wordlist" ]]; then echo "[!] File not found"; exit 1; fi
            echo -n "Enter word count (2 or 3): "
            read count
            echo -n "Enter delimiter (or leave blank): "
            read delimiter
            echo "[~] Generating $count-word combinations..."
            generate_word_combos "$wordlist" "$count" "$delimiter"
            ;;
        3)
            echo -n "Enter path to wordlist (e.g., diceware.txt): "
            read wordlist
            if [[ ! -f "$wordlist" ]]; then echo "[!] File not found"; exit 1; fi
            echo -n "Enter word count (8 or 12): "
            read count
            echo "[~] Generating $count-word passphrases..."
            generate_passphrase "$wordlist" "$count"
            ;;
        4)
            echo "[!] Exiting CrackSmith..."
            exit 0
            ;;
        *)
            echo "[!] Invalid choice."
            ;;
    esac

    echo -e "\n[✔] Output saved to: $outfile"
}

# Run Menu Loop
while true; do
    menu
    echo -n $'\n[↻] Run again? (y/n): '
    read again
    [[ "$again" =~ ^[Yy]$ ]] || break
done
