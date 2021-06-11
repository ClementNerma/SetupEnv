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
        
        echowarn "Writing provided URL to local directory file."
        if [[ -f $ADF_YS_URL ]]; then rm "$ADF_YS_URL"; fi
        echo "$url" > "$ADF_YS_URL"
    fi

    echoinfo "Downloading videos list from playlist URL \z[magenta]°$url\z[]°..."

    if [[ -f $ADF_YS_CACHE ]]; then
        local read_from_cache=1
        echoinfo "Retrieving videos list from cache file."
        local json=$(command cat "$ADF_YS_CACHE")
    else
        local read_from_cache=0
        local started=$(timer_start)
        local json=$(youtube-dl -J -i "$url" "${@:2}" 2>/dev/null)
        echoinfo "Videos list was retrieved in \z[yellow]°$(timer_end $started)\z[]°."
    fi

    echoinfo "Checking JSON output..."

    local count=$(echo -E "$json" | jq '.entries | length')

    echo -E "$json" > $ADF_YS_CACHE
    echoinfo "Written JSON output to the cache file."

    echoinfo "${count} videos were found.\n"

    local download_list=()

    for i in {1..$count}; do
        local index=$((i-1))
        local videoid=$(echo -E "$json" | jq ".entries[$index].id" -r)

        if [[ $videoid = "null" ]]; then
            continue
        fi

        if [[ -z $(find . -name "*-$videoid.*") ]]; then
            local title=$(echo -E "$json" | jq ".entries[$index].title" -r)
            local uploaded=$(echo -E "$json" | jq ".entries[$index].upload_date" -r | sed -E "s/([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9])/\3\/\2\/\1/")
            echoinfo "\z[magenta]°[$videoid]\z[]° \z[cyan]°$uploaded\z[]° \z[yellow]°${title}\z[]°"
            download_list+=($(echo -E "$json" | jq ".entries[$index].webpage_url" -r))
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

        if ! ytdl ${download_list[$i]}; then
            errors=$((errors+1))
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
