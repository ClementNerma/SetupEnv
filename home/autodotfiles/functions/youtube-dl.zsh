# Software: Youtube-DL
export YTDL_PARALLEL_DOWNLOADS=0

# Overriding variables:
# * YTDL_DRY_RUN=1        => just display the command without running it
# * YTDL_BARE=1           => don't add any of the default arguments to Youtube-DL
# * YTDL_CUSTOM_QUALITY=1 => don't add the default "-f bestvideo/..." argument
# * YTDL_NO_METADATA=1    => don't add the default "--add-metadata" argument
# * YTDL_NO_THUMBNAIL=1   => don't add the thumbnail to the downloaded video file
# * YTDL_AUDIO_ONLY=1     => only download the audio track
# * YTDL_FORCE_PARALLEL=1 => force to download the video on parallel, ignoring the default thresold
# * YTDL_TEMP_DIR=...     => download in the specified temporary directory before moving it to the final one
# * YTDL_OUTPUT_DIR=...   => download to the specified directory (default: the current working directory)
# * YTDL_APPEND=...       => append arguments to the final youtube-dl command
# * YTDL_PRINT_CMD=1      => show the used command
# * YTDL_ITEM_CMD=...     => run a command for each root item when download is finished
function ytdl() {
	export YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS+1))
	local decrease_counter=1
	local is_using_tempdir=0

	local prev_cwd=$(pwd)
	local tempdir=""
	local is_tempdir_cwd=0
	
	local download_to=$(pwd)

	if [[ ! -z "$YTDL_OUTPUT_DIR" ]]; then
		download_to="${YTDL_OUTPUT_DIR%/}"
		echoinfo "Downloading to custom directory: \e[95m$download_to"
	fi

	# Check if download must be performed in a temporary directory
	if (( YTDL_PARALLEL_DOWNLOADS >= ADF_CONF_YTDL_TEMP_DL_DIR_THRESOLD )) || [[ "$YTDL_FORCE_PARALLEL" = 1 ]] || [[ ! -z "$YTDL_TEMP_DIR" ]]
	then
		export YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS-1))
		decrease_counter=0
		is_using_tempdir=1
		tempdir="$ADF_YTDL_TEMP_DL_DIR_PATH/$(date +%s)"

		if [[ -z "$YTDL_TEMP_DIR" ]]; then
			mkdir -p "$tempdir"
		elif [[ ! -d "$YTDL_TEMP_DIR" ]]; then
			echoerr "Resume path is not a directory!"
			return 1
		else
			tempdir="${YTDL_TEMP_DIR%/}"
		fi

		if [[ "$(realpath "$prev_cwd")" == "$(realpath "$tempdir")" ]]; then
			is_tempdir_cwd=1
		else
			echoinfo "> Downloading first to temporary directory: \e[95m$tempdir"
		fi

		cd "$tempdir"
	fi

	# Store the command in an history
	local bestquality_params="-f bestvideo+bestaudio/best"
	local metadata_params="--add-metadata"
	local thumbnail_params="--embed-thumbnail"

	if [[ $1 == "https://www.youtube.com/"* || $1 == "https://music.youtube.com/"* ]]; then
		thumbnail_params=""
	fi

	if [[ ! -z "$YTDL_CUSTOM_QUALITY" ]] || [[ ! -z "$YTDL_BARE" ]]; then
		bestquality_params=""
	fi

	if [[ ! -z "$YTDL_AUDIO_ONLY" ]]; then
		bestquality_params="-f bestaudio"
	fi

	if [[ ! -z "$YTDL_NO_METADATA" ]] || [[ ! -z "$YTDL_BARE" ]]; then
		metadata_params=""
	fi

	if [[ ! -z "$YTDL_NO_THUMBNAIL" ]] || [[ ! -z "$YTDL_BARE" ]]; then
		thumbnail_params=""
	fi

	local ytdl_debug_cmd="$bestquality_params $metadata_params $thumbnail_params "$@" $YTDL_APPEND"

	if [[ ! -z "$YTDL_PRINT_CMD" || ! -z "$YTDL_DRY_RUN" ]]; then
		echoinfo "Command >> youtube-dl $ytdl_debug_cmd"
	fi

	echo "YTDL_TEMP_DIR='$tempdir' ytdl $ytdl_debug_cmd" >> "$ADF_CONF_YTDL_HISTORY_FILE"

	# Perform the download
	if [[ -z "$YTDL_DRY_RUN" ]]; then
		if ! youtube-dl $bestquality_params $metadata_params $thumbnail_params "$@" $YTDL_APPEND
		then
			if [[ $decrease_counter = 1 ]]; then
				YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS-1))
			fi

			echoerr "Failed to download videos with Youtube-DL!"
			echoerr "You can resume the download with:"
			echoinfo "ytdlresume '$tempdir' $*"
			cd "$prev_cwd"
			return 1
		fi
	fi

	# Decrease the counter
	if [[ $decrease_counter = 1 ]]; then
		export YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS-1))
	fi

	# Move ready files & clean up
	if [[ "$is_using_tempdir" = 1 ]] && [[ $is_tempdir_cwd = 0 ]]
	then
		cd "$prev_cwd"

		local files_count="$(command ls "$tempdir" -1A | wc -l)"
		local counter=0

		echoinfo "Moving [$files_count] files to output directory: \e[95m$download_to\e[93m..."

		if [[ ! -d "$download_to" ]]; then
			mkdir -p "$download_to"
		fi

		if [[ ! -z "$YTDL_ITEM_CMD" ]]; then
			for item in "$tempdir"/*(N)
			do
				"$YTDL_ITEM_CMD" "$item"
			done
		fi

		for item in "$tempdir"/*(N)
		do
			counter=$((counter+1))
			echoinfo "> Moving item $counter / $files_count: \e[95m$(basename "${item%/}")\e[93m..."

			local tomove="${item%/}"

			if [[ -d "$item" ]]; then
				item="$item/"
			fi

			if ! mv "$item" "$download_to"
			then
				echoerr "Failed to move Youtube-DL videos! Temporary download path is:"
				echopath "$tempdir"
				return 1
			fi
		done

		echoinfo "Done!"
		rmdir "$tempdir"
	fi
}

function ytdlclean() {
	rm "$ADF_YTDL_TEMP_DL_DIR_PATH"
}

function ytdlpar() {
	YTDL_FORCE_PARALLEL=1 ytdl "$@"
}

function ytdlresume() {
	YTDL_TEMP_DIR="$1" ytdl "${@:2}"
}

function ytdlhere() {
	YTDL_TEMP_DIR="." ytdl "$@"
}

function ytdlmveach() {
	ytdl "$@" --exec "invmv '$(pwd)'"
}

function ytdlhistory() {
	command cat "$ADF_CONF_YTDL_HISTORY_FILE"
}

# Download a YouTube video with separate french and english subtitle files (if available)
function ytdlsubs() {
	ytdl "$@" --write-sub --sub-lang "fr,en"
}

# Load the cookies function
source "$ADF_FUNCTIONS_DIR/youtube-dl.cookies.zsh"