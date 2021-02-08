
function echocolored() {
    printf "$1"
    shift
    while IFS= read -r line ; do echo $line; done <<< "$@"
    printf "\e[0m"
}

function echoerr() {
    echocolored "\e[91mERROR: " "$@"
}

function echosuccess() {
    echocolored "\e[92m" "$@"
}

function echoinfo() {
    echocolored "\e[93m" "$@"
}

# Arguments: "<url>" "<download location>"
function dl() {
    local url="$1"
    local outpath="$2"
    shift

    if [[ ! -z "$outpath" ]]; then
        shift
        wget -q --show-progress -O "$outpath" "$url" "$@"
    else
        wget -q --show-progress "$url" "$@"
    fi
}

function sudodl() {
    local url="$1"
    local outpath="$2"
    shift

    if [[ ! -z "$outpath" ]]; then
        shift
        sudo wget -q --show-progress -O "$outpath" "$url" "$@"
    else
        sudo wget -q --show-progress "$url" "$@"
    fi
}

# Arguments: "<download location>"
function dli() { wget -qi - --show-progress -O "$1" }
function sudodli() { sudo wget -qi - --show-progress -O "$1" }

# Arguments: "<repo author>/<reponame>" "<file grep pattern>" "<download location>"
function dlghrelease() {
    curl -s "https://api.github.com/repos/$1/releases/latest" \
        | grep "browser_download_url.*$2" \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | dli "$3"
}
