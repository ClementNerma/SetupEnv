#
# This file exposes utilities for backuping and updating the environment
#

# Backup current environment
function zerbackup() {
	echo -e "\e[94mBackuping environment..."

	local old_env_loc=$(dirname "$ADF_SUB_DIR")
	local old_env_backup_dir="$old_env_loc/_adf-backup/Backup $(date '+%Y.%m.%d - %Hh %Mm %Ss')"
	mkdir -p "$old_env_backup_dir"

	while read item
	do
		# Security (should never happen, this check is here just in case)
		if [[ -z "$item" ]]; then
			continue
		fi

		if [[ $item = ".config" ]]; then continue; fi

		if [[ -f "$old_env_loc/$item" || -d "$old_env_loc/$item" ]]; then
			cp -R "$old_env_loc/$item" "$old_env_backup_dir/$item"
		fi
	done < "$ADF_FILES_LIST"

	# Done!
	export ADF_LAST_BACKUP_DIR="$old_env_backup_dir"
	echo -e "\e[94mBackup completed at \e[95m$old_env_backup_dir"
}

# Update to latest version
function zerupdate() {
	if [[ ! -z "$1" ]]; then
		echosuccess "Updating from provided path: \e[95m$1"
		local update_path="$1"
	else
		if [[ $ADF_MAIN_PERSONAL_COMPUTER = 1 ]]; then
			local update_path="$PROJDIR/_Done/AutoDotFiles"
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

	while read item
	do
		# Security (should never happen, this check is here just in case)
		if [[ -z "$item" ]]; then
			continue
		fi

		command rm -rf "$HOME/$(basename "$item")"
	done < "$ADF_FILES_LIST"

	# Copy updated files
	echosuccess "Updating environment..."
	cp -R "$update_path/home/." ~/

	# Restore the local data scripts
	if [[ $OVERWRITE_LOCAL_SCRIPTS != 1 ]]; then
		cp -R "$ADF_LAST_BACKUP_DIR/zsh-sub/local" "$ADF_SUB_DIR/"
	fi

	# Save the new files list
	command ls -1A "$update_path/home" > "$ADF_FILES_LIST"

	# Update the restoration script
	echosuccess "Updating the restoration script..."
	zerupdate_restoration_script

	# Load new environment
	echosuccess "Loading environment..."
	source "$ADF_SUB_DIR/index.zsh"

	# Done!
	echosuccess "Environment successfully updated!"
}

# Download latest version and update
function zerupdate_online() {
	local tmpdir="/tmp/autodtofiles-update-$(date +%s)"

	# Download the update from GitHub
	if ! ghdl "ClementNerma/AutoDotFiles" "$tmpdir"; then
		return 1
	fi

	# Update the environment
	zerupdate "$tmpdir"

	# Clean up
	echoinfo "Cleaning up temporary directory..."
	command rm -rf "$tmpdir"

	# Done!
	echosuccess "Done!"	
}

# Update the restoration script
function zerupdate_restoration_script() {
	sudo cp "$ADF_SUB_DIR/restore.zsh" "$ADF_RESTORATION_SCRIPT"
	sudo chmod +x "$ADF_RESTORATION_SCRIPT"
}

# Uninstall AutoDotFiles
function zeruninstall() {
	zerbackup
	echo "$ADF_LAST_BACKUP_DIR" > "$HOME/.uninstalled-autodotfiles.txt"
	echosuccess "AutoDotFiles was successfully installed!"
	echosuccess "To restore it, just type '\e[93mzerrestore\e[92m'."

	command rm -rf "$ADF_SUB_DIR"
	command rm ~/.bashrc
	command rm ~/.zshrc
	command rm ~/.p10k.zsh

	exit
}
