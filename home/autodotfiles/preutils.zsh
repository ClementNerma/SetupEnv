
# Arguments: "<url>" "<download location>"
function dl() {
    if [[ ! -z "$2" ]]; then
        wget -q --show-progress -O "$2" "$1" "${@:3}"
    else
        wget -q --show-progress "$@"
    fi
}

function sudodl() {
    if [[ ! -z "$2" ]]; then
        sudo wget -q --show-progress -O "$2" "$1" "${@:3}"
    else
        sudo wget -q --show-progress "$@"
    fi
}

# Download files whose URL will be provided through STDIN
# Arguments: "<download location>"
function dli() { wget -qi - --show-progress -O "$1" }
function sudodli() { sudo wget -qi - --show-progress -O "$1" }

# Download a file from the latest of a GitHub repository
# Arguments: "<repo author>/<reponame>" "<file grep pattern>" "<download location>"
function dlghrelease() {
	local release_url=$(
		curl -s "https://api.github.com/repos/$1/releases/latest" \
        | grep "browser_download_url.*$2" \
        | cut -d : -f 2,3 \
        | tr -d \"
	)

	if [[ -z $release_url ]]; then
		echoerr "Failed to find an URL matching in repository \z[yellow]°$1\z[]° (pattern \z[cyan]°$2\z[]°)"
		return 1
	fi

    curl -s "https://api.github.com/repos/$1/releases/latest" \
        | grep "browser_download_url.*$2" \
        | cut -d : -f 2,3 \
        | tr -d \" \
        | dli "$3"
}

# Download the latest version of the source code from a GitHub repository
# Arguments: "<repo author>/<repo name>" "<download location>"
function ghdl() {
	local repo_url="$1"

	if [[ $repo_url = "https://"* ]]; then
		if [[ $repo_url != "https://github.com/"* ]]; then
			echoerr "Invalid GitHub repository URL: \z[yellow]°$repo_url\z[]°"
			return 1
		fi
	elif [[ $repo_url = "http://"* ]]; then
		echoerr "Cannot get from HTTP link with GitHub"
		return 1
	else
		repo_url="https://github.com/$repo_url"
	fi

	local repoauthor=$(echo "$repo_url" | cut -d'/' -f4)
	local reponame=$(echo "$repo_url" | cut -d'/' -f5)
	local outdir="$reponame"

	if [[ ! -z "$2" ]]; then
		outdir="$2"
	fi
	
	reponame="${reponame%.git}"

	echosuccess "Cloning from repository: \z[yellow]°$repoauthor/$reponame\z[]°..."

	if [[ -d "$outdir" ]]; then
		echoerr "> Directory \z[magenta]°$outdir\z[]° already exists!"
		return 1
	fi

	echoinfo "> Fetching default branch..."
	local branch=$(curl -s "https://api.github.com/repos/$repoauthor/$reponame" | jq -r ".default_branch")

	if [[ $branch == "null" ]]; then
		echoerr "> Failed to determine default branch!"
		return 1
	fi

	local filename="$reponame-$(humandate).zip"
	echoinfo "> Fetching archive for branch \z[yellow]°$branch\z[]° to \z[magenta]°$filename\z[]°..."
	
	local zipurl="https://codeload.github.com/$repoauthor/$reponame/zip/$branch"

	if ! dl "$zipurl" "$filename"; then
		echoerr "> Failed to fetch archive from URL: \z[yellow]°$zipurl\z[]°!"
		return 1
	fi

	echoinfo "> Extracting archive to directory \z[yellow]°$outdir\z[]°..."
	unzip -q "$filename"
	command rm "$filename"
	mv "$reponame-$branch" "$outdir"

	if [[ -z "$2" ]]; then
		cd "$outdir"
	fi

	echosuccess "Done!"
}

# Ask for an input with a simple prompt
function prompt() {
	local input=""
	
	if [[ $1 = "-s" ]]; then
		read -s "input?$2"
	else
		read "input?$1"
	fi

	echo "$input"
}

function humandate() {
	date '+%Y_%m_%d-%Hh_%Mm_%Ss'
}

function _filebak() {
	local itempath="${1%/}"

	if [[ ! -f "$itempath" && ! -d "$itempath" ]]; then
		echoerr "Provided path was not found: \z[green]°$itempath\z[]°"
		return 1
	fi

	local renpath="$itempath.bak-$(humandate)"

	${*:2} "$itempath" "$renpath"
	export LAST_FILEBAK_PATH="$renpath"
}

# Copy an item called <something> to <something>.bak-<timestamp>
function cpbak() {
	_filebak "$@" cp -r
}

# Move an item called <something> to <something>.bak-<timestamp>
function mvbak() {
	_filebak "$@" mv
}

# Compute the 32-bit checksum of a flat directory (= only files)
# Checksum will only be the same if the directory's filenames and content are equal
# Files order and timestamps are not taken into consideration
function cksumdir() {
	if [[ -f "$1" && ! -z "$ADF_ALLOW_CKSUM_FILE" ]]; then
		command cat "$1" | cksum
		return
	fi

	if [[ ! -d "$1" ]]; then
		echoerr "Input directory not found at path: \z[yellow]°$1\z[]°"
		return 1
	fi

	local checksums=""

	for item in "$1/"*; do
		local checksum=""
		local filenamesum=$(basename "$item" | cksum)

		if checksum=$(ADF_ALLOW_CKSUM_FILE=1 cksumdir "$item"); then
			checksums+="$filenamesum$checksum"
		else
			return 2
		fi
	done

	echo "$checksums" | cksum | cut -d ' ' -f 1
}

# Check if a command exists
function commandexists() {
	command -v "$1" > /dev/null 2>&1
}

# Inversed 'mv' (can be useful in situations where the source's name is automatically added to the command)
export invmv="/usr/local/bin/invmv"

if [[ ! -f "$invmv" ]]; then
	sudo sh -c "echo '#!/bin/bash' > '$invmv'"
	sudo sh -c "echo 'mv \"\$2\" \"\$1\"' >> '$invmv'"
	sudo sh -c "chmod +x '$invmv'"
fi
