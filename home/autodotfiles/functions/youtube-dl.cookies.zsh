function ytdlcookies() {
    if [[ -z "$1" ]]; then
        echoerr "Please provide an action to perform ('help' to get some help)."
        return 1
    fi

    case "$1" in
        help)
            echoinfo "1. Go to: \e[95mChrome's Application -> Storage -> Cookies -> [domain] table"
            echoinfo "2. Copy it (Ctrl+C)"
            echoinfo "3. Run 'ytdlcookies create <your preset name>'"
            echoinfo "4. Paste the copied table (Ctrl+V) in the editor"
            echoinfo "5. Save and exit (Ctrl+S & Ctrl+X)"
            echoinfo "6. Use it with 'ytdlcookies use <your preset name> <ytdl arguments>"
            echoinfo
            echopath "A. Renew expired cookies with 'ytdlcookies renew <your preset name>' (then steps from 4.)"
            echopath "B. Delete a preset with 'ytdlcookies rm <your preset name>"
            echopath "C. List all existing presets with 'ytdlcookies list'"
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

            echosuccess "Successfully created preset: \e[95m$preset_name"
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

            echosuccess "Successfully renewed preset: \e[95m$preset_name"
            ;;

        rm)
            if [[ ! -d "$preset_path" ]]; then
                echoerr "Preset was not found (provide ':list' to see them all)"
                return 1
            fi

            rm "$preset_path"
            echosuccess "Successfully removed preset: \e[95m$preset_name"
            return
            ;;

        use)
            if [[ ! -f "$converted_cookies_path" ]]; then
                echoerr "Preset was not found (provide ':list' to see them all)"
                return 1
            fi

            ytdl "${@:3}" --cookies "$converted_cookies_path"
            ;;


        *)
            echoerr "Unknown action: \e[95m$1"
            return 1
            ;;
    esac
}

export ADF_YTDL_COOKIES_PRESETS_DIR="$ADF_DATA_DIR/ytdl-cookies-presets"

if [[ ! -d "$ADF_YTDL_COOKIES_PRESETS_DIR" ]]; then
    mkdir -p "$ADF_YTDL_COOKIES_PRESETS_DIR"
fi

alias yr="ytdlcookies renew"
alias yu="ytdlcookies use"