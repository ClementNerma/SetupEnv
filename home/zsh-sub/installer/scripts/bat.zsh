
curl -s https://api.github.com/repos/sharkdp/bat/releases/latest \
    | grep "browser_download_url.*bat_.*_amd64.deb" \
    | cut -d : -f 2,3 \
    | tr -d \" \
    | wget -qi - --show-progress -O "$INSTALLER_TMPDIR/bat.deb"

sudo dpkg -i "$INSTALLER_TMPDIR/bat.deb"
