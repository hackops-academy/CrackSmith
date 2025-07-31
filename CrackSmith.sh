#!/bin/bash

# Trap CTRL+C
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
    echo -e "\e[1;91m[~] CrackSmith v1.0 | Powered by HackOps Academy | @_hack_ops_\e[0m"
    echo
}

# Generate password list
generate_passwords() {
    echo -e "\n[+] Enter target info to craft the wordlist:"
    read -p "[?] First Name: " fname
    read -p "[?] Last Name: " lname
    read -p "[?] Nickname: " nick
    read -p "[?] Birthdate (ddmmyyyy): " bday
    read -p "[?] Pet Name: " pet
    read -p "[?] Favorite Number: " favnum
    read -p "[?] Symbols to append (e.g. ! @ #): " sym

    mkdir -p output
    outfile="output/${fname}_cracksmith.txt"
    > "$outfile"

    base=("$fname" "$lname" "$nick" "$bday" "$pet" "$favnum")
    symbols=($(echo $sym))

    echo -e "\n[+] Generating variations..."

    for word in "${base[@]}"; do
        for sym in "${symbols[@]}"; do
            echo "${word}${sym}" >> "$outfile"
            echo "${sym}${word}" >> "$outfile"
        done
        echo "$word" >> "$outfile"
        echo "${word}123" >> "$outfile"
        echo "${word}1234" >> "$outfile"
        echo "${word}2025" >> "$outfile"
        echo "${word^^}" >> "$outfile"
        echo "${word,,}" >> "$outfile"
        echo "${word^}" >> "$outfile"
    done

    echo -e "\n✅ Wordlist saved as: \e[1;93m$outfile\e[0m"
    echo -e "[*] Total lines: $(wc -l < $outfile)"
    echo -e "[*] Move to Termux Downloads with:\n    \e[1;92mmv $outfile /sdcard/Download/\e[0m"
}

# Start
banner
generate_passwords
