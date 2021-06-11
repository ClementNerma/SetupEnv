export YTDL_SYNC_URL_CONTAINER_FILENAME=".ytdlsync-url"
export YTDL_SYNC_CACHE_FILENAME=".ytdlsync-cache"

function ytdlsync() {
    if [[ -z $1 ]]; then
        if [[ ! -f $YTDL_SYNC_URL_CONTAINER_FILENAME ]]; then
            echoerr "Missing URL container file \z[yellow]°$YTDL_SYNC_URL_CONTAINER_FILENAME\z[]°"
            return 1
        fi

        local url=$(command cat "$YTDL_SYNC_URL_CONTAINER_FILENAME")
    else
        local url="$1"
    fi

    echoinfo "Downloading videos list from playlist URL \z[magenta]°$url\z[]°..."

    if (( $YTDL_SYNC_CACHE )) && [[ -f $YTDL_SYNC_CACHE_FILENAME ]]; then
        echoinfo "Retrieving videos list from cache file."
        local json=$(command cat "$YTDL_SYNC_CACHE_FILENAME")
    else
        local json=$(youtube-dl -J -i "$url" "${@:2}" 2>/dev/null)
    fi

    echoinfo "Checking JSON output..."

    local count=$(echo -E "$json" | jq '.entries | length')

    if (( $YTDL_SYNC_CACHE )); then
        echo -E "$json" > $YTDL_SYNC_CACHE_FILENAME
        echoinfo "Written JSON output to the cache file."
    fi

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
        
        if [[ -f $YTDL_SYNC_CACHE_FILENAME ]]; then
            command rm "$YTDL_SYNC_CACHE_FILENAME"
        fi
    else
        echoerr "Failed to download \z[yellow]°$errors\z[]° video(s)."
        return 5
    fi
}