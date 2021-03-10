
# Prefix used by all formatting variables
export ADF_PREFIX_FORMAT="ADF_FORMAT_"

export ADF_FORMAT_RESET="\e[0m"
export ADF_FORMAT_GRAY="\e[90m"
export ADF_FORMAT_RED="\e[91m"
export ADF_FORMAT_GREEN="\e[92m"
export ADF_FORMAT_YELLOW="\e[93m"
export ADF_FORMAT_BLUE="\e[94m"
export ADF_FORMAT_MAGENTA="\e[95m"
export ADF_FORMAT_CYAN="\e[96m"
export ADF_FORMAT_WHITE="\e[97m"

function _report_echoc_error() {
    local cursor=""

    for i in {1..$(($3-1))}; do
        cursor="$cursor "
    done

    local carets=""

    for i in {1..$4}; do
        carets="$carets^"
    done

    cursor="$cursor${ADF_FORMAT_BLUE}$carets${ADF_FORMAT_RESET}"

    >&2 echo "${ADF_FORMAT_RED}====================== echoc error ======================${ADF_FORMAT_RESET}"
    >&2 echo "${ADF_FORMAT_RED}| $1${ADF_FORMAT_RESET}"
    >&2 echo "${ADF_FORMAT_RED}|${ADF_FORMAT_RESET}"
    >&2 echo "${ADF_FORMAT_RED}| In: ${ADF_FORMAT_YELLOW}${2:0:$3-1}${ADF_FORMAT_BLUE}${2:$3:$4}${ADF_FORMAT_YELLOW}${2:$3+$4}${ADF_FORMAT_RESET}"
    >&2 echo "${ADF_FORMAT_RED}|     $cursor"
    >&2 echo "${ADF_FORMAT_RED}=========================================================${ADF_FORMAT_RESET}"
}

function echoc() {
    if (( $ADF_FULLY_SILENT )); then
        return
    fi

    local text="$@"
    local output=""
    local colors_history=()
    local i=-1

    while (( i < ${#text} )); do
        i=$((i+1))

        if [[ $text[$i,$i+2] != "\z[" ]]; then
            output="${output}${text[$i]}"
            continue
        fi

        local substr="${text[$i+3,-1]}"

        local look="]°"
        local color="${substr%%$look*}"

        local format_test_varname="$ADF_PREFIX_FORMAT${color:u}"
        if [[ $color = $substr ]]; then
            output="${output}${text[$i]}"
            continue
        fi

        local segment_len=$((${#color}+5))

        if [[ ! -z $color && -z ${(P)format_test_varname} ]]; then
            _report_echoc_error "Unknown color ${ADF_FORMAT_YELLOW}$color" "$text" $((i-1)) $segment_len
            return 1
        fi

        local add_color=""

        if [[ -z $color ]]; then
            if [[ ${#colors_history[@]} = 0 ]]; then
                _report_echoc_error "Cannot close a color as no one is opened" "$text" $((i-1)) $segment_len
                return 1
            fi

            shift -p colors_history

            add_color="${colors_history[-1]:-reset}"
        else
            colors_history+=("$color")
            add_color="$color"
        fi

        local format_varname="$ADF_PREFIX_FORMAT${add_color:u}"
        output="${output}${(P)format_varname}"
        i=$((i+4+${#color}))
    done

    if [[ ${#colors_history[@]} != 0 ]]; then
        _report_echoc_error "Unterminated color groups: $colors_history" "$text" ${#text} 1
        return 1
    fi

    if (( $ADF_DISPLAY_TO_STDERR )); then
        >&2 echo "$output"
    else
        echo "$output"
    fi
}

function echoerr() {
    ADF_DISPLAY_TO_STDERR=1 echoc "\z[red]°ERROR: $@\z[]°"
}

function echowarn() {
	ADF_DISPLAY_TO_STDERR=1 echoc "\z[yellow]°$@\z[]°"
}

function echosuccess() {
    if (( $ADF_SILENT )); then
        return
    fi

    echoc "\z[green]°$@\z[]°"
}

function echoinfo() {
    if (( $ADF_SILENT )); then
        return
    fi

    echoc "\z[blue]°$@\z[]°"
}

function echodata() {
    if (( $ADF_SILENT )); then
        return
    fi

	echoc "\z[cyan]°$@\z[]°"
}

function echoverb() {
    if ! (( $ADF_VERBOSE )); then
        return
    fi

	echoc "\z[gray]°[Verbose]\z[]° \z[magenta]°$@\z[]°"
}