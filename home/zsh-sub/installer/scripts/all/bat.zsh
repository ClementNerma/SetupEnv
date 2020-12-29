
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
    _BAT_GREPPER="bat_.*_arm64.deb"
else
    _BAT_GREPPER="bat_.*_amd64.deb"
fi

dlghrelease "sharkdp/bat" "$_BAT_GREPPER" "$INSTALLER_TMPDIR/bat.deb"

sudo dpkg -i "$INSTALLER_TMPDIR/bat.deb"

unset _BAT_GREPPER