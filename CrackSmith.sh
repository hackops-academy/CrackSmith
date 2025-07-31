#!/bin/bash

=== Trap CTRL+C ===

trap 'echo -e "\n[!] Interrupted. Exiting CrackSmith..."; exit 1' 2

=== Banner ===

banner() { clear echo -e "\e[1;92m" echo " @@@@@@@  @@@@@@@    @@@@@@    @@@@@@@  @@@  @@@   @@@@@@   @@@@@@@@@@   @@@  @@@@@@@  @@@  @@@" echo "@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@  @@@  @@@@@@@   @@@@@@@@@@@  @@@  @@@@@@@  @@@  @@@" echo "!@@       @@!  @@@  @@!  @@@  !@@       @@!  !@@  !@@       @@! @@! @@!  @@!    @@!    @@!  @@@" echo "!@!       !@!  @!@  !@!  @!@  !@!       !@!  @!!  !@!       !@! !@! !@!  !@!    !@!    !@!  @!@" echo "!@!       @!@!!@!   @!@!@!@!  !@!       @!@@!@!   !!@@!!    @!! !!@ @!@  !!@    @!!    @!@!@!@!" echo "!!!       !!@!@!    !!!@!!!!  !!!       !!@!!!     !!@!!!   !@!   ! !@!  !!!    !!!    !!!@!!!!" echo ":!!       !!: :!!   !!:  !!!  :!!       !!: :!!        !:!  !!:     !!:  !!:    !!:    !!:  !!!" echo ":!:       :!:  !:!  :!:  !:!  :!:       :!:  !:!      !:!   :!:     :!:  :!:    :!:    :!:  !:!" echo " ::: :::  ::   :::  ::   :::   ::: :::   ::  :::  :::: ::   :::     ::    ::     ::    ::   :::" echo " :: :: :   :   : :   :   : :   :: :: :   :   :::  :: : :     :      :    :       :      :   : :" echo -e "\e[0m" echo -e "\e[1;91m[~] CrackSmith v2.0 | Powered by HackOps Academy | @hack_ops\e[0m" echo }

=== Password Generators ===

outfile="wordlist.txt" wordfile="words.txt"

4-digit passwords

generate_4digit() { > "$outfile" for i in {0000..9999}; do printf "%04d\n" "$i" >> "$outfile" done echo "[+] 4-digit passwords saved to $outfile" }

8-digit passwords

generate_8digit() { > "$outfile" for ((i=10000000; i<=10010000; i++)); do echo "$i" >> "$outfile" done echo "[+] 8-digit passwords (sample) saved to $outfile" }

Word-based combos

generate_word_passwords() { count=$1 > "$outfile" words=($(shuf -n $((count * 10)) "$wordfile")) for ((i=0; i<${#words[@]} - count; i++)); do pass="" for ((j=0; j<count; j++)); do pass+="${words[i+j]}" done echo "$pass" >> "$outfile" done echo "[+] $count-word passwords saved to $outfile" }

Common patterns from user info

generate_from_user() { echo -e "\n[+] Enter info (leave blank if unknown):" read -p "[?] First Name: " fname read -p "[?] Last Name: " lname read -p "[?] Nickname: " nick read -p "[?] Birthdate (DDMMYYYY): " bday read -p "[?] Pet Name: " pet read -p "[?] Favorite Number: " favnum read -p "[?] Symbols (space-separated): " sym

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

echo -e "\n[+] Generating passwords from input..."
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

}

=== Menu ===

main_menu() { while true; do banner echo "1. Generate 4-digit numeric passwords" echo "2. Generate 8-digit numeric passwords" echo "3. Generate 8-word passwords from dictionary" echo "4. Generate 12-word passwords from dictionary" echo "5. Generate passwords from personal info" echo "0. Exit" echo read -p "[?] Choose an option: " choice

case $choice in
        1) generate_4digit ;;
        2) generate_8digit ;;
        3) generate_word_passwords 8 ;;
        4) generate_word_passwords 12 ;;
        5) generate_from_user ;;
        0) echo -e "\n[!] Exiting CrackSmith...\n"; exit ;;
        *) echo "[!] Invalid option. Try again." ;;
    esac
    read -p $'\n[Enter] Return to menu...'
done

}

main_menu

