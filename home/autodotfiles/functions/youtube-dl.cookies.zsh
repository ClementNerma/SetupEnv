function ytdlcookies() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an action to perform ('help' to get some help)."
        return 1
    fi

    case "$1" in
        help)
            echoinfo "1. Go to: \z[magenta]°Chrome's Application -> Storage -> Cookies -> [domain] table\z[]°"
            echoinfo "2. Copy it (Ctrl+C)"
            echoinfo "3. Run 'ytdlcookies create <your preset name>'"
            echoinfo "4. Paste the copied table (Ctrl+V) in the editor"
            echoinfo "5. Save and exit (Ctrl+S & Ctrl+X)"
            echoinfo "6. Use it with 'ytdlcookies use <your preset name> <ytdl arguments>"
            echoinfo
            echodata "A. Renew expired cookies with 'ytdlcookies renew <your preset name>' (then steps from 4.)"
            echodata "B. Delete a preset with 'ytdlcookies rm <your preset name>"
            echodata "C. List all existing presets with 'ytdlcookies list'"
            return 99
            ;;

        list)
            command ls -1A "$ADF_YTDL_COOKIES_PRESETS_DIR"
            return
            ;;
    esac
    
    local preset_name="$2"
    local preset_path="$ADF_YTDL_COOKIES_PRESETS_DIR/$preset_name"
    local raw_cookies_path="$preset_path/raw-cookies.txt"
    local converted_cookies_path="$preset_path/formatted-cookies.txt"

    local nodejs_script="const SHELL_INJECTED_FILENAME=\"$raw_cookies_path\"; $(cat <<END
/**
 * @file Convert cookies copy/pasted from Chrome's Application -> Storage -> Cookies -> [domain] table,
 * into the Netscape cookies format used by tools like "curl" or "youtube-dl".
 */
const fs = require('fs');

const content = fs.readFileSync(SHELL_INJECTED_FILENAME, 'utf8');
const cookies = content.split('\\n');

console.log('# Netscape HTTP Cookie File');

for (const cookie of cookies) {
  let [name, value, domain, path, expiration, /* size */, httpOnly] = cookie.split('\\t');
  if (!name)
    continue;
  if (domain.charAt(0) !== '.')
    domain = '.' + domain;
  httpOnly = httpOnly === '✓' ? 'TRUE' : 'FALSE'
  if (expiration === 'Session')
    expiration = new Date(Date.now() + 86400 * 1000);
  expiration = Math.trunc(new Date(expiration).getTime() / 1000);
  console.log([domain, 'TRUE', path, httpOnly, expiration, name, value].join('\\t'));
}
END
)"

    case "$1" in
        create)
            if [[ -d "$preset_path" ]]; then
                echoerr "Cannot create preset as it already exists."
                return 1
            fi

            mkdir -p "$preset_path"
            nano "$raw_cookies_path"

            if [[ ! -s "$raw_cookies_path" ]]; then
                echoerr "Preset creation aborted."
                rmdir "$preset_path"
                return 2
            fi

            if ! node -e "$nodejs_script" > "$converted_cookies_path"; then
                echoerr "Cookies conversion failed, aborting creation."
                command rm -rf "$preset_path"
                return 3
            fi

            echosuccess "Successfully created preset: \z[magenta]°$preset_name\z[]°"
            ;;


        renew)
            if [[ ! -d "$preset_path" ]]; then
                echoerr "Cannot create preset as it does not exist."
                return 1
            fi

            mvbak "$raw_cookies_path"
            local backed_up_cookies="$LAST_FILEBAK_PATH"

            nano "$raw_cookies_path"

            if [[ ! -s "$raw_cookies_path" ]]; then
                echoerr "Preset renewal aborted, restoring previous cookies file."
                mv "$backed_up_cookies" "$raw_cookies_path"
                return 2
            fi

            if ! node -e "$nodejs_script" > "$converted_cookies_path"; then
                echoerr "Cookies conversion failed, restoring previous cookies file."
                mv "$backed_up_cookies" "$raw_cookies_path"
                return 3
            fi

            echosuccess "Successfully renewed preset: \z[magenta]°$preset_name\z[]°"
            ;;

        rm)
            if [[ ! -d "$preset_path" ]]; then
                echoerr "Preset was not found (provide ':list' to see them all)"
                return 1
            fi

            rm "$preset_path"
            echosuccess "Successfully removed preset: \z[magenta]°$preset_name\z[]°"
            return
            ;;

        use)
            if [[ ! -f "$converted_cookies_path" ]]; then
                echoerr "Preset was not found (provide ':list' to see them all)"
                return 1
            fi

            ytdl "${@:3}" --cookies "$converted_cookies_path"
            ;;

        use-raw)
            if [[ ! -f "$converted_cookies_path" ]]; then
                echoerr "Preset was not found (provide ':list' to see them all)"
                return 1
            fi

            youtube-dl "${@:3}" --cookies "$converted_cookies_path"
            ;;


        get-path)
            if [[ ! -f "$converted_cookies_path" ]]; then
                echoerr "Preset was not found (provide ':list' to see them all)"
                return 1
            fi

            echo "$converted_cookies_path"
            ;;


        display)
            if [[ ! -f "$converted_cookies_path" ]]; then
                echoerr "Preset was not found (provide ':list' to see them all)"
                return 1
            fi

            cat "$converted_cookies_path"
            ;;


        *)
            echoerr "Unknown action: \z[magenta]°$1\z[]°"
            return 1
            ;;
    esac
}

