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
banner

# Output file
read -p "Enter output filename (e.g., wordlist.txt): " outfile
> "$outfile"  # Always start clean

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

# Function: Generate 8-word personal pattern passwords
generate_8word() {
    > "$outfile"
    echo "🔐 Generating personal info-based passwords..."
    read -p "Enter target's name: " name
    read -p "Enter target's nickname: " nickname
    read -p "Enter target's birth year (e.g., 1998): " birthyear
    read -p "Enter target's pet name: " pet
    read -p "Enter any special word (like favorite movie): " special

    for word in "$name" "$nickname" "$birthyear" "$pet" "$special"; do
        echo "$word" >> "$outfile"
        echo "${word}123" >> "$outfile"
        echo "${word}1234" >> "$outfile"
        echo "${word}2025" >> "$outfile"
        echo "${word}@123" >> "$outfile"
        echo "${word}!" >> "$outfile"
        echo "${word^^}" >> "$outfile"               # UPPERCASE
        echo "${word,,}" >> "$outfile"               # lowercase
        echo "${word^}" >> "$outfile"                # Capitalized
        echo "${word}@${birthyear}" >> "$outfile"
        echo "${word}#${birthyear}" >> "$outfile"
        echo "${birthyear}${word}" >> "$outfile"
        echo "${word}_$birthyear" >> "$outfile"
        echo "${word}007" >> "$outfile"
        echo "${word}786" >> "$outfile"
        echo "${word}king" >> "$outfile"
        echo "${word}boss" >> "$outfile"
        echo "${word}_@123" >> "$outfile"
        echo "${word}!@#" >> "$outfile"
    done
    echo "✅ Personal info-based password list saved to $outfile"
}

# Function: Generate 12-word stronger passphrases
generate_12word() {
    > "$outfile"
    echo "🔐 Generating advanced passphrases from personal details..."
    read -p "Enter target's name: " name
    read -p "Enter target's nickname: " nickname
    read -p "Enter target's birth year (e.g., 1998): " birthyear
    read -p "Enter target's pet name: " pet
    read -p "Enter any special word (like favorite movie): " special

    for n1 in "$name" "$nickname" "$pet" "$special"; do
        for n2 in "$name" "$nickname" "$pet" "$special"; do
            if [ "$n1" != "$n2" ]; then
                echo "${n1}${n2}${birthyear}" >> "$outfile"
                echo "${n1}_${n2}@${birthyear}" >> "$outfile"
                echo "${n1^}${n2^}#${birthyear}" >> "$outfile"
                echo "${n1,,}.${n2,,}123!" >> "$outfile"
                echo "${n1}007${n2}786" >> "$outfile"
                echo "${n1}@${n2}#${birthyear}" >> "$outfile"
                echo "${birthyear}${n1}${n2}" >> "$outfile"
                echo "${n1}${birthyear}${n2}" >> "$outfile"
                echo "${n1}-${n2}-@123" >> "$outfile"
            fi
        done
    done
    echo "✅ Strong passphrase list generated and saved to $outfile"
}

# Function: Common patterns using dictionary
generate_common_patterns() {
    > "$outfile"
    if [[ ! -f "words.txt" ]]; then
        echo "[!] Missing words.txt dictionary. Place it in the same directory."
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

# Menu
while true; do
    echo
    echo "Choose an option:"
    echo "1) Generate 4-digit passwords"
    echo "2) Generate 8-digit passwords"
    echo "3) Generate 8-word passphrases (based on personal info)"
    echo "4) Generate 12-word strong passphrases (based on personal info)"
    echo "5) Generate common patterns (from dictionary)"
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
