#
# This file defines global functions and aliases
#

# Synchronize a directory
function rsync_dir() {
	if [[ $SUDO_RSYNC = "true" ]]; then
		echo WARNING: Using rsync in SUDO mode.
	fi

	local started=0
	local failed=0

	echo Starting transfer...
	while [[ $started -eq 0 || $failed -eq 1 ]]
	do
	    started=1
	    failed=0

		if [[ $SUDO_RSYNC = "true" ]]; then
			sudo rsync --archive --verbose --partial --progress "$1" "$2" ${@:3}
		else
			rsync --archive --verbose --partial --progress "$1" "$2" ${@:3}
		fi
	
		if [[ $? -ne 0 ]]
		then
			echo Transfer failed. Retrying in 5 seconds...
			sleep 5s
			failed=1
		fi
	done
	echo Done.
}

# Copy a project to another directory without its dependencies and temporary files
function cp_proj_nodeps() {
	if [[ -d "$2" ]]; then
		if [[ $3 != "-f" && $3 != "--force" ]]; then
			echo "Target directory exists. To overwrite it, provide '-f' or '--force' as a third argument."
			return 1
		fi
	fi

	rsync --exclude '*.tmp' --exclude '.rustc_info.json' \
		  --exclude 'node_modules/' --exclude 'pnpm-store/' --exclude 'common/temp/' --exclude '.rush/temp/' \
		  --exclude 'build/' --exclude 'dist/' \
		  --exclude 'target/debug/' --exclude 'target/release/' --exclude 'target/wasm32-unknown-unknown/' \
		  --archive --partial --progress \
		  --delete --delete-excluded "$1/" "$2" "${@:3}"
}

# Backup a project
function bakproj() {
	local itempath="${1%/}"

	if [[ ! -f "$itempath" && ! -d "$itempath" ]]; then
		echoerr "Provided path was not found: \e[92m$itempath"
		return 1
	fi

	cp_proj_nodeps "$itempath" "$itempath.bak-$(date '+%Y_%m_%d-%H_%M_%S')"
}

# Run a Cargo project located in the projects directory
function cargext() {
	cargo run "--manifest-path=$PROJDIR/$1/Cargo.toml" -- ${@:2}
}

# Run a Cargo project located in the projects directory in release mode
function cargextr() {
	cargo run "--manifest-path=$PROJDIR/$1/Cargo.toml" --release -- ${@:2}
}

# Rename a Git branch
function gitrename() {
    local old_branch=$(git rev-parse --abbrev-ref HEAD)
	echo Renaming branch "$old_branch" to "$1"...
	git branch -m "$1"
	git push origin -u "$1"
	git push origin --delete "$old_branch"
}

# A simple 'rm' with progress
function rmprogress() {
	if [ -z "$1" ]; then
		return 1
	fi
	
	command rm -rv "$1" | pv -l -s $( du -a "$1" | wc -l ) > /dev/null
}

# Archive a directory into a .tar file
function tarprogress() {
	tar cf - "$1" -P | pv -s $(du -sb "$1" | awk '{print $1}') > "$1.tar"
}

# Archive a directory into a .tar.gz file
function targzprogress() {
	tar czf - "$1" -P | pv -s $(du -sb "$1" | awk '{print $1}') > "$1.tar"
}

# Measure time a command takes to complete
function howlong() {
	local started=$(($(date +%s%N)))
	"$@"
	local finished=$(($(date +%s%N)))
	local elapsed=$(((finished - started) / 1000000))

	printf 'Command "'
	printf '%s' "${@[1]}"
	if [[ ! -z $2 ]]; then printf ' %s' "${@:2}"; fi
	printf '" completed in ' "$@"

	local elapsed_s=$((elapsed / 1000))
	local D=$((elapsed_s/60/60/24))
	local H=$((elapsed_s/60/60%24))
	local M=$((elapsed_s/60%60))
	local S=$((elapsed_s%60))
	if [ $D != 0 ]; then printf "${D}d "; fi
	if [ $H != 0 ]; then printf "${H}h "; fi
	if [ $M != 0 ]; then printf "${M}m "; fi
	
	local elapsed_ms=$((elapsed % 1000))
	printf "${S}.%03ds" $elapsed_ms

	printf "\n"
}

# Go to a directory located in the projects directory
function p() {
	if [[ -z "$1" ]]; then
		echo Please provide a project to go to.
	else
		cd "$PROJDIR/$1"
	fi
}

# Create a directory and go into it
function mkcd() {
	if [[ ! -d "$1" ]]; then
		mkdir -p "$1"
	fi

	cd "$1"
}

# Software: Trasher
function trasher() {
	sudo trasher --create-trash-dir --trash-dir "$TRASHDIR" "$@"
}

function rm() {
	trasher rm --move-ext-filesystems "$@"
}

function rmperma() {
	trasher rm --permanently "$@"
}

function unrm() {
	trasher unrm --move-ext-filesystems "$@"
}

# Software: Youtube-DL
export YTDL_PARALLEL_DOWNLOADS=0

