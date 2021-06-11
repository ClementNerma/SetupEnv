#
# This file defines global functions and aliases
#

# Synchronize a directory
function rsync_dir() {
	if [[ $SUDO_RSYNC = "true" ]]; then
		echowarn "WARNING: Using rsync in SUDO mode."
	fi

	local started=0
	local failed=0

	echoinfo "Starting transfer..."
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
			echoerr "Transfer failed. Retrying in 5 seconds..."
			sleep 5s
			failed=1
		fi
	done

	echosuccess "Done."
}

# Copy a project to another directory without its dependencies and temporary files
function cp_proj_nodeps() {
	if [[ ! -d "$1" ]]; then
		echoerr "Source does not exist!"
		return 1
	fi

	if [[ -f "$2" || -d "$2" ]]; then
		echoerr "Target already exists!"
		return 1
	fi

	rsync --exclude '*.tmp' --exclude '.rustc_info.json' \
		  --exclude 'node_modules/' --exclude 'pnpm-store/' --exclude 'common/temp/' --exclude '.rush/temp/' \
		  --exclude 'build/' --exclude 'dist/' \
		  --exclude 'target/debug/' --exclude 'target/release/' --exclude 'target/wasm32-unknown-unknown/' --exclude 'target/doc/' \
		  --exclude 'target/.rustc_info.json' --exclude 'target/.rustdoc_fingerprint.json' \
		  --archive --partial --progress \
		  --delete --delete-excluded "${@:3}" "$1/" "$2"
}

# Backup a project
function bakproj() {
	_filebak "$1" cp_proj_nodeps "${@:2}"
}

# Backup the current project
function bakthis() {
	local item=$(pwd)
	cd ..
	_filebak "$item" cp_proj_nodeps "${@:2}"
	cd "$item"
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
	echoinfo "Renaming branch '$old_branch' to '$1'..."
	git branch -m "$1"
	git push origin -u "$1"
	git push origin --delete "$old_branch"
}

# A simple 'rm' with progress
function rmprogress() {
	if [[ -z "$1" ]]; then
		echoerr "Missing operand for 'rmprogress'"
		return 1
	fi
	
	rm -rv "$1" | pv -l -s $( du -a "$1" | wc -l ) > /dev/null
}

# Move a folder's content with progress
function mvprogress() {
	if [[ ! -d $1 ]]; then
		echoerr "Please provide a source directory."
		return 1
	fi
	
	if [[ ! -d $2 ]]; then
		echoerr "Please provide a target directory."
		return 2
	fi

	local files_count="$(command ls "$1" -1A | wc -l)"
	local counter=0

	for item in "$1"/*(N)
	do
		counter=$((counter+1))
		echoinfo "> Moving item $counter / $files_count: \z[magenta]°$(basename "${item%/}")\z[]°..."

		local tomove="${item%/}"

		if [[ -d "$item" ]]; then
			item="$item/"
		fi

		if ! sudo mv "$item" "$2"
		then
			echoerr "Failed to move a file!"
			return 1
		fi
	done
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
		echoerr "Please provide a project to go to."
		return 1
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

# Install a Debian package
function debi() {
	sudo apt update
	sudo dpkg -i "$1"
	sudo apt install -f
}

# Install a Debian package from the web
function debir() {
	local debpath="/tmp/$(date +%s%N).deb"
	dl "$1" "$debpath"
	debi "$debpath"
	command rm "$debpath"
}

# Start a timer
typeset -A ADF_TIMERS

function timer_start() {
	if [[ -z "$1" ]]; then
		echoerr "Please provide a timer name."
		return 1
	fi

	if [[ ! -z "${ADF_TIMERS[$1]}" ]]; then
		echoerr "Timer \z[yellow]°$1\z[]° is already in use."
		return 2
	fi

	ADF_TIMERS[$1]=$(($(date +%s%N)))
}

function timer_end() {
	if [[ -z "$1" ]]; then
		echoerr "Please provide a timer name."
		return 1
	fi

	if [[ -z "${ADF_TIMERS[$1]}" ]]; then
		echoerr "Timer \z[yellow]°$1\z[]° does not exist."
		return 2
	fi

	local started=${ADF_TIMERS[$1]}
	local finished=$(($(date +%s%N)))
	local elapsed=$(((finished - started) / 1000000))

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

	unset "ADF_TIMERS[$1]"
}