# Download a full album from Youtube Music
# Ability to download to a custom output directory using the "$YTDL_ALBUM_OUTPUT_DIR"
# You can also run a custom command on each album directory by providing a command in "$YTDL_ALBUM_ITEM_CMD"
# It's also possible to suffix the downloaded items with their playlist ID by setting "$YTDL_ALBUM_ID_SUFFIX"
# Thumbnails downloading can be skipped by setting "$YTDL_SKIP_THUMBNAIL"
# Custom Youtube-DL folder can be set with "$YTDL_DIR_FORMAT"
function ytdlalbum() {
    if [[ -z "$YTDL_ALBUM_PRESET" ]]; then
        echoerr "Please provide a cookies preset in variable \$YTDL_ALBUM_PRESET. To list them, type: \z[magenta]°ytdlcookies list\z[]°"
        return 1
    fi

    if [[ -z "$1" ]]; then
        echoerr "Please provide an album URL to download."
        return 1
    fi

    if [[ "$1" != "https://music.youtube.com/playlist?list="* ]]; then
        echoerr "This is not a valid YouTube Music Album/Playlist URL!"
        return 1
    fi

    local id_suffix=""

    if (( $YTDL_ALBUM_ID_SUFFIX )); then
        id_suffix=" [%(playlist_id)s]"
    fi

    local dir_format="%(artist)s - %(release_year)s - %(album)s$id_suffix"

    if [[ ! -z "$YTDL_DIR_FORMAT" ]]; then
        dir_format="$YTDL_DIR_FORMAT"
    fi

    local thumbnail_cmd="__ytdlalbumthumbnail"
    local thumbnail_args=""

    if (( $YTDL_SKIP_THUMBNAIL )); then
        thumbnail_cmd=""
        thumbnail_args=" --no-id4cover"
    fi

    YTDL_AUDIO_ONLY=1 YTDL_OUTPUT_DIR="$YTDL_ALBUM_OUTPUT_DIR" YTDL_ITEM_CMD=("$thumbnail_cmd" "${YTDL_ALBUM_ITEM_CMD[@]}") \
    ytdlcookies use "$YTDL_ALBUM_PRESET" "$@" \
        -o "$dir_format/%(playlist_index)s.%(release_year)s.%(id)s. %(track)s.%(ext)s" \
        --exec "zsh $ADF_FUNCTIONS_DIR/youtube-dl.tag.zsh$thumbnail_args"
}

# Download a playlist from Youtube Music
function ytdlplaylist() {
    YTDL_DIR_FORMAT="%(playlist_title)s" YTDL_SKIP_THUMBNAIL=1 ytdlalbum "$@"
}

# (Internal) Download a thumbnail (requires tagging)
function __ytdlalbumthumbnail() {
    if [[ -z "$1" || -z "$YTDL_ALBUM_PRESET" ]]; then
        echoerr "Either preset, directory or both were not provided."
        return 1
    fi

    if [[ ! -d "$1" ]]; then
        echoerr "Input directory \z[magenta]°$1\z[]° does not exist."
        return 1
    fi

    local id4cover_file="$1/__id4cover.txt"

    if [[ ! -f "$id4cover_file" ]]; then
        echoerr "Cannot download thumbnail (missing identification file \z[magenta]°$id4cover_file\z[]°)"
        return 1
    fi

    local id=$(cat "$id4cover_file")

    if [[ -z "$id" ]]; then
        echoerr "Cannot download thumbnail (identifier is empty)"
        return 1
    fi

    local thumbnail_url=$(ytdlcookies use-raw "$YTDL_ALBUM_PRESET" --get-thumbnail "https://music.youtube.com/watch?v=$id")
    thumbnail_url="${thumbnail_url%%\?*}"
    thumbnail_url="${thumbnail_url/hqdefault/maxresdefault}"

    if [[ $? != 0 ]]; then
        echoerr "Failed to get thumbnail's URL."
        return 1
    fi
    
    local thumbnail_tmp="$1/cover.tmp.${thumbnail_url:t:e}"

    echoinfo ">> Downloading thumbnail for album \z[magenta]°$(basename "$1")\z[]° at \z[yellow]°$thumbnail_url\z[]°..."

    if ! dl "$thumbnail_url" "$thumbnail_tmp"; then
        echoerr "Failed to download thumbnail."
        return 1
    fi

    if ! ffmpeg -hide_banner -loglevel error -i "$thumbnail_tmp" -filter:v "crop=720:720:280:1000" "$1/cover.jpg"; then
        echoerr "Failed to crop thumbnail with FFMPEG."
        return 1
    fi

    rm "$thumbnail_tmp"
    rm "$id4cover_file"
}

export ADF_YTDL_COOKIES_PRESETS_DIR="$ADF_DATA_DIR/ytdl-cookies-presets"

if [[ ! -d "$ADF_YTDL_COOKIES_PRESETS_DIR" ]]; then
    mkdir -p "$ADF_YTDL_COOKIES_PRESETS_DIR"
fi

alias yr="ytdlcookies renew"
alias yu="ytdlcookies use"