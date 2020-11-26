
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
    _BAT_GREPPER="bat_.*_arm64.deb"
else
    _BAT_GREPPER="bat_.*_amd64.deb"
fi

curl -s https://api.github.com/repos/sharkdp/bat/releases/latest \
    | grep "browser_download_url.*$_BAT_GREPPER" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi - --show-progress -O "$INSTALLER_TMPDIR/bat.deb"

sudo dpkg -i "$INSTALLER_TMPDIR/bat.deb"

unset _BAT_GREPPER