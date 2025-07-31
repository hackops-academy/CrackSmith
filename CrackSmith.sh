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
    echo -e "\e[1;91m[~] CrackSmith v1.1 | Powered by HackOps Academy | @_hack_ops_\e[0m"
    echo
}

# Generate wordlist
generate_passwords() {
    echo -e "\n[+] Enter info (leave blank if unknown):"

    read -p "[?] First Name: " fname
    read -p "[?] Last Name: " lname
    read -p "[?] Nickname: " nick

    echo -e "\n[!] Use DDMMYYYY format (e.g. 15082005) or leave blank if unknown"
    read -p "[?] Birthdate: " bday

    read -p "[?] Pet Name: " pet
    read -p "[?] Favorite Number: " favnum
    read -p "[?] Symbols (space-separated, e.g. ! @ #): " sym

    mkdir -p output
    outfile="output/CrackSmith_${fname:-User}.txt"
    > "$outfile"

    base=()
    [[ $fname ]] && base+=("$fname")
    [[ $lname ]] && base+=("$lname")
    [[ $nick ]]  && base+=("$nick")
    [[ $bday ]]  && base+=("$bday")
    [[ $pet ]]   && base+=("$pet")
    [[ $favnum ]] && base+=("$favnum")

    symbols=($sym)
    estimate_lines=$(( ${#base[@]} * (${#symbols[@]} * 2 + 4) ))

    echo -e "\n🧠 Estimated wordlist size:"
    echo -e "   ~ $estimate_lines entries"
    echo -e "   ~ $(($estimate_lines * 10 / 1024)) KB (approx)"

    read -p "[?] Continue generating? (y/n): " confirm
    [[ $confirm != "y" ]] && echo -e "\n[!] Aborted. Exiting...\n" && exit 0

    echo -e "\n[+] Generating passwords..."
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

    echo -e "\n✅ Wordlist saved to: \e[1;93m$outfile\e[0m"
    echo -e "📦 Move to Termux Downloads:\n    \e[1;92mmv $outfile /sdcard/Download/\e[0m"



    # Accurate line count and file size
    line_count=$(wc -l < "$outfile")
    file_size=$(du -h "$outfile" | cut -f1)

    echo -e "📏 Total Lines: \e[1;92m$line_count\e[0m"
    echo -e "💾 File Size: \e[1;92m$file_size\e[0m"
    echo -e "📦 To move to Downloads folder:"
    echo -e "    \e[1;92mmv $outfile /sdcard/Download/\e[0m"
}

# Start tool
banner
generate_passwords
