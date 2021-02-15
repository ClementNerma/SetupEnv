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

tmp_file="${1:t:r}.tmp.${1:t:e}"

echo "[ADF-Tagger] Tagging \e[95m$1\e[0m..."
ffmpeg -i "$1" -c copy -metadata TRACK="${match[1]}" "$tmp_file" -hide_banner -loglevel error
command rm "$1"
mv "$tmp_file" "$1"

unset tmp_file