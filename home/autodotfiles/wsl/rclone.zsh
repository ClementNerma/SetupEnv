#
# RClone handler
#

function rclone_mirror() {
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

    if ! rclone_list=$(__rclone_sync_nocheck "$1" "$2" --dry-run "${@:3}" 2>&1 > /dev/null); then
        return 4
    fi

    local items=()
    local todelete=()
    local tomove=()
    local total=""
    local size=""
    local noitem=0

    while IFS= read -r line; do
        if [[ $line =~ ^[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9]?[0-9][[:space:]][0-9]?[0-9]:[0-9][0-9]:[0-9][0-9][[:space:]]NOTICE:[[:space:]]([^:]+):[[:space:]]Skipped[[:space:]](copy|delete|move)[[:space:]]as[[:space:]]--dry-run[[:space:]]is[[:space:]]set[[:space:]]\\(size[[:space:]][0-9\\.kMGT]+\\)$ ]]; then
            if [[ ${match[2]} = "copy" ]]; then
                items+=("${match[1]}")
            elif [[ ${match[2]} = "delete" ]]; then
                todelete+=("${match[1]}")
            elif [[ ${match[2]} = "move" ]]; then
                tomove+=("${match[1]}")
            else
                echoerr "Unreachable: expected 'copy', 'delete' or 'move' in regex result, got '${match[2]}'"
                return 5
            fi
        elif [[ $line =~ ^Transferred:[[:space:]]+0[[:space:]]/[[:space:]]0[[:space:]]Bytes,[[:space:]]-,[[:space:]]0[[:space:]]Bytes/s,[[:space:]]ETA[[:space:]]-$ ]]; then
            noitem=1
        elif [[ $line =~ ^[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9]?[0-9][[:space:]][0-9]?[0-9]:[0-9][0-9]:[0-9][0-9][[:space:]]NOTICE:[[:space:]]+(.+)$ ]]; then
            echoerr "Failed to parse line: \z[white]°$line\z[]°"
            return 5
        elif [[ $line =~ ^Transferred:[^/]+/[[:space:]]([0-9\\.]+[[:space:]][kMGTBytes]+),[[:space:]]100%, ]]; then
            size="${match[1]}"
        elif [[ $line =~ ^Transferred:[^/]+/[[:space:]]([0-9]+),[[:space:]]100%$ ]]; then
            total="${match[1]}"
        elif [[ $line =~ ^[0-9][0-9][0-9][0-9]/[0-9][0-9]/[0-9]?[0-9][[:space:]][0-9]?[0-9]:[0-9][0-9]:[0-9][0-9][[:space:]]NOTICE:[[:space:]]*$ ]]; then
        elif [[ $line =~ ^Checks:[[:space:]]+[0-9]+[[:space:]]/[[:space:]][0-9]+,[[:space:]]100%$ ]]; then
        elif [[ $line =~ ^Elapsed[[:space:]]time:[[:space:]]+[0-9\\.smhd]+$ ]]; then
        else
            printf '%s\n' "$line"
        fi
    done <<< "$rclone_list"

    if [[ $noitem -eq 0 ]]; then
        if [[ -z $size ]] && [[ -z $total ]]; then
            echoerr "Failed to get both the total transfer size and the number of items to transfer."
            return 6
        fi

        if [[ -z $size ]]; then
            echoerr "Failed to get the total transfer size."
            return 7
        fi
        
        if [[ -z $total ]]; then
            echoerr "Failed to get the total number of items to transfer."
            return 8
        fi

        if [[ ${#items} -ne $total ]]; then
            echoerr "Found \z[yellow]°${#items}\z[]°, but expected a total of \z[yellow]°$total\z[]° items to transfer!"
            return 9
        fi
    fi

    if (( ${#items} )); then
        while IFS= read -r item; do
            echoinfo "> Going to transfer: \z[magenta]°$item\z[]°"
        done <<< $(printf '%s\n' "${items[@]}" | sort -n)
    fi

    if (( ${#tomove} )); then
        while IFS= read -r item; do
            echoinfo "> Going to move from: \z[magenta]°$item\z[]°"
        done <<< $(printf '%s\n' "${tomove[@]}" | sort -n)
    fi

    if (( ${#todelete} )); then
        while IFS= read -r item; do
            echowarn "> Going to delete: \z[magenta]°$item\z[]°"
        done <<< $(printf '%s\n' "${todelete[@]}" | sort -n)
    fi

    echoinfo "Found \z[yellow]°${#items}\z[]° item(s) to transfer, \z[yellow]°${#tomove}\z[]° to move and \z[yellow]°${#todelete}\z[]° to delete for a total of \z[yellow]°$size\z[]°."

    if [[ ${#items} -eq 0 && ${#todelete} -eq 0 && ${#tomove} -eq 0 ]]; then
        echosuccess "Nothing to do."
        return
    fi

    if (( $DRY_RUN )); then
        return
    fi

    echo ""
    echo ""
    echowarn "Confirm the synchronization (Y/n)?"

    read "answer?"

    if [[ ! -z $answer && $answer != "y" && $answer != "Y" ]]; then
        return 2
    fi
    
    echoinfo "Sleeping 2 seconds before starting..."
    sleep 2

    if ! __rclone_sync_nocheck --check-first --progress "$@"; then
        return 10
    fi

    echosuccess "Successfully synchronized \z[magenta]°$1\z[]° to \z[magenta]°$2\z[]°."
}

function __rclone_sync_nocheck() {
    rclone.exe sync "$1" "$2" \
        --progress-terminal-title \
        --stats-file-name-length 0 \
        --order-by "name,mixed,75" \
        --transfers 8 \
        --filter "- System Volume Information/**" \
        --filter "- \$RECYCLE.BIN/**" \
        --create-empty-src-dirs \
        --track-renames --track-renames-strategy "leaf,size" \
        "${@:3}"
}