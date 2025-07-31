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


# === Configuration ===
outfile="wordlist.txt"
wordfile="words.txt"  # Add your base words here

# === Common patterns function ===
generate_common_patterns() {
    > "$outfile"
    while read -r word; do
        echo "$word" >> "$outfile"
        echo "${word}123" >> "$outfile"
        echo "${word}1234" >> "$outfile"
        echo "${word}@123" >> "$outfile"
        echo "${word}@2025" >> "$outfile"
        echo "${word}2025" >> "$outfile"
        echo "${word}#2025" >> "$outfile"
        echo "${word}!" >> "$outfile"
        echo "123${word}" >> "$outfile"
        echo "admin${word}" >> "$outfile"
        echo "${word}admin" >> "$outfile"
        echo "${word}root" >> "$outfile"
        echo "${word}pass" >> "$outfile"
        echo "${word}!" >> "$outfile"
        echo "${word}@" >> "$outfile"
        echo "${word}@#" >> "$outfile"
        echo "${word}$$" >> "$outfile"
    done < "$wordfile"
    echo "[+] Common password patterns generated in $outfile"
}

# === Number Password Generators ===
generate_4digit() {
    > "$outfile"
    for i in {0000..9999}; do
        printf "%04d\n" "$i" >> "$outfile"
    done
    echo "[+] 4-digit passwords generated in $outfile"
}

generate_8digit() {
    > "$outfile"
    for ((i=10000000; i<=10010000; i++)); do
        echo "$i" >> "$outfile"
    done
    echo "[+] 8-digit passwords (sample) generated in $outfile"
}

# === Word-based Passwords ===
generate_word_passwords() {
    count=$1
    > "$outfile"
    words=($(shuf -n $((count * 10)) "$wordfile"))
    for ((i=0; i<${#words[@]} - count; i++)); do
        pass=""
        for ((j=0; j<count; j++)); do
            pass+="${words[i+j]}"
        done
        echo "$pass" >> "$outfile"
    done
    echo "[+] ${count}-word passwords generated in $outfile"
}

# === Menu ===
while true; do
    clear
    echo "=============================="
    echo "  🔐 Password Wordlist Maker"
    echo "=============================="
    echo "1. Generate 4-digit numeric passwords"
    echo "2. Generate 8-digit numeric passwords"
    echo "3. Generate 8-word passwords (combined)"
    echo "4. Generate 12-word passwords (combined)"
    echo "5. Generate common password patterns"
    echo "0. Exit"
    echo "------------------------------"
    read -p "Choose an option: " choice

    case $choice in
        1) generate_4digit ;;
        2) generate_8digit ;;
        3) generate_word_passwords 8 ;;
        4) generate_word_passwords 12 ;;
        5) generate_common_patterns ;;
        0) echo "Exiting..."; exit ;;
        *) echo "Invalid option. Try again." ;;
    esac
    read -p "Press Enter to return to menu..."
done
