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

# Advanced Password Generator
outfile="output.txt"
> "$outfile"

generate_numeric() {
  len=$1
  max=$(printf "%0.s9" $(seq 1 $len))
  for i in $(seq -w 0 $max); do
    echo "$i" >> "$outfile"
  done
}

generate_word_combos() {
  wordlist=$1
  count=$2
  delimiter=${3:-""}

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

# Simple argument parser
case $1 in
  --mode)
    mode=$2
    ;;
esac

case $mode in
  numeric)
    generate_numeric "$4"
    ;;
  words)
    generate_word_combos "$4" "$6" "$8"
    ;;
  passphrase)
    generate_passphrase "$4" "$6"
    ;;
  *)
    echo "Invalid mode. Use numeric, words, or passphrase."
    ;;
esac

echo "[✔] Output saved to $outfile"
