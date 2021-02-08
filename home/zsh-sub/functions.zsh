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
	cp_proj_nodeps "$1" "$1.bak"
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

# Software: Github
function ghdl() {
	if [[ $1 != "https://github.com/"* ]]; then
		echoerr "Invalid GitHub repository URL: \e[93m$1"
	fi

	local repoauthor=$(echo "$1" | cut -d'/' -f4)
	local reponame=$(echo "$1" | cut -d'/' -f5)
	local outdir="$reponame"

	if [[ ! -z "$3" ]]; then
		outdir="$3"
	fi
	
	reponame="${reponame%.git}"

	echosuccess "Cloning from repository: \e[93m$repoauthor/$reponame\e[92m..."

	if [[ -d "$3" ]]; then
		echoerr "> Directory \e[95m$3\e[91m already exists!"
		return 1
	fi

	echo -e "\e[34m> Fetching default branch..."
	local branch=$(curl -s "https://api.github.com/repos/$repoauthor/$reponame" | jq -r ".default_branch")

	if [[ $branch == "null" ]]; then
		echoerr "> Failed to determine default branch!"
		return 1
	fi

	local filename="$reponame-$(date +%s).zip"
	echo -e "\e[34m> Fetching archive for branch \e[93m$branch\e[34m to \e[95m$filename\e[34m...\e[0m"
	
	local zipurl="https://codeload.github.com/$repoauthor/$reponame/zip/$branch"

	if ! dlren "$zipurl" "$filename"; then
		echoerr "> Failed to fetch archive from URL: \e[93m$zipurl\e[91m!"
		return 1
	fi

	echo -e "\e[34m> Extracting archive to directory \e[93m$3\e[34m...\e[0m"
	unzip -q "$filename"
	mv "$reponame-$branch" "$3"

	cd "$3"

	echosuccess "Done!"
}

# Software: Youtube-DL
function ytdlbase() {
	youtube-dl -f bestvideo+bestaudio/best --add-metadata "$@"
}

function ytdl() {
	if [[ $1 == "https://www.youtube.com/"* ]]; then
		ytdlbase "$@"
	else
		ytdlbase --embed-thumbnail "$@"
	fi
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
	htdl "$1" -o "$debpath"
	debi "$debpath"
	rm "$debpath"
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