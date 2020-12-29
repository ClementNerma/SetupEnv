
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_FD_GREPPER="armv7"
else
	_FD_GREPPER="x86_64"
fi

curl -s https://api.github.com/repos/Nukesor/pueue/releases/latest \
	| grep "browser_download_url.*pueue-linux-$_FD_GREPPER" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/pueue"

curl -s https://api.github.com/repos/Nukesor/pueue/releases/latest \
	| grep "browser_download_url.*pueued-linux-$_FD_GREPPER" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/pueued"

sudo chmod +x "$INSTALLER_TMPDIR/pueue"
sudo chmod +x "$INSTALLER_TMPDIR/pueued"

sudo mv "$INSTALLER_TMPDIR/pueue" /usr/bin/pueue
sudo mv "$INSTALLER_TMPDIR/pueued" /usr/bin/pueued

unset _FD_GREPPER