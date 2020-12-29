
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