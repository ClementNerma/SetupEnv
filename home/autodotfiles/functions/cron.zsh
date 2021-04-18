
# Check if there is a line in the cronfile containing the provided string
function adf_cron_contains() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide a content to look for."
        return 1
    fi

	crontab -l 2> /dev/null | grep "$1" > /dev/null
}

# Add a task at the end of the cronfile
# Usage: cron_add_uq_raw <filter> <time | "-"> <command> [--head]
function adf_cron_add_uq_raw() {
    if [[ -z $1 ]]; then
        echoerr "Please provide a filter."
        return 1
    fi

    if [[ -z $2 ]]; then
        echoerr "Please provide a CRON time."
        return 2
    fi

    if [[ -z $3 ]]; then
        echoerr "Please provide a command."
        return 3
    fi

    if [[ ! -z $4 && $4 != "--head" ]]; then
        echoerr "Fourth argument must be \z[yellow]°--head\z[]° or empty."
        return 4
    fi

    if [[ ! $3 == *"$1"* ]]; then
        echoerr "Filter does not cover the command."
        return 4
    fi

    if adf_cron_contains "$1"; then
        echoverb "Ignoring CRON line with filter \z[yellow]°$2\z[]° as it already exists."
        return
    fi

    local line="$3"

    if [[ $2 != "-" ]]; then
        line="$2 $3"
    fi

    if [[ $4 != "--head" ]]; then
    	(crontab -l 2> /dev/null; echo "$line") | crontab
    else
        (echo "$line"; crontab -l 2> /dev/null) | crontab
    fi
}

# Add a task to run inside ADF at the end of the cronfile
# Usage: cron_add_uq_raw <task slug> <time> <command> [--head]
function adf_cron_add_uq() {
    adf_cron_add_uq_raw "adf_cron_logged '$1'" "$2" "zsh '$ADF_ENTRYPOINT' --just-run adf_cron_logged '$1' $3" $4

    local ret=$? ; if (( $ret )); then return $ret; fi
}

# Run a command from inside a CRON task
function adf_cron_logged() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide a CRON task slug."
        return 1
    fi

    if [[ -z "$2" ]]; then
        echoerr "Please provide a command to run."
        return 2
    fi

    _adf_cron_logged "$@" >> "$ADF_CONF_CRON_LOGS_DIR/$1.log" 2>&1

    local ret=$? ; if (( $ret )); then return $ret; fi
}

function _adf_cron_logged() {
    echoinfo "[ADF:CRON] Running task \z[yellow]°$1\z[]° at \z[magenta]°$(humandate)\z[]°..."

    "${@:2}"

    local ret=$?

    local exitcodemsg="command ended successfully (exit code 0)"

    if (( $ret )); then
        exitcodemsg="\z[red]°command failed with exit code \z[yellow]°$ret\z[]°\z[]°"
    fi

    echoinfo "[ADF:CRON] Finished running task \z[yellow]°$1\z[]° at \z[magenta]°$(humandate)\z[]°, $exitcodemsg."
    echoinfo " "
    echoinfo " "

    if (( $ret )); then return $ret; fi
}

# Read the logs of a specific CRON task
function adf_cron_logs() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide a task slug to read the logs from. Available ones:"

        for file in "$ADF_CONF_CRON_LOGS_DIR/"*(N); do
            echoinfo "* \z[yellow]°${$(basename "$file")/.log/}\z[]°"
        done

        return 1
    fi

    local logsfile="$ADF_CONF_CRON_LOGS_DIR/$1.log"

    if [[ ! -f "$logsfile" ]]; then
        echoerr "This task slug doesn't exist or it does not have a log file yet."
        return 2
    fi

    cat "$logsfile"
}

if [[ ! -d "$ADF_CONF_CRON_LOGS_DIR" ]]; then
    mkdir -p "$ADF_CONF_CRON_LOGS_DIR"
fi