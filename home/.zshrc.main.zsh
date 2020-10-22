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
  local tool_path="$SOFTWAREDIR/PlatformTools"

  if [[ ! -f "$tool_path/$1" ]]; then
    echo -e "\e[91mERROR: Could not find Platform Tools binary \e[93m$1\e[91m at path \e[93m$tool_path\e[0m"
    return
  fi

  "$tool_path/$1" ${@:2}
}

alias adb="adbtool adb.exe"
alias fastboot="adbtool fastboot.exe"

# Provide Borg aliases with built-in passphrase
alias borg="BORG_PASSPHRASE=\"\$(command cat \$PROJDIR/_Done/Backupy/BORG_PASSPHRASE.txt)\" borg"
alias borgmatic="BORG_PASSPHRASE=\"\$(command cat \$PROJDIR/_Done/Backupy/BORG_PASSPHRASE.txt)\" borgmatic"

# Allow fast editing of this file
alias zermain="nano ~/.zshrc.main.zsh && source ~/.zshrc.main.zsh"