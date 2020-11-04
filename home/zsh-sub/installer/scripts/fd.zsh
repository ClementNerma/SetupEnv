
curl -s https://api.github.com/repos/sharkdp/fd/releases/latest \
	| grep "browser_download_url.*fd-musl_.*_amd64.deb" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/fd.deb"

sudo dpkg -i "$INSTALLER_TMPDIR/fd.deb"