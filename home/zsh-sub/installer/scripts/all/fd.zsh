
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_FD_GREPPER="fd-musl_.*_armhf.deb"
else
	_FD_GREPPER="fd-musl_.*_amd64.deb"
fi

curl -s https://api.github.com/repos/sharkdp/fd/releases/latest \
	| grep "browser_download_url.*$_FD_GREPPER" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/fd.deb"

sudo dpkg -i "$INSTALLER_TMPDIR/fd.deb"

unset _FD_GREPPER