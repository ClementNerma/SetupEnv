#!/usr/bin/zsh

# Function meant for internal use
# Tags a file downloaded by 'ytdlalbum' with additional metadata

write_id4cover=1

if [[ $1 = "--no-id4cover" ]]; then
    write_id4cover=0
    shift
fi

if [[ ! -f "$1" ]]; then
    echo "\e[91mFile not found: \e[95m$1"
    return 1
fi

if [[ ! "$(basename "$1")" =~ ^([0-9]+)\.([0-9NA]+)\.([a-zA-Z0-9_\-]+)\.(.*)$ ]]; then
    echo "\e[91mInvalid filename format: \e[95m$1"
    return 1
fi

dir=$(dirname "$1")
out_ext="${1:t:e}"

if [[ ${1:t:e} = "webm" ]]; then
    out_ext="opus"
fi

out="$dir/${match[1]}.${match[4]:t:r}.$out_ext"

if [[ ${match[2]} != "NA" ]]; then
    year="${match[2]}"
else
    year=""
fi

echo "[ADF-Tagger] Tagging \e[95m$out\e[0m..."

ffmpeg -hide_banner -loglevel error \
    -i "$1" \
    -c:a copy \
    -metadata COMMENT="" \
    -metadata comment="" \
    -metadata DESCRIPTION="" \
    -metadata description="" \
    -metadata TRACK="$((match[1]))" \
    -metadata year="$year" \
    -metadata YEAR="$year" \
    -metadata date="$year" \
    -metadata DATE="$year" \
    "$out"

if (( $write_id4cover )) && [[ ! -f "$dir/__id4cover.txt" ]]; then
    echo "${match[3]}" > "$dir/__id4cover.txt"
fi

command rm "$1"