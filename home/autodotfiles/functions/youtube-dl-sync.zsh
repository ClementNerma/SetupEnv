export ADF_YS_URL=".ytdlsync-url"
export ADF_YS_CACHE=".ytdlsync-cache"

function ytsync() {
    if [[ -z $1 ]]; then
        if [[ ! -f $ADF_YS_URL ]]; then
            echoerr "Missing URL container file \z[yellow]°$ADF_YS_URL\z[]°"
            return 1
        fi

        local url=$(command cat "$ADF_YS_URL")
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
        return
    fi

    echoinfo "Do you want to continue (Y/n)?"

    read 'answer?'

    if [[ ! -z $answer && $answer != "y" && $answer != "Y" ]]; then
        return 2
    fi

    local errors=0

    for i in {1..${#download_list}}; do
        echoinfo "| Downloading video \z[yellow]°${i} / ${#download_list}\z[]°..."
    
        if ! ytdl "${download_list[$i]}" "$YS_ARGS"; then
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