# Overriding variables:
# * BARE_YTDL=1           => don't add any of the default arguments to Youtube-DL
# * CUSTOM_QUALITY=1      => don't add the default "-f bestvideo/..." argument
# * NO_METADATA=1         => don't add the default "--add-metadata" argument
# * YTDL_FORCE_PARALLEL=1 => force to download the video on parallel, ignoring the default thresold
# * YTDL_RESUME_PATH=...  => download in the specified directory inside or a generated temporary one
# * YTDL_APPEND=...       => append arguments to the final youtube-dl command
# * DEBUG_COMMAND=1       => show the used command
function ytdlbase() {
	export YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS+1))
	local decrease_counter=1
	local is_using_tempdir=0

	local prev_cwd=$(pwd)
	local tempdir=""
	local is_tempdir_cwd=0

	# Check if download must be performed in a temporary directory
	if (( YTDL_PARALLEL_DOWNLOADS >= ADF_CONF_YTDL_TEMP_DL_DIR_THRESOLD )) || [[ "$YTDL_FORCE_PARALLEL" = 1 ]] || [[ ! -z "$YTDL_RESUME_PATH" ]]
	then
		export YTDL_PARALLEL_DOWNLOADS=$((YTDL_PARALLEL_DOWNLOADS-1))
		decrease_counter=0
		is_using_tempdir=1
		tempdir="$ADF_YTDL_TEMP_DL_DIR_PATH/$(date +%s)"

		if [[ -z "$YTDL_RESUME_PATH" ]]; then
			mkdir -p "$tempdir"
		elif [[ ! -d "$YTDL_RESUME_PATH" ]]; then
			echoerr "Resume path is not a directory!"
			return 1
		else
			tempdir="$YTDL_RESUME_PATH"
		fi

		if [[ "$(realpath "$prev_cwd")" == "$(realpath "$tempdir")" ]]; then
			is_tempdir_cwd=1
		else
			echoinfo "Downloading to temporary directory: \e[95m$tempdir"
		fi

		cd "$tempdir"
	fi

	# Store the command in an history
	local bestquality_params="-f bestvideo+bestaudio/best"
	local metadata_params="--add-metadata"

	if [[ ! -z "$CUSTOM_QUALITY" && "$CUSTOM_QUALITY" != 0 ]] || [[ ! -z "$BARE_YTDL" && "$BARE_YTDL" != 0 ]]; then
		bestquality_params=""
	fi

	if [[ ! -z "$NO_METADATA" && "$NO_METADATA" != 0 ]] || [[ ! -z "$BARE_YTDL" && "$BARE_YTDL" != 0 ]]; then
		metadata_params=""
	fi

	if [[ ! -z "$DEBUG_COMMAND" ]]; then
		echoinfo "Command >>" youtube-dl $bestquality_params $metadata "$@" $YTDL_APPEND
	fi

	echo "YTDL_RESUME_PATH='$tempdir' ytdlbase $bestquality_params $metadata "$@" $YTDL_APPEND" >> "$ADF_CONF_YTDL_HISTORY_FILE"

	# Perform the download
	if ! youtube-dl $bestquality_params $metadata "$@" $YTDL_APPEND
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

		echoinfo "Moving [$files_count] files to output directory: \e[95m$(pwd)"

		for item in "$tempdir"/*(N)
		do
			counter=$((counter+1))
			echoinfo "> Moving file $counter / $files_count: \e[95m$(basename "$item")\e[92m..."
			
			if ! mv "$item" .
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

function ytdl() {
	if [[ $1 == "https://www.youtube.com/"* ]]; then
		ytdlbase "$@"
	else
		ytdlbase --embed-thumbnail "$@"
	fi
}

function ytdlpar() {
	YTDL_FORCE_PARALLEL=1 ytdl "$@"
}

function ytdlresume() {
	local resume_path="$1"
	shift

	YTDL_RESUME_PATH="$resume_path" ytdl "$@"
}

function ytdlhere() {
	YTDL_RESUME_PATH="." ytdl "$@"
}

function ytdlhistory() {
	command cat "$ADF_CONF_YTDL_HISTORY_FILE"
}

# Download a YouTube video with separate french and english subtitle files (if available)
function ytdlsubs() {
	ytdl "$@" --write-sub --sub-lang "fr,en"
}

# Install a Debian package
function debi() {
	sudo apt update
	sudo dpkg -i "$1"
	sudo apt install -f
}

# Install a Debian package from the web
function debir() {
	local debpath="/tmp/$(date +%s).deb"
	dl "$1" "$debpath"
	debi "$debpath"
	command rm "$debpath"
}

# Open a file or directory on Windows from a 'fd' search
function openfd() {
  local results=$(fd "$@")
  local count=$(echo "$results" | wc -l)

  if [[ -z "$results" ]]; then
      echoerr "No result found for this search."
      return 1
  fi

  if [[ $count = 1 ]]; then
    open "$results"
    return
  fi

  local selected=$(echo "$results" | fzf)

  if [[ -z "$selected" ]]; then
    return 1
  fi

  open "$selected"
}

# Open a file or directory on Windows from a 'zoxide' search
function openz() {
  local result=$(zoxide query "$1" 2>/dev/null)

  if [[ -z "$result" ]]; then
    echoerr "No result found by Zoxide."
    return 1
  fi

  open "$result"
}

# Open a file or directory on Windows from a 'zoxide' + 'fd' search
function openfz() {
  if [[ -z "$1" ]]; then
    echoerr "Please provide a search for Zoxide."
    return 1
  fi

  local result=$(zoxide query "$1" 2>/dev/null)

  if [[ -z "$result" ]]; then
    echoerr "No result found by Zoxide."
    return 1
  fi
  
  cd "$result"
  openfd
}

# Aliases to exit after open commands
function opene() { open "$@" && exit }
function openze() { openz "$@" && exit }
function openfde() { openfd "$@" && exit }
function openfze() { openfz "$@" && exit }