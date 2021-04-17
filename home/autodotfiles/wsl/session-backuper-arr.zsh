
# NOTE: "BSS" stands for "Backup Software Session"
typeset -A ADF_SESSION_BACKUPER_SW

export _ADF_BSS_DATA_KEYS=("process_name" "window_format" "executable" "lookup_dirs")

function _adf_bss_entries() {
    for key in ${(k)ADF_SESSION_BACKUPER_SW}; do
        if [[ $key =~ ^(.*)\/\.exists$ ]]; then
            printf "%s\n" "${match[1]}"
        fi
    done
}

function _adf_bss_has_entry() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an entry to check."
        return 1
    fi

    if [[ -z "${ADF_SESSION_BACKUPER_SW[$1/.exists]}" ]]; then
        return 2
    fi
}

function _adf_bss_has_entry_key() {
    if ! _adf_bss_has_plain_entry_key "$1" "$2" && ! _adf_bss_has_array_entry_key "$1" "$2"; then
        return 1
    fi
}

function _adf_bss_has_plain_entry_key() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an entry to check."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a data key to check."
        return 2
    fi

    if [[ -z "${ADF_SESSION_BACKUPER_SW[$1/$2/.plain]}" ]]; then
        return 9
    fi
}

function _adf_bss_has_array_entry_key() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an array entry to check."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a data key to check."
        return 2
    fi

    if [[ -z "${ADF_SESSION_BACKUPER_SW[$1/$2/.length]}" ]]; then
        return 9
    fi
}

function _adf_bss_set() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an entry to set."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a data key to set."
        return 2
    fi

    if [[ -z "$3" ]]; then
        echoerr "Please provide a value to assign."
        return 3
    fi

    if ! (( $_ADF_BSS_DATA_KEYS[(Ie)$2] )); then
        echoerr "Unknown BSS data key: \z[yellow]°$2\z[]°"
        return 4
    fi
    
    if _adf_bss_has_entry_key "$1" "$2"; then
        echoerr "BSS entry already exists: \z[yellow]°$1\z[]°\z[cyan]°/$2\z[]°"
        return 5
    fi

    ADF_SESSION_BACKUPER_SW[$1/.exists]=1
    ADF_SESSION_BACKUPER_SW[$1/$2/.plain]="$3"
}

function _adf_bss_set_array() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an array entry to set."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a data key to set."
        return 1
    fi

    if [[ -z "$3" ]]; then
        echoerr "Please provide a value to assign."
        return 2
    fi

    if ! (( $_ADF_BSS_DATA_KEYS[(Ie)$2] )); then
        echoerr "Unknown BSS data key: \z[yellow]°$2\z[]°"
        return 3
    fi

    if _adf_bss_has_entry_key "$1" "$2"; then
        echoerr "BSS entry already exists: \z[yellow]°$1\z[]°\z[cyan]°/$2\z[]°"
        return 5
    fi

    local i=0

    for value in "${@:3}"; do
        ADF_SESSION_BACKUPER_SW[$1/$2/$i]="$value"
        i=$((i+1))
    done

    ADF_SESSION_BACKUPER_SW[$1/.exists]=1
    ADF_SESSION_BACKUPER_SW[$1/$2/.length]=$i
}

function _adf_bss_get_key() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an array entry to get."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a data key to get."
        return 1
    fi

    if ! (( $_ADF_BSS_DATA_KEYS[(Ie)$2] )); then
        echoerr "Unknown BSS data key: \z[yellow]°$2\z[]°"
        return 3
    fi

    if ! _adf_bss_has_plain_entry_key "$1" "$2"; then
        echoerr "BSS plain entry does not exist: \z[yellow]°$1\z[]°\z[cyan]°/$2\z[]°"
        return 5
    fi

    printf "%s" "${ADF_SESSION_BACKUPER_SW[$1/$2/.plain]}"
}

function _adf_bss_get_array_length() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an entry to get."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a data key to get."
        return 2
    fi

    if ! (( $_ADF_BSS_DATA_KEYS[(Ie)$2] )); then
        echoerr "Unknown BSS data key: \z[yellow]°$2\z[]°"
        return 4
    fi

    if ! _adf_bss_has_array_entry_key "$1" "$2"; then
        echoerr "BSS array entry does not exist: \z[yellow]°$1\z[]°\z[cyan]°/$2\z[]°"
        return 5
    fi

    printf "%s" "${ADF_SESSION_BACKUPER_SW[$1/$2/.length]}"
}

function _adf_bss_get_array_index() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an entry to get."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a data key to get."
        return 2
    fi

    if [[ -z "$3" ]]; then
        echoerr "Please provide an index to get."
        return 3
    fi

    if ! (( $_ADF_BSS_DATA_KEYS[(Ie)$2] )); then
        echoerr "Unknown BSS data key: \z[yellow]°$2\z[]°"
        return 4
    fi

    if ! _adf_bss_has_array_entry_key "$1" "$2"; then
        echoerr "BSS array entry does not exist: \z[yellow]°$1\z[]°\z[cyan]°/$2\z[]°"
        return 5
    fi

    if [[ -z ${ADF_SESSION_BACKUPER_SW[$1/$2/$3]} ]]; then
        echoerr "Unknown BSS array index: \z[yellow]°$1\z[]°\z[cyan]°:$3\z[]°"
        return 6
    fi

    printf "%s" "${ADF_SESSION_BACKUPER_SW[$1/$2/$3]}"
}

function _adf_bss_get_array_lines() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an entry to get."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a data key to get."
        return 2
    fi

    if ! (( $_ADF_BSS_DATA_KEYS[(Ie)$2] )); then
        echoerr "Unknown BSS data key: \z[yellow]°$2\z[]°"
        return 4
    fi

    if ! _adf_bss_has_array_entry_key "$1" "$2"; then
        echoerr "BSS array entry does not exist: \z[yellow]°$1\z[]°\z[cyan]°/$2\z[]°"
        return 5
    fi

    local total=$(_adf_bss_get_array_length "$1" "$2")

    for i in {0..$((total - 1))}; do
        echo $(_adf_bss_get_array_index "$1" "$2" $i)
    done
}

function _adf_bss_delete_entry() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an entry to get."
        return 1
    fi

    if ! _adf_bss_has_entry "$1"; then
        echoerr "BSS entry does not exist: \z[yellow]°$1\z[]°"
        return 2
    fi

    for key in ${(k)ADF_SESSION_BACKUPER_SW}; do
        if [[ $key == "$1/"* ]]; then
            unset "ADF_SESSION_BACKUPER_SW[$key]"
        fi
    done
}