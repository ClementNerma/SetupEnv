if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_ZOXIDE_GREPPER="zoxide-armv7-unknown-linux-musleabihf"
else
	_ZOXIDE_GREPPER="zoxide-x86_64-unknown-linux-musl"
fi

dlghrelease "ajeetdsouza/zoxide" "$_ZOXIDE_GREPPER" "$INSTALLER_TMPDIR/zoxide.tar.gz"
tar zxf "$INSTALLER_TMPDIR/zoxide.tar.gz" -C "$INSTALLER_TMPDIR"
mv "$INSTALLER_TMPDIR/$_ZOXIDE_GREPPER/zoxide" "$ADF_BIN_DIR/zoxide"

chmod +x "$ADF_BIN_DIR/zoxide"