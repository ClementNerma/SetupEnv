
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

function echoc() {
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
        if [[ $color = $substr ]] || [[ ! -z $color && -z ${(P)format_test_varname} ]]; then
            output="${output}${text[$i]}"
            continue
        fi

        local add_color=""

        if [[ -z $color ]]; then
            if [[ ${#colors_history[@]} = 0 ]]; then
                echo "${ADF_FORMAT_RED}echoc: Cannot close a color as no one is opened!${ADF_FORMAT_RESET}"
                echo "${ADF_FORMAT_RED}> In: $text${ADF_FORMAT_RESET}"
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
        echo "${ADF_FORMAT_RED}echoc: Unterminated color groups: $colors_history${ADF_FORMAT_RESET}"
        return 1
    fi

    echo "$output"
}

function echoerr() {
    echoc "\z[red]°ERROR: $@\z[]°"
}

function echosuccess() {
    echoc "\z[green]°$@\z[]°"
}

function echoinfo() {
    echoc "\z[blue]°$@\z[]°"
}

function echowarn() {
	echoc "\z[yellow]°$@\z[]°"
}

function echodata() {
	echoc "\z[cyan]°$@\z[]°"
}