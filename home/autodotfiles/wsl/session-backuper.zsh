
# Backup the session
# Works by enumerating the windows of the said softwares' processes, and filtering them through PowerShell and ZSH
function adf_backup_session() {
    local outdir="$ADF_CONF_WSL_BACKUP_SESSION_DIR/$(humandate)"
    mkdir -p "$outdir"

    # Iterate over all software profiles
    for software in $( _adf_bss_entries ); do
        adf_backup_software_session "$outdir" "$software" "$(_adf_bss_get_key "$software" "process_name")" "$(_adf_bss_get_key "$software" "window_format")"
    done

    # Ignore empty values
    if [[ -z "$(command ls -A "$outdir")" ]]; then
      echosuccess "Nothing to backup!"
      command rmdir "$outdir"
      return
    fi

    # Prepare the final directory
    # In case of fail above, the final directoy will simply not have a checksum, but will remain on the disk
    local finaldir="$outdir-$(cksumdir "$outdir")"
    mv "$outdir" "$finaldir"

    # Output the backup directory
    echo -n "$finaldir"
}

# Backup a software's session
# Works by listing the windows from the provided process name using PowerShell
# Arguments: <output directory> <slug> <process name> <matching regex>
function adf_backup_software_session() {
    # Get the list of windows for the provided process
    local windows="$(process_windows "$3")"

    if [[ -z $windows ]]; then
        echoinfo "> Nothing to backup for software \z[cyan]°$3\z[]°"
        return
    fi

    # 000d = '\r'
    if [[ ${#windows} = 1 && $(printf '%04x\n' \'$windows[1]) = "000d" ]]; then
        echowarn "NOTE: No window found for software \z[cyan]°$3\z[]°."
        return
    fi

    # Iterate over the list of windows
    while IFS= read -r window; do
        # Ignore empty lines
    	if [[ ${#window} = 1 && $(printf '%04x\n' \'$window[1]) = "000d" ]]; then continue; fi

        # Ensure the window's format match the provided one
        # Note that accents may cause regex even like (.*) to fail
        if [[ ! $window =~ $4 ]]; then
            echowarn "WARNING: Invalid window format for software \z[cyan]°$3\z[]°: \z[magenta]°$window\z[]°"
            echo "##INVALID##:$window" >> "$1/$2.txt"
        else
	        echo "${match[1]}" >> "$1/$2.txt"
        fi
    done <<< "$windows"
}

# Compile the backup data in a compressed archive to take less space
# This is the only file that will be taken during backups
function adf_backup_session_compile() {
    if [[ -f "$ADF_CONF_WSL_BACKUP_SESSION_COMPILATION" ]]; then
        echowarn "Removing previous compilation archive..."
        rm "$ADF_CONF_WSL_BACKUP_SESSION_COMPILATION"
    fi

    echoinfo "Compiling session backups..."

    if (( $ADF_BACKUP_NO_COMPRESS )); then
        echowarn "Creating a NON-COMPRESSED archive."
        7z a -t7z -m0=Copy -mmt=1 -spf2 -bso0 "$ADF_CONF_WSL_BACKUP_SESSION_COMPILATION" "$ADF_CONF_WSL_BACKUP_SESSION_DIR" "-x!$(basename "$file")"
    else
        7z a -t7z -m0=lzma2 -mx=5 -mfb=64 -md=32m -ms=on -mhc=on -mhe=on -spf2 -bso0 "$ADF_CONF_WSL_BACKUP_SESSION_COMPILATION" "$ADF_CONF_WSL_BACKUP_SESSION_DIR" "-x!$(basename "$file")"
    fi

    if (( $? )); then
        echoerr "7-Zip failed (see error above)"
        return 1
    fi

    echosuccess "Done!"
}

# Restore the last session backed up with `backup_session`
# Previous backups can be restored by providing their checksum through the `CKSUM` variable
# Usage: restore_session [<software name>]
function adf_restore_session() {
    local filter=""

    if [[ ! -z "$CKSUM" ]]; then
      filter="\-$CKSUM$"
    fi

    # Get the last backup's directory name, taking into account the provided filter (if any)
    local last_backup=$(
        # List all items in the session backup directory
        command ls -1A "$ADF_CONF_WSL_BACKUP_SESSION_DIR" |

        # Apply the provided filter (will have no effect if the filter is empty)
        grep "$filter" |

        # Exclude files based on if the item's name as an extension or not
        # Simplest method as we only have a name and not an absolute path,
        # and 'ls' does not allow listing only directories
        grep -v "\..*" |

        # Sort by name - as the directories' names start with a fixed-length timestamp, this will sort the directories by ascending date
        sort |

        # Get the last item, which means the most recent backup
        tail -n1
    )

    echoinfo "Restoring session from directory: \z[yellow]°$last_backup\z[]°..."

    # Look for failures
    local failed=0

    # Iterate over the list of software to restore
    for list_file in "$ADF_CONF_WSL_BACKUP_SESSION_DIR/$last_backup/"*; do
        # Only restore the provided software, if any
		if [[ ! -z "$1" && "$(basename "$list_file")" != "$1.txt" ]]; then
		    echowarn "> Skipping software file \z[magenta]°$(basename "$list_file")\z[]° as asked."
		    continue
		fi

        local filename="$(basename "$list_file")"

        if [[ ! $filename =~ ^(.*)\.txt$ ]]; then
            echoerr "Unknown session software file: \z[yellow]°$list_file\z[]°"
            failed=1
            continue
        fi

        local software="${match[1]}"

        echoinfo "> Restoring program session for software \z[cyan]°$software\z[]°..."

        # (Try to) restore this software's session
        
        if ! _adf_bss_has_entry "$software"; then
            echoerr "Unknown software \z[cyan]°$software\z[]°"
            failed=1
            continue
        fi

        adf_restore_session_softlist "$software" "$list_file" "$(_adf_bss_get_key "$software" "executable")" $(_adf_bss_get_array_lines "$software" "lookup_dirs")
    done

    # End
    if (( $failed )); then
        echoerr "Some errors occurred, please look at output above."
        return 1
    else
        echosuccess "Done."
    fi
}

# Restore a software's session from a list of items
# Arguments: <software name> <list file> <executable path> <...lookup directories>
function adf_restore_session_softlist() {
    # Solve PowerShell-related encoding problems (CRLF)
    local files=$(dos2unix < "$2")

    # List of found files to open (see reason below)
    local toopen=()

    # Number of failures
    local failed=0

    # Pre-formatted software file name
    local software_brackets="\z[cyan]°[$1]\z[]°"

    # Iterate over the list of items to restore
    while IFS=$'\n' read -r file; do
        # Trim the file's name
        local trimmed_file="$(echo "$file" | sed 's/ *$//g')"

        # Handle items tagged as invalids
        if [[ $trimmed_file = "##INVALID##:"* ]]; then
        	echoerrnp ">> Software $software_brackets: invalid item found in backup: \z[yellow]°${trimmed_file:12}\z[]°"
        	failed=$((failed+1))
        	continue
    	fi

        # Find the item to open
        local item=$(adf_find_session_item "$trimmed_file" "${@:4}")

        # If the item is not found, increase the failures counter
        if [[ -z "$item" ]]; then
            failed=$((failed+1))
        else
            # Else, open it
	    	echoinfo ">> Software $software_brackets: found \z[yellow]°$item\z[]°"

            if [[ -z "$RESTORATION_DRY_RUN" ]]; then
                toopen+=("$(wslpath -w "$item")")
            fi
        fi
    done <<< "$files"

    # HACK: Launching the software pieces directly in the loop above would make it break
    #       This is a known bug amongst most shells
    local opened=0

    for item in ${toopen[@]}; do
		(nohup "$3" "$item" > /dev/null 2>&1 &)
		opened=$((opened+1))
    done

    # Ensure all files to restore have been successfully opened
    if [[ $opened != ${#toopen} ]]; then
		echoerr "Only \z[yellow]°$opened\z[]° files were successfully opened ; \z[yellow]°${#toopen}\z[]° were expected."
		return 1
    fi

    if (( $failed > 0 )); then
    	return 2
	fi
}

# Find an item in a list of session-related directories
# Usage: adf_find_session_item <item name to find> <directories to look in...>
function adf_find_session_item() {
    if [[ -z "$2" ]]; then
        echoerr "Please provide search directories."
        return 1
    fi

    # Iterate over the list of lookup directories
    for dir in "${@:2}"; do
        # Assertion to avoid problems if the provided directory does not exist
        if [[ ! -d "$dir" ]]; then
            echoerr "Search directory not found: \z[yellow]°$dir\z[]°"
            return 2
        fi

        # Iterate over the recursive items list from the provided directory
		while IFS=$'\n' read -r candidate; do
            # If an item exists with the filename we're looking for...
		    if [[ -f "$candidate/$1" || -d "$candidate/$1" ]]; then
                # Success, display it and return
                echo -n "$candidate/$1"
                return
            fi
		done <<< $(find "$dir" -type d | sort)
    done

    # If it was not found in the loop above, we can't do much more
    echoerr "File not found: \z[yellow]°$1\z[]°"
    return 3
}

# Run "restore_session" but only search and display the list of files without actually restoring anything
# Made for debug purposes
function adf_dry_restore_session() {
    RESTORATION_DRY_RUN=1 adf_restore_session "$@"
}

# Register a software to backup
# Arguments: <slug> <process name> <window format> <executable path> <lookup directories (array)>
function adf_register_session_backup() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide a slug (will be used in backups' filenames)."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a process name."
        return 2
    fi

    if [[ -z "$3" ]]; then
        echoerr "Please provide a window format."
        return 3
    fi

    if [[ -z "$4" ]]; then
        echoerr "Please provide an executable path."
        return 4
    fi

    if [[ -z "$5" ]]; then
        echoerr "Please provide at least one lookup directory."
        return 5
    fi

    # Checkings
    if _adf_bss_has_entry "$1"; then
        if ! (( $ADF_DISABLE_BSS_OVERRIDING_WARNING )); then
            echowarn "WARNING: Overriding session backup profile for software: \z[cyan]°$1\z[]°"
        fi

        _adf_bss_delete_entry "$1"
    fi

    if [[ ! -f "$4" ]]; then
        echoerr "Provided software path was not found at path: \z[yellow]°$3\z[]°"
        return 7
    fi

    for lookup_dir in ${@:5}; do
        if [[ ! -d "$lookup_dir" ]]; then
            echoerr "Lookup directory not found for software \z[cyan]°$1\z[]° at path \z[yellow]°$lookup_dir\z[]°"
            return 8
        fi
    done

    _adf_bss_set "$1" "process_name" "$2"
    _adf_bss_set "$1" "window_format" "$3"
    _adf_bss_set "$1" "executable" "$4"
    _adf_bss_set_array "$1" "lookup_dirs" "${@:5}"
}

# Load the array manager
source "$ADF_ENV_DIR/session-backuper-arr.zsh"
