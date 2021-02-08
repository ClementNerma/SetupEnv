
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
function dlren() { wget -q --show-progress -O "$2" "$1" }
function sudodlren() { sudo wget -q --show-progress -O "$2" "$1" }

# Arguments: "<url>"
function dl() { wget -qi - --show-progress -O "$1" }
function sudodl() { sudo wget -qi - --show-progress -O "$1" }

# Arguments: "<repo author>/<reponame>" "<file grep pattern>" "<download location>"
function dlghrelease() {
    curl -s "https://api.github.com/repos/$1/releases/latest" \
        | grep "browser_download_url.*$2" \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | dli "$3"
}
