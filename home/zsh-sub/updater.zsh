#
# This file exposes utilities for backuping and updating the environment
#

# Backup current environment
function zerbackup() {
	echo -e "\e[94mBackuping environment...\e[0m"

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
	echo -e "\e[94mBackup completed at \e[95m$old_env_backup_dir\e[0m"
}

# Update to latest version
function zerupdate() {
	if [[ ! -z "$1" ]]; then
		echo -e "\e[92mUpdating from provided path: \e[95m$1\e[0m"
		local update_path="$1"
	else
		if [[ $ZSH_MAIN_PERSONAL_COMPUTER = 1 ]]; then
			local update_path="$PROJDIR/_Done/Setup Environment"
		else
			echo -e "\e[91mERROR: Please provide a path to update ZSH (default path is only available for main computer)\e[0m"
			return 1
		fi
	fi

	if [[ ! -d "$update_path" ]] || [[ ! -f "$update_path/auto-install.bash" ]] || [[ ! -f "$update_path/home/.zshrc" ]]; then
		echo -e "\e[91mERROR: Could not find \e[92mSetup Environment\e[91m files at path \e[95m$update_path\e[0m"
		return 1
	fi

	# Ensure line endings are Unix-compliant
	if ! dos2unix < "$update_path/home/.zshrc" | cmp -s "$update_path/home/.zshrc"; then
		echo -e "\e[91mERROR: Line endings of the update directory are CRLF instead of LF\e[0m"
		echo -e "\e[91m       Update is aborted as wrong line endings would cause runtime errors.\e[0m"
		return 1
	fi

	# Backup current environment
	zerbackup

	# Copy updated files
	echo -e "\e[92mUpdating environment...\e[0m"
	cp -R "$update_path/home/." ~/
	
	# Restore it so it hasn't been overriden by the previous command
	if [[ $OVERWRITE_LOCAL_SCRIPTS != 1 ]]; then
		cp -R "$LAST_SETUPENV_BACKUP_DIR/zsh-sub/local" "$ZSH_SUB_DIR/"
	fi

	# Load new environment
	echo -e "\e[92mLoading environment...\e[0m"
	source "$ZSH_SUB_DIR/index.zsh"

	# Done!
	echo -e "\e[92mEnvironment successfully updated!\e[0m"
}

# Download latest version and update
function zeronline() {
	# Create a temporary directory
	local tmpdir="/tmp/_setupenv_updater_$(date +%s)"
	command rm -rf "$tmpdir"
	mkdir -p "$tmpdir"

	# Determine URL for latest version
	if [[ ! -z "$1" ]]; then
		echo -e "\e[93mUpdating from provided URL: \e[95m$1\e[0m"
		local setupenv_url="$1"
	else
		local setupenv_url="https://codeload.github.com/ClementNerma/SetupEnv-Private/zip/master"
	fi

	# Download latest version
	echo -e "\e[93mDownloading latest environment...\e[0m"

	local setupenv_zip_path="$tmpdir/setupenv.zip"

	if ! wget --show-progress "$setupenv_url" -O "$setupenv_zip_path"; then
		echo -e "\e[91mERROR: Download failed.\e[0m"
		return 1
	fi

	# Extract the downloaded archive
	echo -e "\e[93mExtracting...\e[0m"

	if ! unzip -q "$setupenv_zip_path" -d "$tmpdir/setupenv"; then
		echo -e "\e[91mERROR: Archive extraction failed!\e[0m"
		return 1
	fi

	# Update the environment
	zerupdate "$tmpdir/setupenv/setupenv-master"

	# Clean up
	echo -e "\e[93mCleaning up temporary directory...\e[0m"
	command rm -rf "$tmpdir"

	# Done!
	echo -e "\e[92mDone!\e[0m"	
}