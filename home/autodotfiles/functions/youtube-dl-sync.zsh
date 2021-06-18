export ADF_YS_URL=".ytdlsync-url"
export ADF_YS_CACHE=".ytdlsync-cache"

function ytsync() {
    if [[ -z $1 ]]; then
        if [[ ! -f $ADF_YS_URL ]]; then
            echoerr "Missing URL container file \z[yellow]°$ADF_YS_URL\z[]°"
            return 1
        fi

        local url=$(command cat "$ADF_YS_URL")
    elif [[ -f $ADF_YS_URL ]]; then
        echoerr "An URL was provided but an URL file already exists."
        return 1
    else
        local url="$1"
        shift
        
        echowarn "Writing provided URL to local directory file."
        if [[ -f $ADF_YS_URL ]]; then rm "$ADF_YS_URL"; fi
        echo "$url" > "$ADF_YS_URL"
    fi

    if [[ -f $ADF_YS_CACHE ]]; then
        local read_from_cache=1
        echoinfo "Retrieving videos list from cache file."
        local json=$(command cat "$ADF_YS_CACHE")
    else
        local read_from_cache=0
        
        echoinfo "Counting videos from playlist URL \z[magenta]°$url\z[]°..."

        local count=$(
            youtube-dl "$url" --flat-playlist |
            grep "Downloading video" |
            tail -n1 |
            sed -E "s/\[download\] Downloading video ([0-9]+) of ([0-9]+)/\2/"
        )

        if [[ -z "$count" ]]; then
            echoerr "Got empty count (did the retrieval failed?)"
            return 2
        fi

        echoinfo "Total count of videos is estimated at \z[yellow]°$count\z[]°."
        echoinfo "Downloading videos list from playlist URL \z[magenta]°$url\z[]°..."

        local started=$(timer_start)
        local json=$(youtube-dl -J --get-filename -i "$url" "${@:2}" 2>/dev/null | pv -l -W -s "$((count+1))" | tail -n1)
        
        echoinfo "Videos list was retrieved in \z[yellow]°$(timer_end $started)\z[]°."

        echoinfo "Checking and mapping JSON..."

        local json=$(echo -E "$json" | jq -c '[.entries[] | {id, title, upload_date, webpage_url}]')

        echoinfo "JSON is ready."
    fi

    echoinfo "Checking JSON data..."

    local count=$(echo -E "$json" | jq 'length')

    echo -E "$json" > $ADF_YS_CACHE
    echoinfo "Written JSON output to the cache file."

    echoinfo "${count} videos were found.\n"

    local empty_dir=0

    if [[ -z $(find . -not -name '.*') ]]; then
        empty_dir=1
    fi

    local download_list=()
    
    local max_spaces=$(echo -n "$count" | wc -c)

    for i in {1..$count}; do
        local index=$((i-1))
        local videojson=$(echo -E "$json" | jq ".[$index]")

        local videoid=$(echo -E "$videojson" | jq ".id" -r)

        if [[ $videoid = "null" ]]; then
            continue
        fi

        local current=$(printf "%${max_spaces}s" $i)

        if (( $empty_dir )) || [[ -z $(find . -name "*-$videoid.*") ]]; then
            local title=$(echo -E "$videojson" | jq ".title" -r)
            local uploaded=$(echo -E "$videojson" | jq ".upload_date" -r | sed -E "s/([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])/\3\/\2\/\1/")
            echoinfo "\z[gray]°$current / $count\z[]° \z[magenta]°[$videoid]\z[]° \z[cyan]°$uploaded\z[]° \z[yellow]°${title}\z[]°"
            download_list+=($(echo -E "$videojson" | jq ".webpage_url" -r))
        fi
    done

    echoinfo "\nGoing to download \z[yellow]°${#download_list}\z[]° videos."

    if (( $read_from_cache )); then
        echowarn "Video list was retrieved from a cache file."
    fi

    if ! (( ${#download_list} )); then
        echosuccess "No video to download!"
        rm "$ADF_YS_CACHE"
        return
    fi

    echoinfo "Do you want to continue (Y/n)?"

    read 'answer?'

    if [[ ! -z $answer && $answer != "y" && $answer != "Y" ]]; then
        return 2
    fi

    local errors=0
    local bandwidth_limit="$ADF_YTDL_SYNC_LIMIT_BANDWIDTH"

    if (( $SLOWSYNC )); then
        bandwidth_limit="2M"
    fi

    for i in {1..${#download_list}}; do
        echoinfo "| Downloading video \z[yellow]°${i}\z[]° / \z[yellow]°${#download_list}\z[]°: \z[magenta]°${download_list[$i]}\z[]°..."
    
        if ! YTDL_ALWAYS_THUMB=1 YTDL_LIMIT_BANDWIDTH="$ADF_YTDL_SYNC_LIMIT_BANDWIDTH" ytdl "${download_list[$i]}"; then
            errors=$((errors+1))
            echowarn "Waiting 5 seconds before next video..."
            sleep 5
        fi
    done

    if [[ $errors -eq 0 ]]; then
        echosuccess "Done!"
        rm "$ADF_YS_CACHE"
    else
        echoerr "Failed to download \z[yellow]°$errors\z[]° video(s)."
        return 5
    fi
}

# Look for videos that have a resolution lower than 1920x1080 pixels, and re-download them
# This function exists because the 'ytdl' function previously used the 'bestvideo+bestaudio/best' preset of Youtube-DL,
#  which doesn't always get the best quality unfortunately (only the highest bitrate, which is sometimes not the best resolution nor picture quality).
# By re-downloading these files, they keep the same filename and creation date, but in higher quality if they are still available.
function ytrepairres() {
    local loc="."

    if ! (( $YTDL_REPAIR_SIMULATE )) && [[ -z "$1" ]]; then
        echoerr "Please provide a download URL prefix."
        return 1
    fi

    if [[ ! -z "$2" ]]; then
        if [[ ! -d "$2" ]]; then
            echoerr "Provided path is not a directory."
            return 2
        fi

        loc="$2"
    fi

    local total=0
    local success=0
    local errors=0

    local prev_cwd=$(pwd)

    cd "$loc"
    
    for entry in *; do
        echoverb "Analyzing: $entry..."

        if [[ -d "$entry" ]]; then
            YTDL_REPAIR_SUBROUTINE=1 ytrepairres "$1" "$entry"
            continue
        fi

        total=$((total+1))

        local width=""
        
        if ! width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=s=x:p=0 "$entry"); then
            echoerr "Failed to get resolution for invalid video file \z[magenta]°$(basename "$entry")\z[]°."
            errors=$((errors+1))
            continue
        fi

        if (( $width < 1920 )); then
            if [[ $entry =~ ^[^\/]+\-([a-zA-Z0-9_\-]+)\.([^\.]+)$ ]]; then
                local url="$1${match[1]}"

                echoverb "Checking formats for $url..."

                if ! (youtube-dl -F "$url" | grep "1920x1080" > /dev/null); then
                    continue
                fi

                echoinfo "Previous file size: \z[yellow]°$(filesize "$entry")\z[]° for \z[magenta]°$(basename "$entry")\z[]°."
                echoinfo "URL: \z[gray]°$url\z[]°"

                if ! (( $YTDL_REPAIR_SIMULATE )) && ! YTDL_LIMIT_BANDWIDTH="$ADF_YTDL_SYNC_LIMIT_BANDWIDTH" ytdl "$url"; then
                    errors=$((errors+1))
                    echoerr "Failed to download video. Waiting 3 seconds now."
                    sleep 3
                else
                    echoinfo "New file size: \z[yellow]°$(filesize "$entry")\z[]° for \z[magenta]°$(basename "$entry")\z[]°."
                    echoinfo "------------------------------------------------------------------------------------------------"
                    success=$((success+1))
                fi
            else
                errors=$((errors+1))
                echoerr "Failed to match: $entry"
            fi
        fi
    done

    cd "$prev_cwd"

    if (( $YTDL_REPAIR_SUBROUTINE )); then
        return
    fi

    if (( $errors )); then
        echoerr "Failed with \z[yellow]°$errors\z[]° error(s)."
        return 9
    else
        echosuccess "Successfully downloaded in higher quality \z[yellow]°$success\z[]° videos (out of $total)!"
    fi
}
