#!/bin/bash
clear

trap 'echo -e "\n[!] Interrupted. Exiting CrackSmith..."; exit 1' 2

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
    echo -e "\e[1;91m[~] CrackSmith v2.0 | Powered by HackOps Academy | @hack_ops\e[0m"
}

# Output file
read -p "Enter output filename (e.g., wordlist.txt): " outfile

# Function: Generate 4-digit passwords
generate_4digit() {
    > "$outfile"
    for i in $(seq -w 0000 9999); do
        echo "$i" >> "$outfile"
    done
    echo "[+] 4-digit passwords saved to $outfile"
}

# Function: Generate 8-digit numeric passwords
generate_8digit() {
    > "$outfile"
    for i in $(seq -w 00000000 99999999); do
        echo "$i" >> "$outfile"
    done
    echo "[+] 8-digit passwords saved to $outfile"
}

# Function: Generate 8-word passphrases
generate_8word() {
    > "$outfile"
    if [[ ! -f "words.txt" ]]; then
        echo "[!] Missing words.txt dictionary"
        return
    fi
    for i in {1..100}; do
        shuf -n 8 words.txt | tr '\n' ' ' | sed 's/ $//' >> "$outfile"
        echo "" >> "$outfile"
    done
    echo "[+] 8-word passphrases saved to $outfile"
}

# Function: Generate 12-word passphrases
generate_12word() {
    > "$outfile"
    if [[ ! -f "words.txt" ]]; then
        echo "[!] Missing words.txt dictionary"
        return
    fi
    for i in {1..100}; do
        shuf -n 12 words.txt | tr '\n' ' ' | sed 's/ $//' >> "$outfile"
        echo "" >> "$outfile"
    done
    echo "[+] 12-word passphrases saved to $outfile"
}

# Function: Common password pattern generator
generate_common_patterns() {
    > "$outfile"
    if [[ ! -f "words.txt" ]]; then
        echo "[!] Missing words.txt dictionary"
        return
    fi
    while read -r word; do
        echo "${word}123" >> "$outfile"
        echo "${word}1234" >> "$outfile"
        echo "${word}12345" >> "$outfile"
        echo "${word}2025" >> "$outfile"
        echo "${word}2024" >> "$outfile"
        echo "${word}!" >> "$outfile"
        echo "${word}@123" >> "$outfile"
        echo "${word}@2025" >> "$outfile"
        echo "123${word}" >> "$outfile"
        echo "${word}#007" >> "$outfile"
        echo "${word}_007" >> "$outfile"
        echo "${word}@" >> "$outfile"
        echo "${word}#123" >> "$outfile"
        echo "${word}_pass" >> "$outfile"
        echo "${word}00" >> "$outfile"
        echo "${word}007" >> "$outfile"
    done < words.txt
    echo "[+] Common patterns saved to $outfile"
}

# Call the banner
banner

# Menu
while true; do
    echo
    echo "Choose an option:"
    echo "1) Generate 4-digit passwords"
    echo "2) Generate 8-digit passwords"
    echo "3) Generate 8-word passphrases"
    echo "4) Generate 12-word passphrases"
    echo "5) Generate common password patterns"
    echo "0) Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1) generate_4digit ;;
        2) generate_8digit ;;
        3) generate_8word ;;
        4) generate_12word ;;
        5) generate_common_patterns ;;
        0) echo "Exiting..."; exit ;;
        *) echo "Invalid option. Try again." ;;
    esac
done
