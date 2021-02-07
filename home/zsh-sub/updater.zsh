#
# This file exposes utilities for backuping and updating the environment
#

# Backup current environment
function zerbackup() {
	echo -e "\e[94mBackuping environment..."

	local old_env_loc=$(dirname "$ZSH_SUB_DIR")
	local old_env_backup_dir="$old_env_loc/_setupenv-update-backup/Backup $(date '+%Y.%m.%d - %Hh %Mm %Ss')"
	mkdir -p "$old_env_backup_dir"

	setopt GLOB_DOTS

	for item_abs in "$update_path/home/"*
	do
		local item="$(basename "$item_abs")"

		if [[ $item = ".config" ]]; then continue; fi

		if [[ -f "$old_env_loc/$item" || -d "$old_env_loc/$item" ]]; then
			cp -R "$old_env_loc/$item" "$old_env_backup_dir/$item"
		fi
	done

	unsetopt GLOB_DOTS

	# Done!
	export LAST_SETUPENV_BACKUP_DIR="$old_env_backup_dir"
	echo -e "\e[94mBackup completed at \e[95m$old_env_backup_dir"
}

# Update to latest version
function zerupdate() {
	if [[ ! -z "$1" ]]; then
		echosuccess "Updating from provided path: \e[95m$1"
		local update_path="$1"
	else
		if [[ $ZSH_MAIN_PERSONAL_COMPUTER = 1 ]]; then
			local update_path="$PROJDIR/_Done/SetupEnv"
		else
			echoerr "Please provide a path to update ZSH (default path is only available for main computer)"
			return 1
		fi
	fi

	if [[ ! -d "$update_path" ]] || [[ ! -f "$update_path/auto-install.bash" ]] || [[ ! -f "$update_path/home/.zshrc" ]]; then
		echoerr "Could not find \e[92mSetup Environment\e[91m files at path \e[95m$update_path"
		return 1
	fi

	# Ensure line endings are Unix-compliant
	if ! dos2unix < "$update_path/home/.zshrc" | cmp -s "$update_path/home/.zshrc"; then
		echoerr "Line endings of the update directory are CRLF instead of LF"
		echoerr "       Update is aborted as wrong line endings would cause runtime errors."
		return 1
	fi

	# Backup current environment
	zerbackup

	# Remove old files
	echosuccess "Removing old environment..."
	setopt globdots
	for item in "$update_path/home/"*
	do
		# Security (should never happen, this check is here just in case)
		if [[ -z "$(basename "$item")" ]]; then
			echoerr "Empty item name in update path!"
			continue
		fi

		command rm -rf "$HOME/$(basename "$item")"
	done
	unsetopt globdots

	# Copy updated files
	echosuccess "Updating environment..."
	cp -R "$update_path/home/." ~/
	
	# Restore it so it hasn't been overriden by the previous command
	if [[ $OVERWRITE_LOCAL_SCRIPTS != 1 ]]; then
		cp -R "$LAST_SETUPENV_BACKUP_DIR/zsh-sub/local" "$ZSH_SUB_DIR/"
	fi

	# Load new environment
	echosuccess "Loading environment..."
	source "$ZSH_SUB_DIR/index.zsh"

	# Done!
	echosuccess "Environment successfully updated!"
}

# Download latest version and update
function zerupdate_online() {
	# Create a temporary directory
	local tmpdir="/tmp/_setupenv_updater_$(date +%s)"
	command rm -rf "$tmpdir"
	mkdir -p "$tmpdir"

	# Determine URL for latest version
	if [[ ! -z "$1" ]]; then
		echoinfo "Updating from provided URL: \e[95m$1"
		local setupenv_url="$1"
	else
		local setupenv_url="https://codeload.github.com/ClementNerma/SetupEnv/zip/master"
	fi

	# Download latest version
	echoinfo "Downloading latest environment..."

	local setupenv_zip_path="$tmpdir/setupenv.zip"

	if ! dl "$setupenv_url" "$setupenv_zip_path"; then
		echoerr "Download failed."
		return 1
	fi

	# Extract the downloaded archive
	echoinfo "Extracting..."

	if ! unzip -q "$setupenv_zip_path" -d "$tmpdir/setupenv"; then
		echoerr "Archive extraction failed!"
		return 1
	fi

	# Update the environment
	zerupdate "$tmpdir/setupenv/setupenv-master"

	# Clean up
	echoinfo "Cleaning up temporary directory..."
	command rm -rf "$tmpdir"

	# Done!
	echosuccess "Done!"	
}