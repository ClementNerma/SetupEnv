
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_ZOXIDE_GREPPER="zoxide-armv7-unknown-linux-musleabihf"
else
	_ZOXIDE_GREPPER="zoxide-x86_64-unknown-linux-gnu"
fi

dlghrelease "ajeetdsouza/zoxide" "$_ZOXIDE_GREPPER" "$INSTALLER_TMPDIR/zoxide"

sudo mv "$INSTALLER_TMPDIR/zoxide" /usr/local/bin/zoxide

sudo chmod +x /usr/local/bin/zoxide