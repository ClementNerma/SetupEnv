#
# RClone handler
#

function rclone_mirror() {
    if ! __rclone_sync_full "$1" "$2" --dry-run; then
        return 1
    fi

    echo ""
    echo ""
    echoinfo "Confirm the synchronization (Y/n)?"

    read "answer?"

    if [[ ! -z $answer && $answer != "y" && $answer != "Y" ]]; then
        return 2
    fi
    
    echoinfo "Sleeping 2 seconds before starting..."
    sleep 2

    if ! __rclone_sync_full "$1" "$2"; then
        return 10
    fi

    echosuccess "Successfully synchronized \z[magenta]°$1\z[]° to \z[magenta]°$2\[]°."
}

function __rclone_sync_full() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide a source."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a destination."
        return 2
    fi

    if [[ ! -d "$(wslpath "$1")" ]]; then
        echoerr "Source directory was not found at path \z[yellow]°$1\z[]°."
        return 3
    fi

    if ! rclone.exe lsf "$2" > /dev/null; then
        echoerr "Destination does not exist or is not available."
        return 4
    fi

    rclone.exe sync "$1" "$2" \
        --progress \
        --max-backlog "10000000" \
        --create-empty-src-dirs \
        --track-renames --track-renames-strategy "leaf,size" \
        --filter "- System Volume Information/**" \
        --filter "- \$RECYCLE.BIN/**" \
        --filter "- .yacreaderlibrary/**" \
        --filter "- ROMS/WIIU/**" \
        "${@:3}"
}
