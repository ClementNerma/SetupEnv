
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_ZOXIDE_GREPPER="zoxide-armv7-unknown-linux-musleabihf"
else
	_ZOXIDE_GREPPER="zoxide-x86_64-unknown-linux-gnu"
fi

curl -s https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest \
	| grep "browser_download_url.*$_ZOXIDE_GREPPER" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/zoxide"

sudo mv "$INSTALLER_TMPDIR/zoxide" /usr/local/bin/zoxide

sudo chmod +x /usr/local/bin/zoxide