
# Arguments: "<url>" "<download location>"
function dl() {
    if [[ ! -z "$2" ]]; then
        curl --silent --progress-bar -o "$2" "$1" "${@:3}"
    else
        curl --silent --progress-bar "$@"
    fi
}

function sudodl() {
    if [[ ! -z "$2" ]]; then
        sudo curl --silent --progress-bar -o "$2" "$1" "${@:3}"
    else
        sudo curl --silent --progress-bar "$@"
    fi
}

# Download files whose URL will be provided through STDIN
# Arguments: "<download location>"
function dli() { wget -qi - --show-progress -O "$1" }
function sudodli() { sudo wget -qi - --show-progress -O "$1" }

# Download a file from the latest of a GitHub repository
# Arguments: "<repo author>/<reponame>" "<file grep pattern>" "<download location>"
function dlghrelease() {
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

	echoc "\z[blue]°> Fetching default branch...\z[]°"
	local branch=$(curl -s "https://api.github.com/repos/$repoauthor/$reponame" | jq -r ".default_branch")

	if [[ $branch == "null" ]]; then
		echoerr "> Failed to determine default branch!"
		return 1
	fi

	local filename="$reponame-$(date +%s).zip"
	echoc "\z[blue]°> Fetching archive for branch \z[yellow]°$branch\z[]° to \z[magenta]°$filename\z[]°...\z[]°"
	
	local zipurl="https://codeload.github.com/$repoauthor/$reponame/zip/$branch"

	if ! dl "$zipurl" "$filename"; then
		echoerr "> Failed to fetch archive from URL: \z[yellow]°$zipurl\z[]°!"
		return 1
	fi

	echoc "\z[blue]°> Extracting archive to directory \z[yellow]°$outdir\z[]°...\z[]°"
	unzip -q "$filename"
	command rm "$filename"
	mv "$reponame-$branch" "$outdir"

	if [[ -z "$2" ]]; then
		cd "$outdir"
	fi

	echosuccess "Done!"
}

function _filebak() {
	local itempath="${1%/}"

	if [[ ! -f "$itempath" && ! -d "$itempath" ]]; then
		echoerr "Provided path was not found: \z[green]°$itempath\z[]°"
		return 1
	fi

	local renpath="$itempath.bak-$(date '+%Y_%m_%d-%H_%M_%S')"

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

# Inversed 'mv' (can be useful in situations where the source's name is automatically added to the command)
export invmv="/usr/local/bin/invmv"

if [[ ! -f "$invmv" ]]; then
	sudo sh -c "echo '#!/bin/bash' > '$invmv'"
	sudo sh -c "echo 'mv \"\$2\" \"\$1\"' >> '$invmv'"
	sudo sh -c "chmod +x '$invmv'"
fi
