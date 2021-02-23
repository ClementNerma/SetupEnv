#!/usr/bin/zsh

# Function meant for internal use
# Tags a file downloaded by 'ytdlalbum' with additional metadata

if [[ ! -f "$1" ]]; then
    echo "\e[91mFile not found: \e[95m$1"
    return 1
fi

if [[ ! "$(basename "$1")" =~ ^([0-9]+)\.([0-9]+)\.(.*)$ ]]; then
    echo "\e[91mInvalid filename format: \e[95m$1"
    return 1
fi

dir=$(dirname "$1")
out_ext="${1:t:e}"

if [[ ${1:t:e} = "webm" ]]; then
    out_ext="opus"
fi

out="$dir/${match[1]}.${match[3]:t:r}.$out_ext"

echo "[ADF-Tagger] Tagging \e[95m$out\e[0m..."

ffmpeg -hide_banner -loglevel error \
    -i "$1" \
    -c:a copy \
    -metadata COMMENT="" \
    -metadata comment="" \
    -metadata DESCRIPTION="" \
    -metadata description="" \
    -metadata TRACK="$((match[1]))" \
    -metadata year="$((match[2]))" \
    -metadata YEAR="$((match[2]))" \
    -metadata date="$((match[2]))" \
    -metadata DATE="$((match[2]))" \
    "$out"

command rm "$1"