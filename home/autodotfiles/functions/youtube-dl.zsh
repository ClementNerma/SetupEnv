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
# * YTDL_JUST_ITEM_CMD=1  => just run the provided commands on each item (don't run 'youtube-dl')
# * YTDL_ITEM_CMD=...     => run a command for each root item when download is finished
# * YTDL_IGNORE_ERR=1     => consider download a success even if a non-zero exit code was returned
# * YTDL_ALWAYS_THUMB=1   => if thumbnail cannot be embedded, write it alongside the output file
# * YTDL_LIMIT_BANDWIDTH  => limit download bandwidth
function ytdl() {
	export YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS+1))
	local decrease_counter=1
	local is_using_tempdir=0

	local prev_cwd=$(pwd)
	local tempdir=""
	local is_tempdir_cwd=0
	
	local download_to=$(pwd)

	if [[ -z "$YTDL_LIMIT_BANDWIDTH" ]]; then
		local YTDL_LIMIT_BANDWIDTH="$ADF_YTDL_DEFAUT_LIMIT_BANDWIDTH"
	fi

	if [[ ! -z "$YTDL_LIMIT_BANDWIDTH" && ! $YTDL_LIMIT_BANDWIDTH = *"K" && ! $YTDL_LIMIT_BANDWIDTH = *"M" ]]; then
		echoerr "Invalid bandwidth limit provided."
		return 1
	fi

	if [[ ! -z "$YTDL_OUTPUT_DIR" ]]; then
		download_to="${YTDL_OUTPUT_DIR%/}"
		echoinfo "Downloading to custom directory: \z[magenta]°$download_to\z[]°"
	fi

	# Check if download must be performed in a temporary directory
	if (( YTDL_PARALLEL_DOWNLOADS >= ADF_CONF_YTDL_TEMP_DL_DIR_THRESOLD )) || (( $YTDL_FORCE_PARALLEL )) || [[ ! -z "$YTDL_TEMP_DIR" ]]
	then
		export YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS-1))
		decrease_counter=0
		is_using_tempdir=1
		tempdir="$ADF_CONF_YTDL_TEMP_DL_DIR_PATH/$(date +%s%N)"

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
			echoinfo "> Downloading first to temporary directory: \z[magenta]°$tempdir\z[]°"
		fi

		cd "$tempdir"
	fi

	# Store the command in an history
	local metadata_params="--add-metadata"
	local thumbnail_params="--embed-thumbnail"
	local bandwidth_limit="1G"
	local quality_format="bestvideo[height>2160]+bestaudio/best[height>2160]/bestvideo[height=2160]+bestaudio/best[height=2160]/bestvideo[height>1440]+bestaudio/best[height>1440]/bestvideo[height=1440]+bestaudio/best[height=1440]/bestvideo[height>1080]+bestaudio/best[height>1080]/bestvideo[height=1080]+bestaudio/best[height=1080]/bestvideo[height>720]+bestaudio/best[height>720]/bestvideo[height=720]+bestaudio/best[height=720]/bestvideo[height>480]+bestaudio/best[height>480]/bestvideo[height=480]+bestaudio/best[height=480]/bestvideo[height>320]+bestaudio/best[height>320]/bestvideo[height=320]+bestaudio/best[height=320]/bestvideo[height>240]+bestaudio/best[height>240]/bestvideo[height=240]+bestaudio/best[height=240]/bestvideo[height>144]+bestaudio/best[height>144]/bestvideo[height=144]+bestaudio/best[height=144]/bestvideo+bestaudio/best"

	if [[ $1 == "https://www.youtube.com/"* || $1 == "https://music.youtube.com/"* ]]; then
		if (( $YTDL_ALWAYS_THUMB )); then
			thumbnail_params="--write-thumbnail"
		else
			thumbnail_params=""
		fi
	fi

	if (( $YTDL_AUDIO_ONLY )); then
		quality_format="bestaudio"
	fi

	if [[ ! -z $YTDL_LIMIT_BANDWIDTH ]]; then
		bandwidth_limit="$YTDL_LIMIT_BANDWIDTH"
	fi

	if [[ ! -z $YTDL_CUSTOM_QUALITY ]]; then
		quality_format="$YTDL_CUSTOM_QUALITY"
	fi

	if (( $YTDL_NO_METADATA )) || (( $YTDL_BARE )); then
		metadata_params=""
	fi

	if (( $YTDL_NO_THUMBNAIL )) || (( $YTDL_BARE )); then
		thumbnail_params=""
	fi

	local ytdl_debug_cmd="$bestquality_params $metadata_params $thumbnail_params -r $bandwidth_limit "$@" $YTDL_APPEND"

	if (( $YTDL_PRINT_CMD )) || (( $YTDL_DRY_RUN )); then
		echoinfo "Command >> youtube-dl $ytdl_debug_cmd"
	fi

	# Perform the download
	if [[ "$YTDL_DRY_RUN" != 1 ]] && [[ -z "$YTDL_JUST_ITEM_CMD" ]]; then
		if ! youtube-dl -f "$quality_format" $metadata_params $thumbnail_params -r $bandwidth_limit --abort-on-unavailable-fragment "$@" $YTDL_APPEND
		then
			if ! (( $YTDL_IGNORE_ERR )); then
				if [[ $decrease_counter = 1 ]]; then
					YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS-1))
				fi

				echoerr "Failed to download videos with Youtube-DL!"
				echoerr "You can resume the download with:"
				echoinfo "ytdlresume '$tempdir' '$1' ${@:2}"
				cd "$prev_cwd"
				return 1
			fi
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

		if [[ ! -z "$YTDL_ITEM_CMD" ]]; then
			local command_count=0
			
			for cmd in ${YTDL_ITEM_CMD[@]}; do
				if [[ ! -z "$cmd" ]]; then
					command_count=$((command_count + 1))
				fi
			done

			echoinfo "> Running custom commands ($command_count) on downloaded items..."

			for cmd in ${YTDL_ITEM_CMD[@]}; do
				if [[ -z "$cmd" ]]; then
					continue
				fi

				echoinfo ">> Running custom command: \z[magenta]°$cmd\z[]°..."

				for item in "$tempdir"/*(N)
				do
					if ! "$cmd" "$item"; then
						echoerr "Custom command failed"
						echoerr "You can resume the download with:"
						echoinfo "ytdlresume '$tempdir' '$1' ${*:2}"
						cd "$prev_cwd"
						return 1
					fi

					# Prevent scripts from changing the current working directory and causing a bug
					cd "$prev_cwd"
				done
			done
		fi

		echoinfo "> Moving [$files_count] files to output directory: \z[magenta]°$download_to\z[]°..."

		if [[ ! -d "$download_to" ]]; then
			mkdir -p "$download_to"
		fi

		for item in "$tempdir"/*(N)
		do
			counter=$((counter+1))
			echoinfo "> Moving item $counter / $files_count: \z[magenta]°$(basename "${item%/}")\z[]°..."

			local tomove="${item%/}"

			if [[ -d "$item" ]]; then
				local item="$item/"
			fi

			if ! sudo mv "$item" "$download_to"
			then
				echoerr "Failed to move Youtube-DL videos! Temporary download path is:"
				echodata "$tempdir"
				return 1
			fi
		done

		echoinfo "Done!"
		rmdir "$tempdir"
	fi
}

function ytdlclean() {
	rm "$ADF_CONF_YTDL_TEMP_DL_DIR_PATH"
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

function ytdlaria() {
	ytdl --external-downloader aria2c --external-downloader-args "-c -x 10 --summary-interval=0" "$@"
}

# Download a YouTube video with separate french and english subtitle files (if available)
function ytdlsubs() {
	ytdl "$@" --write-sub --sub-lang "fr,en"
}

# Load the cookies function
source "$ADF_FUNCTIONS_DIR/youtube-dl-cookies.zsh"