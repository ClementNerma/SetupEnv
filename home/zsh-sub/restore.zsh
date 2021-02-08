#!/usr/bin/zsh

# This file is not loaded with SetupEnv.
# It is meant to be put in '/usr/local/bin' to be used to restore SetupEnv after it has been uninstalled by the user.

last_backup="$1"

if [[ ! -z "$last_backup" ]]; then
    echo "INFO: Restoring from provided backup path: $last_backup"
else
    last_backup_filepath="$HOME/.uninstalled-setupenv.txt"

    if [[ ! -f "$last_backup_filepath" ]]; then
        echo "ERROR: backup file path not found at: $last_backup_filepath"
        return 1
    fi

    last_backup="$(command cat "$last_backup_filepath")"

    echo "INFO: Restoring from memorized backup path: $last_backup"
fi

if [[ ! -d "$last_backup" ]]; then
    echo "ERROR: Backup path does not exist or is not a directory!"
    return 1
fi

glob_dots_was_enabled=0

if [[ -o GLOB_DOTS ]]; then
    glob_dots_was_enabled=1
else
    setopt GLOB_DOTS
fi

export SETUPENV_RESTORATION_OVERWRITTEN_FILES="$HOME/.setupenv-restoring-$(date +%s)"

echo "INFO: Moving all overwritten files to: $SETUPENV_RESTORATION_OVERWRITTEN_FILES"
mkdir "$SETUPENV_RESTORATION_OVERWRITTEN_FILES"

for item in "$last_backup/"*; do
    echo "INFO: > Restoring: $(basename "$item")"

    orig_item="$HOME/$(basename "$item")"

    if [[ -f "$orig_item" || -d "$orig_item" ]]; then
        echo "INFO: >> Backing up: $orig_item"
        command mv "$orig_item" "$SETUPENV_RESTORATION_OVERWRITTEN_FILES/"
    fi

    command mv "$item" "$orig_item"
done

if [[ $glob_dots_was_enabled = 0 ]]; then
    unsetopt GLOB_DOTS
fi

echo " "
echo "INFO: Successfully restored SetupEnv!"
echo "INFO: Please log in again."
echo " "

exit
