#!/usr/bin/zsh

#
# This file contains commands and configuration which are specific to my main computer.
#

# Create project using hand-made template
function create-project () {
  cp -R "$PROJDIR/_Done/Templates/$1" "$2"
  cd "$2"
  zsh TEMPLATE_INIT.zsh
  rm TEMPLATE_INIT.zsh
}

# Update to latest version
function zerupdate() {
	local update_path="$PROJDIR/_Done/Setup Environment"

	if [[ ! -d "$update_path" ]] || [[ ! -f "$update_path/auto-install.bash" ]] || [[ ! -f "$update_path/home/.zshrc.lib.zsh" ]]; then
		echo -e "\e[91mERROR: Could not find \e[92mSetup Environment\e[91m files at path \e[93m$update_path\e[0m"
		return
	fi

	echo -e "\e[92mUpdating environment...\e[0m"

	# Backup local file
	mv ~/.zshrc.this.zsh ~/.zshrc.this.zsh.staging

	# Copy updated files
	cp -R "$update_path/home/." ~/

	# Restore it so it hasn't been overriden by the previous command
	mv ~/.zshrc.this.zsh.staging ~/.zshrc.this.zsh
	source ~/.zshrc.lib.zsh
	echo -e "\e[92mDone!\e[0m"
}

# Backup
function backupy() {
  	local backupy_path="$PROJDIR/_Done/Backupy/backupy.bash"

	if [[ ! -f "$backupy_path" ]]; then
		echo -e "\e[91mERROR: Could not find \e[92mBackupy\e[91m files at path \e[93m$backupy_path\e[0m"
		return
	fi

	bash "$backupy_path" $@
}

# Software: Android's Platform Tools
function adbtool() {
  local tool_path="$SFWDIR/PlatformTools"

  if [[ ! -f "$tool_path/$1" ]]; then
    echo -e "\e[91mERROR: Could not find Platform Tools binary \e[93m$1\e[91m at path \e[93m$tool_path\e[0m"
    return
  fi

  "$tool_path/$1" ${@:2}
}

alias adb="adbtool adb.exe"
alias fastboot="adbtool fastboot.exe"

# Allow fast editing of this file
alias zerty="nano ~/.zshrc.main.zsh && source ~/.zshrc.main.zsh"