
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

# Arguments: "<repo author>/<reponame>" "<file grep pattern>" "<download location>"
function dlghrelease() {
    curl -s "https://api.github.com/repos/$1/releases/latest" \
        | grep "browser_download_url.*$2" \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | wget -qi - --show-progress -O "$3"
}
