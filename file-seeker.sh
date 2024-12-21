#!/bin/bash

# Function to recursively count and display files and directories (including hidden ones)
find_files() 
{
    # Include hidden files and directories with ".*"
    for item in "$1"/* "$1"/.*; do
        # Skip the special directories "." and ".."
        if [ "$(basename "$item")" == "." ] || [ "$(basename "$item")" == ".." ]; then
            continue
        fi

        if [ -d "$item" ]; then
            # It is a directory
            echo -e "Directory: ${BLUE}$item${RESET}"
            dir_count=$((dir_count + 1))
            find_files "$item" # Recursive call
        elif [ -f "$item" ]; then
            # It is a file
            #echo -e "File: ${GREEN}$item${RESET}"
            #file_count=$((file_count + 1))
            if [[ "$extension" == "*" ]] || [[ "$item" == *."$extension" ]]; then
                size=$(du -h "$item" | cut -f1)
                case "$action" in
                    "list")
                        echo -e "File: ${GREEN}$item${RESET} (${GREEN}$size${RESET})"
                        ;;

                    "empty")
                        echo -e "Empty file: ${GREEN}$item${RESET} (${GREEN}$size${RESET})"
                        echo "Lorem ipsum dolor sit amet, consectetur adipisicing elit" > "$item"
                        echo "" > "$item"
                        ;;

                    "delete")
                        echo -e "Encrypting file: ${GREEN}$item${RESET} (${GREEN}$size${RESET})"

                        # Step 1: Encrypt the file and overwrite it
                        if openssl enc -aes-256-cbc -salt -pbkdf2 -in "$item" -out "$item" -pass pass:"$password" 2>/dev/null; then
                            echo -e "File encrypted and saved as: ${GREEN}$item${RESET}"
                        else
                            echo -e "${RED}Error encrypting file: $item. Skipping...${RESET}"
                        fi

                        echo -e "Overwriting original file with random data ${overwrite} times: ${GREEN}$item${RESET}"
                        shred -n${overwrite} -f -z "$item"  # Overwrite the file 5 times with random data and zeros

                        # We overwrite the file name 5 times with a hash
                        for i in {1..5}; do
                            # Generate an MD5 hash based on the current name and timestamp
                            hash=$(echo "$item-$(date +%s)" | md5sum | cut -d' ' -f1)
                            new_name="$(dirname "$item")/$hash"

                            # Rename the file
                            mv "$item" "$new_name"
                            echo -e "File renamed to: ${GREEN}$new_name${RESET} number $i"

                            item="$new_name"
                        done
                        
                        # Delete the renamed file
                        echo "Lorem ipsum dolor sit amet, consectetur adipisicing elit" > "$new_name"
                        rm -f "$new_name"
                        echo -e "File deleted: ${RED}$new_name${RESET}"
                    ;;

                esac
                
                file_count=$((file_count + 1))
            fi
        fi
    done
}

process_empty_dirs() 
{
    local path="$1"   # Path to search in
    local count=0     # Counter for affected directories

    # Find and process empty directories
    while read -r dir; do
        echo -e "Processing empty directory: ${GREEN}$dir${RESET}"

        for i in {1..5}; do
            # Generate a random hash for renaming
            hash=$(echo "$dir-$(date +%s)" | md5sum | cut -d' ' -f1)
            new_name="$(dirname "$dir")/$hash"

            # Rename the directory
            mv "$dir" "$new_name"

            dir="$new_name"
        done

        echo -e "Directory renamed to: ${GREEN}$new_name${RESET}"

        # Delete the renamed directory
        rmdir "$new_name"
        echo -e "Directory deleted: ${RED}$new_name${RESET}"

        ((count++)) # Increment the counter
    done < <(find "$path" -type d -empty)

    # Print the total number of affected directories
    echo -e "${GREEN}Total directories affected: $count${RESET}"
}

# define colors
GREEN="\033[32m"
RED="\033[31m"
BLUE="\033[34m"     
PURPLE="\033[35m"   
YELLOW="\033[33m"    
ORANGE="\033[38;5;208m"   
RESET="\033[0m"

# Check if a path is provided as an argument
if [ $# -ne 2 ]; then
    echo
    echo -e "${YELLOW}  Usage:   $0 <path> <extension> "
    echo -e "${YELLOW}  Example: $0 /path/to/dir txt   (searches .txt files) "
    echo -e "${YELLOW}           $0 /path/to/dir '*'   (searches all files)${RESET}"
    echo
    exit 1
fi

# Initialize variables
password="lar32ldasnkh4k23heasdnkwnr23lqnedni3dn"
path="$1"
extension="$2"
file_count=0
dir_count=0
overwrite=15


# Check if the provided path exists and is a directory
if [ ! -d "$path" ]; then
    echo "Error: The path '$path' does not exist or is not a directory."
    exit 1
fi

offset=10
padding=$(printf "%${offset}s")

# Mostrar texto con desplazamiento
echo
echo "================================================================="
echo -e "  ${GREEN}What do you want to do?${RESET}"
echo
echo -e "${padding}${GREEN}1) Search and see${RESET}"
echo -e "${padding}${GREEN}2) Search and Empty${RESET}"
echo -e "${padding}${GREEN}3) Search and delete${RESET}"
echo -e "${padding}${GREEN}4) Search empty directories and Delete${RESET}"
echo -e "${padding}${GREEN}5) Do nothing${RESET}"
echo "================================================================="
# Leer opción con desplazamiento
echo -n "${padding}"  # Añadir padding a la línea de entrada
echo
read -p "Enter your choice (1, 2, 3, 4 or 5): " action_choice

# Display start message
echo 
echo -e "Scanning path: ${GREEN}$path${RESET}"
echo "-------------------------"

case "$action_choice" in
    1)
        action="list"
        find_files "$path"  
        echo
        echo "*** Search files end"
        ;;
    2)
        action="empty"
        read -p "${RED}Are you sure you want to execute the 'empty' files? (yes/no):${RESET} " confirm

        if [[ "$confirm" == "yes" ]]; then
            find_files "$path"
            echo
            echo "*** Search & Empty End"
        else
            echo "Operation canceled by the user."
        fi

        ;;
    3)
        action=delete
        read -p "$( echo -e "${RED}Are you sure you want to execute the 'delete' files? (yes/no):${RESET} ")" confirm

        if [[ "$confirm" == "yes" ]]; then
            find_files "$path"
            echo
            echo "*** Search & Destroy End"
        else
            echo "Operation canceled by the user."
        fi

        ;;
    4)
        read -p "$( echo -e "${RED}Are you sure you want to execute the 'delete' empty directories? (yes/no):${RESET} ")" confirm

        if [[ "$confirm" == "yes" ]]; then
            process_empty_dirs "$path"
            echo
            echo "*** Search & destroy directories end ***"
        else
            echo "Operation canceled by the user."
        fi

        ;;
    5)
        echo
        echo -e " * ${RED}Do nothing selected${RESET}";
        ;;
    *)
        echo -e "${RED}Invalid choice. No action taken.${RESET}"
        ;;
esac


# Display the final count summary
echo
echo "-------------------------"
echo "Summary:"
echo -e "${ORANGE}Total directories: $dir_count${RESET}"
echo -e "${ORANGE}Total files: $file_count${RESET}"
echo
