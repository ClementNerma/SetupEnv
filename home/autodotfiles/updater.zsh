#
# This file exposes utilities for backuping and updating the environment
#

# Backup current environment
function zerbackup() {
	echoinfo "Backuping environment..."

	local old_env_loc=$(dirname "$ADF_DIR")
	local old_env_backup_dir="$old_env_loc/_adf-backup/Backup $(date '+%Y.%m.%d - %Hh %Mm %Ss')"
	mkdir -p "$old_env_backup_dir"

	while read item
	do
		# Security (should never happen, this check is here just in case)
		if [[ -z "$item" ]]; then
			continue
		fi

		if [[ -f "$old_env_loc/$item" || -d "$old_env_loc/$item" ]]; then
			cp -R "$old_env_loc/$item" "$old_env_backup_dir/$item"
		fi
	done < "$ADF_FILES_LIST"

	echoverb "Synchronizing..."
	sync

	# Done!
	export ADF_LAST_BACKUP_DIR="$old_env_backup_dir"
	echoinfo "Backup completed at \z[magenta]°$old_env_backup_dir\z[]°"
}

# Update to latest version
function zerupdate() {
	if [[ ! -z "$1" ]]; then
		echosuccess "Updating from provided path: \z[magenta]°$1\z[]°"
		local update_path="$1"
	else
		if [[ $ADF_CONF_MAIN_PERSONAL_COMPUTER = 1 ]]; then
			local update_path="$PROJDIR/AutoDotFiles"
		else
			echoerr "Please provide a path to update ZSH (default path is only available for main computer)"
			return 1
		fi
	fi

	if [[ ! -d "$update_path" ]] || [[ ! -f "$update_path/auto-install.bash" ]] || [[ ! -f "$update_path/home/.zshrc" ]]; then
		echoerr "Could not find \z[yellow]°AutoDotFiles\z[]° files at path \z[magenta]°$update_path\z[]°"
		return 1
	fi

	# Ensure line endings are Unix-compliant
	if ! dos2unix < "$update_path/home/.zshrc" | cmp -s "$update_path/home/.zshrc"; then
		echoerr "Line endings of the update directory are CRLF instead of LF"
		echoerr "       Update is aborted as wrong line endings would cause runtime errors."
		return 1
	fi

	# Backup current environment
	ADF_SILENT=1 zerbackup
	
	# Remove old files
	echoinfo "Removing old environment..."

	while read item
	do
		# Security (should never happen, this check is here just in case)
		if [[ -z "$item" ]]; then
			continue
		fi

		command rm -rf "$HOME/$(basename "$item")"
	done < "$ADF_FILES_LIST"

	# Copy updated files
	echoinfo "Updating environment..."
	cp -R "$update_path/home/." ~/

	# Save the new files list
	command ls -1A "$update_path/home" > "$ADF_FILES_LIST"

	# Restore local items
	cp -R "$ADF_LAST_BACKUP_DIR/autodotfiles-local" ~/

	# Update the restoration script
	echoverb "Updating the restoration script..."
	zerupdate_restoration_script

	# Load new environment
	echoinfo "Loading environment..."
	export ADF_JUST_UPDATED=1
	source "$ADF_DIR/index.zsh"

	# Done!
	echosuccess "Environment successfully updated!"
}

# Update to test local changes
function zerupdate_testing() {
	ADF_SILENT=1 zerupdate
}

# Download latest version and update
function zerupdate_online() {
	local tmpdir="/tmp/autodotfiles-update-$(date +%s%N)"

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

# Path to the uninstalled file
export UNINSTALLED_FILE="$HOME/.uninstalled-autodotfiles.txt"

# Update the restoration script
function zerupdate_restoration_script() {
	if [[ -f $UNINSTALLED_FILE ]]; then
		command rm "$UNINSTALLED_FILE"
	fi

	sudo cp "$ADF_DIR/restore.zsh" "$ADF_CONF_RESTORATION_SCRIPT"
	sudo chmod +x "$ADF_CONF_RESTORATION_SCRIPT"
}

# Uninstall AutoDotFiles
function zeruninstall() {
	zerbackup
	echo "$ADF_LAST_BACKUP_DIR" > "$UNINSTALLED_FILE"

	while read item
	do
		# Security (should never happen, this check is here just in case)
		if [[ -z "$item" ]]; then
			continue
		fi

		command rm -rf "$HOME/$item"
	done < "$ADF_FILES_LIST"

	echosuccess "AutoDotFiles was successfully installed!"
	echosuccess "To restore it, just type '\z[yellow]°zerrestore\z[]°'."
	echosuccess ""
	
	echoinfo "Press any key to continue..."
	read '?'

	exit
}
