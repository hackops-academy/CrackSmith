#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CrackSmith v2.0 — Advanced Wordlist Generator
Refined for: High Performance & Logic
License: MIT
"""

import sys
import os
import itertools
import time
import signal
import datetime

# --- Configuration & Colors ---
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

VERSION = "2.0 (Python Engine)"

# --- Ethics Warning ---
def banner():
    os.system('cls' if os.name == 'nt' else 'clear')
    print(f"{Colors.GREEN}{Colors.BOLD}")
    print(r"""
_________                       __               _________       .__  __  .__     
\_   ___ \____________    ____ |  | __          /   _____/ _____ |__|/  |_|  |__  
/    \  \/\_  __ \__  \ _/ ___\|  |/ /  ______  \_____  \ /     \|  \   __\  |  \ 
\     \____|  | \// __ \\  \___|    <  /_____/  /        \  Y Y  \  ||  | |   Y  \
 \______  /|__|  (____  /\___  >__|_ \         /_______  /__|_|  /__||__| |___|  /
        \/            \/     \/     \/                 \/      \/              \/ 
 
      Made by Hackops Academy | _hack_ops_
 """)
    print(f"   {Colors.BLUE}v{VERSION} | Advanced Pattern Engine{Colors.END}")
    print(f"{Colors.YELLOW}")
    print(" ETHICS WARNING: This tool is for authorized testing only.")
    print(" Unauthorized access to computer systems is illegal.")
    print(f"{Colors.END}")
    print("-" * 60)

# --- Core Logic Generators ---

def leet_transform(word):
    """Generates leet speak variations."""
    subs = {
        'a': ['4', '@'], 'e': ['3'], 'i': ['1', '!'], 
        'o': ['0'], 's': ['$', '5'], 't': ['7']
    }
    # Simple strategy: Return original, and full-leet version
    # (Recursive permutation is too heavy for millions of base words)
    variations = {word}
    
    # version 1: simple substitution
    chars = list(word)
    for i, c in enumerate(chars):
        if c.lower() in subs:
            chars[i] = subs[c.lower()][0]
    variations.add("".join(chars))
    
    return variations

def casing_transform(word):
    """Returns set of casing variations."""
    return {
        word,
        word.lower(),
        word.upper(),
        word.capitalize(),
        word.swapcase()
    }

def generate_years(start=1980, end=2030):
    return [str(y) for y in range(start, end + 1)]

def get_profile_permutations(data):
    """
    The Heavy Lifter.
    Combines profile data in pairs and triplets.
    Ex: Name+Date, Pet+Name+Suffix, etc.
    """
    base_words = set()
    
    # 1. Normalize Inputs
    raw_inputs = [data[k] for k in data if data[k]]
    
    # 2. Expand Base Words (Case + Leet)
    for w in raw_inputs:
        cases = casing_transform(w)
        for c in cases:
            base_words.update(leet_transform(c))
            
    # Add common separators
    separators = ["", "_", ".", "-", "!"]
    
    # Add common suffixes
    suffixes = ["123", "12", "1", "!", "!!", "01", "2024", "2025"]
    
    # 3. Yield logic (Generator)
    # Single words + suffix
    for word in base_words:
        yield word
        for suf in suffixes:
            yield f"{word}{suf}"
            
    # 4. Combinations (Word + Sep + Word)
    # We limit to permutations of 2 items to keep file size manageable (< 100GB)
    # Use itertools to generate (Word A, Word B)
    for a, b in itertools.permutations(base_words, 2):
        for sep in separators:
            yield f"{a}{sep}{b}"
            # Add suffix to combo
            yield f"{a}{sep}{b}123"
            yield f"{a}{sep}{b}!"

def mask_generator(mask):
    """
    Hashcat style mask generator.
    ?d = digit, ?l = lower, ?u = upper, ?s = symbol
    """
    chars = {
        '?d': '0123456789',
        '?l': 'abcdefghijklmnopqrstuvwxyz',
        '?u': 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        '?s': '!@#$%^&*()-_=+'
    }
    
    # Parse mask
    # This is a basic parser. For advanced parsing, use regex logic.
    # We will assume the user enters standard python format for now or simple placeholders
    # Let's map strict positions.
    
    token_list = []
    i = 0
    while i < len(mask):
        if mask[i] == '?' and i+1 < len(mask):
            key = mask[i:i+2]
            if key in chars:
                token_list.append(chars[key])
                i += 2
                continue
        token_list.append(mask[i]) # Literal character
        i += 1
        
    # itertools.product generates the cartesian product
    for combo in itertools.product(*token_list):
        yield "".join(combo)

# --- Menus & Input ---

def interactive_profile():
    print(f"{Colors.BLUE}[*] PROFILE MODE: Leave empty to skip.{Colors.END}")
    data = {}
    data['first'] = input("First Name: ").strip()
    data['last']  = input("Last Name:  ").strip()
    data['nick']  = input("Nickname:   ").strip()
    data['bday']  = input("Birth Year: ").strip()
    data['partner'] = input("Partner:    ").strip()
    data['pet']   = input("Pet Name:   ").strip()
    data['company'] = input("Company/City: ").strip()
    
    return data

def save_generator_to_file(generator, filename):
    print(f"\n{Colors.YELLOW}[*] Generating... Please wait.{Colors.END}")
    count = 0
    start_time = time.time()
    
    try:
        with open(filename, 'w', encoding='utf-8', errors='ignore') as f:
            for line in generator:
                f.write(line + '\n')
                count += 1
                if count % 50000 == 0:
                    sys.stdout.write(f"\r[+] Lines generated: {count:,}")
                    sys.stdout.flush()
    except KeyboardInterrupt:
        print(f"\n{Colors.RED}[!] Interrupted by user.{Colors.END}")
    
    elapsed = time.time() - start_time
    print(f"\n{Colors.GREEN}[✔] Done! Generated {count:,} passwords in {elapsed:.2f}s.{Colors.END}")
    print(f"{Colors.GREEN}[✔] Saved to: {os.path.abspath(filename)}{Colors.END}")

# --- Main Execution ---

def main():
    signal.signal(signal.SIGINT, lambda x,y: sys.exit(0)) # Clean exit on Ctrl+C
    banner()
    
    print("1. Profile Generator (Smart Combinations)")
    print("2. Mask Attack (e.g. ?l?l?l?d?d)")
    print("3. Numeric Range")
    print("4. Exit")
    
    choice = input(f"\n{Colors.BOLD}Select > {Colors.END}")
    
    filename = input("Enter output filename (default: wordlist.txt): ").strip()
    if not filename: filename = "wordlist.txt"

    if choice == '1':
        data = interactive_profile()
        gen = get_profile_permutations(data)
        save_generator_to_file(gen, filename)
        
    elif choice == '2':
        print(f"\n{Colors.BLUE}Mask Key: ?l (lower), ?u (upper), ?d (digit), ?s (symbol){Colors.END}")
        mask = input("Enter mask (e.g., pass?d?d?d): ")
        gen = mask_generator(mask)
        save_generator_to_file(gen, filename)

    elif choice == '3':
        start = int(input("Start number: "))
        end = int(input("End number: "))
        pad = int(input("Padding (e.g., 4 for 0001): "))
        # Generator expression for efficiency
        gen = (f"{n:0{pad}d}" for n in range(start, end + 1))
        save_generator_to_file(gen, filename)
        
    else:
        print("Exiting.")
        sys.exit()

if __name__ == "__main__":
    main()
    
