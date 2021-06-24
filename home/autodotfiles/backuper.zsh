#!/usr/bin/zsh

#
# This file contains the integrated backup system for the main computer
#

# Perform a local backup
# Requires to set the "ADF_LOCBAK_PASSPHRASE" variable
# Arguments are paths to back up
# Set "ADF_ADD_ADF_FILES_TO_BACKUP" to perform a backup of the current environment
#  To search for specific patterns inside the directory, suffix it by `::<glob pattern>`
# You may also set "ADF_DEOBFUSCATE_PASSPHRASE"
# As well as "ADF_MIRROR_BACKUP" to duplicate it to another location
#
# To create a non-compressed archive, set the "ADF_BACKUP_NO_COMPRESS" variable to 1 or provide a "--no-compress" argument.
function adf_local_backup() {
    if [[ ! -z "$1" && $1 != "--no-compress" ]]; then
        echoerr "Invalid argument provided (must be \z[yellow]°--no-compress\[]° or nothing)"
        return 9
    fi

    if [[ -z $ADF_LOCBAK_PASSPHRASE ]]; then
        echoerr "Please provide a \z[yellow]°\$ADF_LOCBAK_PASSPHRASE\z[]° variable."
        return 1
    fi

    if [[ ! -z $ADF_MIRROR_BACKUP && ! -d $ADF_MIRROR_BACKUP ]]; then
        echoerr "The provided mirro backup directory does not exist!"
    fi
    
    local passphrase="$ADF_LOCBAK_PASSPHRASE"
    
    if (( $ADF_DEOBFUSCATE_PASSPHRASE )); then
        if ! passphrase=$(echo "$passphrase" | adf_obf_decode); then
            return 2
        fi
    fi

    if [[ -z $passphrase ]]; then
        echoerr "The encryption passphrase cannot be empty!"
        return 1
    fi

    if [[ ! -z $ADF_BACKUP_PREPARATION_SCRIPT ]]; then
        echoinfo " "
        echoinfo "(1/5) Running the preparation script..."
        echoinfo " "

        if ! $ADF_BACKUP_PREPARATION_SCRIPT; then
            echoerr "Local backup preparation script exited with a non-zero code."
            return 99
        fi
    else
        echowarn " "
        echowarn "(1/5) No preparation script to run, skipping this step."
        echowarn " "
    fi

    echoinfo " "
    echoinfo "(2/5) Building the files list..."
    echoinfo " "

    local listfile="/tmp/rebackup-list-$(date +%s%N).txt"
    touch "$listfile"

    if ! _adf_add_dir_to_list "$listfile" "$@"; then return 3; fi
    if ! _adf_add_dir_to_list "$listfile" $ADF_ALWAYS_BACKUP; then return 3; fi

    if (( $ADF_ADD_ADF_FILES_TO_BACKUP )); then
        ADF_SILENT=1 zerbackup
        _adf_add_dir_to_list "$listfile" "$ADF_LAST_BACKUP_DIR"
    fi

    if (( $ADF_BACKUP_DRY_RUN )); then
        cat "$listfile"
        rm "$listfile"
        return 99
    fi

    echoinfo ""
    echoinfo "(3/5) Compressing \z[yellow]°$(wc -l < "$listfile")\z[]° elements..."
    echoinfo ""

    local tmpfile="$TEMPDIR/adf-backup-$(humandate).tmp.7z"
    
    if (( $ADF_BACKUP_NO_COMPRESS )); then
        echowarn "Creating a NON-COMPRESSED archive."
        7z a -t7z -m0=Copy -mmt=1 -spf2 -bso0 -p"$passphrase" "$tmpfile" @"$listfile"
    else
        7z a -t7z -m0=lzma2 -mx=$compression -mfb=64 -md=32m -ms=on -mhc=on -mhe=on -spf2 -bso0 -p"$passphrase" "$tmpfile" @"$listfile"
    fi
        
    if (( $? )); then
        echoerr "Command \z[yellow]°7z\z[]° failed."
        command rm "$listfile"
        return 4
    fi

    command rm "$listfile"

    local outfile="$LOCBAKDIR/adf-$(humandate).7z"

    echoinfo " "
    echoinfo "(4/5) Moving the final archive..."
    echoinfo " "

    if ! mv "$tmpfile" "$outfile"; then
        echoerr "Command \z[yellow]°mv\z[]° failed."
        return 5
    fi

    if [[ ! -z $ADF_MIRROR_BACKUP ]]; then
        echoinfo " "
        echoinfo "(5/5) Mirroring the backup..."
        echoinfo " "

        if ! cp "$outfile" "$ADF_MIRROR_BACKUP/$(basename "$outfile")"; then
            echoerr "Command \z[yellow]°cp\z[]° failed."
            return 6
        fi
    else
        echowarn " "
        echowarn "(5/5) WARNING: No mirroring to perform, skipping this type."
        echowarn " "
    fi

    echoverb "Synchronizing storage..."
    sync

    echosuccess "Done! Archive path is \z[magenta]°$outfile\z[]°"
}

function _adf_add_dir_to_list() {
    if [[ ! -f $1 ]]; then
        echoerr "Internal: missing list file in backuper's subroutine"
        return 1
    fi

    if [[ $# == 1 ]]; then
        return
    fi

    local listfile="$1"
    shift

    for item in "$@"; do
        local pattern=""

        local glob_sep_index=${item[(ie)::(GLOB)::]}
        local regex_sep_index=${item[(ie)::(REGEX)::]}

        if (( $glob_sep_index > 0 )) && (( $glob_sep_index <= ${#item} )); then
            pattern="--glob=${item:$((glob_sep_index + 9))}"
            item=${item:0:$((glob_sep_index - 1))}
        elif (( $regex_sep_index > 0 )) && (( $regex_sep_index <= ${#item} )); then
            pattern=${item:$((regex_sep_index + 10))}
            item=${item:0:$((regex_sep_index - 1))}
        fi

        echoinfo "> Treating: \z[magenta]°$item\z[]° \z[cyan]°$pattern\z[]°"

        if [[ -f $item ]]; then
            echo "$item" >> "$listfile"
            continue
        elif [[ ! -d $item ]]; then
            echoerr "Input directory \z[yellow]°$item\z[]° does not exist!"
            return 2
        fi

        local files=""

        if ! files=$(fd --threads=1 --hidden --one-file-system --type 'file' --absolute-path --search-path "$item" "$pattern"); then
            echoerr "Command \z[yellow]°fd\z[]° failed."
            return 2
        fi

        files=$(printf "%s" "$files" | grep "\S")

        if [[ -z "$files" ]]; then
            echowarn ">  WARNING: No matching found for this item!"
        else
            printf "%s\n" "$files" | sort >> "$listfile"
        fi
    done
}
