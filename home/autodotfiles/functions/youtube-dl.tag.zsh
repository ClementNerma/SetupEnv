#!/usr/bin/zsh

# Function meant for internal use
# Tags a file downloaded by 'ytdlalbum' with additional metadata

if [[ ! -f "$1" ]]; then
    echo "\e[91mFile not found: \e[95m$1"
    return 1
fi

if [[ ! "$(basename "$1")" =~ ^([0-9]+)\. ]]; then
    echo "\e[91mInvalid filename format: \e[95m$1"
    return 1
fi

audio_file="$1"

if [[ ${1:t:e} = "webm" ]]; then
    audio_file="$(dirname "$1")/${1:t:r}.oga"
    ffmpeg -hide_banner -loglevel warning -i "$1" -vn -c:a copy "$audio_file"
    rm "$1"
fi

tmp_file="${1:t:r}.tmp.${audio_file:t:e}"

echo "[ADF-Tagger] Tagging \e[95m$(basename "$audio_file")\e[0m..."
ffmpeg -i "$audio_file" -c copy -metadata TRACK="${match[1]}" "$tmp_file" -hide_banner -loglevel error

command rm "$audio_file"
mv "$tmp_file" "$audio_file"

unset audio_file
unset tmp_file