#!/usr/bin/zsh

#
# This file contains the integrated backup system for the main computer
#

# Perform a local backup
# Requires to set the "ADF_LOCBAK_PASSPHRASE" variable
# Arguments are paths to back up
# Set "ADF_ADD_ADF_FILES_TO_BACKUP" to perform a backup of the current environment
# You may also set "ADF_DEOBFUSCATE_PASSPHRASE"
function adf_local_backup() {
    if [[ -z $ADF_LOCBAK_PASSPHRASE ]]; then
        echoerr "Please provide a \z[yellow]°\$ADF_LOCBAK_PASSPHRASE\z[]° variable."
        return 1
    fi
    
    if (( $ADF_DEOBFUSCATE_PASSPHRASE )); then
        ADF_DEOBFUSCATE_PASSPHRASE=$(adf_obf_decode "$ADF_DEOBFUSCATE_PASSPHRASE")
        if [[ $? != 0 ]]; then return 2; fi
    fi

    echoinfo "(1/3) Building the files list..."

    local listfile="/tmp/rebackup-list-$(date +%s).txt"
    touch "$listfile"

    if (( $ADF_ADD_ADF_FILES_TO_BACKUP )); then
        ADF_SILENT=1 zerupdate
        _adf_add_dir_to_list "$listfile" "$ADF_LAST_BACKUP_DIR"
    fi

    if ! _adf_add_dir_to_list "$listfile" "$@"; then return 3; fi
    if ! _adf_add_dir_to_list "$listfile" $ADF_ALWAYS_BACKUP; then return 3; fi

    echoinfo ""
    echoinfo "(2/3) Compressing \z[yellow]°$(wc -l < "$listfile")\z[]° elements..."
    echoinfo ""

    local tmpfile="$TEMPDIR/adf-backup-$(humandate).7z"
    
    if ! 7z a -t7z -m0=lzma2 -mx=5 -mfb=64 -md=32m -ms=on -mhc=on -mhe=on -spf2 -bso0 -p"$ADF_LOCBAK_PASSPHRASE" "$tmpfile" @"$listfile"; then
        echoerr "Command \z[yellow]°7z\z[]° failed."
        command rm "$listfile"
        return 4
    fi

    command rm "$listfile"

    local outfile="$LOCBAKDIR/$(humandate).7z"

    echoinfo " "
    echoinfo "(3/3) Moving the final archive..."
    echoinfo " "

    if ! mv "$tmpfile" "$outfile"; then
        echoerr "Command \z[yellow]°mv\z[]° failed."
        return 5
    fi

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
        echoinfo "> Treating: \z[yellow]°$item\z[]°"

        if [[ -f $item ]]; then
            echo "$item" >> "$listfile"
            continue
        elif [[ ! -d $item ]]; then
            echoerr "Input directory \z[yellow]°$item\z[]° does not exist!"
            return 2
        fi

        if ! fd --hidden --one-file-system --type 'file' --absolute-path --search-path "$item" >> "$listfile"; then
            echoerr "Command \z[yellow]°fd\z[]° failed."
            return 2
        fi
    done
}
