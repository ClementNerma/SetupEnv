#!/usr/bin/zsh

#
# This file contains commands and configuration which are specific to my main computer.
#

# Create project using hand-made template
function create-project () {
  cp -R "$PROJDIR/_Done/Templates/$1" "$2"
  cd "$2"
  zsh TEMPLATE_INIT.zsh
  command rm TEMPLATE_INIT.zsh
}

# Backup
function backupy() {
  	local backupy_path="$PROJDIR/_Done/Backupy/backupy.bash"

	if [[ ! -f "$backupy_path" ]]; then
		echoerr "Could not find \e[92mBackupy\e[91m files at path \e[93m$backupy_path"
		return 1
	fi

	bash "$backupy_path" $@
}

# Software: Android's Platform Tools
function adbtool() {
  local tool_path="$SOFTWAREDIR/PlatformTools"

  if [[ ! -f "$tool_path/$1" ]]; then
    echoerr "Could not find Platform Tools binary \e[93m$1\e[91m at path \e[93m$tool_path"
    return 1
  fi

  "$tool_path/$1" ${@:2}
}

alias adb="adbtool adb.exe"
alias fastboot="adbtool fastboot.exe"

# Provide Borg aliases with built-in passphrase
alias withborgpass="BORG_PASSPHRASE=\"\$(command cat \$PROJDIR/_Done/Backupy/BORG_PASSPHRASE.txt)\""

alias borg="withborgpass borg"
alias borgfs="withborgpass borgfs"
alias borgmatic="withborgpass borgmatic"
