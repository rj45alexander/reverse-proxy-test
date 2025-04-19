#!/bin/bash

if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run with sudo."
    exit 1
fi

NLOGIN_SHELL="/usr/sbin/nologin"
GROUP="proxyusers"

if ! getent group "$GROUP" &>/dev/null; then
    echo "Group $GROUP not found; creating automatically."
    groupadd "$GROUP"
fi

echo
echo "1. Create new proxy user"
echo "2. Remove existing proxy user"
echo "3. List all proxy users"
echo
read -rp "Enter choice [1/2/3]: " choice
echo
case "$choice" in
    1)
        read -rp "Enter new username: " username

        if id "$username" &>/dev/null; then
            echo "User '$username' already exists."
            exit 1
        fi
        
        read -rsp "Enter password: " password
        echo
        read -rsp "Confirm password: " password2
        echo

        if [[ "$password" != "$password2" ]]; then
            echo "Passwords do not match."
            exit 1
        fi
        if [[ -z "$username" || -z "$password" ]]; then
            echo "Username or password cannot be empty."
            exit 1
        fi
        sudo useradd -M -s "$NLOGIN_SHELL" -G "$GROUP" "$username"
        echo "$username:$password" | sudo chpasswd
        echo "User '$username' created and added to $GROUP."
        ;;
    2)
        read -rp "Enter username to delete: " username

        if [[ -z "$username" ]]; then
            echo "No username supplied."
            exit 1
        fi

        if getent group "$GROUP" | grep -qw "$username"; then
            read -rp "Are you sure you want to delete user '$username'? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                userdel "$username"
                echo "User '$username' deleted."
            else
                echo "Aborted."
                exit 1
            fi
        else
            echo "User '$username' is not part of the $GROUP group or does not exist."
        fi
        ;;
    3)
        echo "Proxy users:"
        # uid>1000
        awk -F: -v shell="$NLOGIN_SHELL" -v group="$GROUP" '
            $7 == shell && $3 >= 1000 {
                cmd = "id -nG " $1
                cmd | getline groups
                close(cmd)
                if (groups ~ group) print $1
            }' /etc/passwd
        ;;
    *)
        echo "Invalid choice."
        ;;
esac
