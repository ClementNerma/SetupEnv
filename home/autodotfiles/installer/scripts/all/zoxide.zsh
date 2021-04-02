if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_ZOXIDE_GREPPER="zoxide-armv7-unknown-linux-musleabihf"
else
	_ZOXIDE_GREPPER="zoxide-x86_64-unknown-linux-gnu"
fi

dlghrelease "ajeetdsouza/zoxide" "$_ZOXIDE_GREPPER" "$ADF_BIN_DIR/zoxide"

chmod +x "$ADF_BIN_DIR/zoxide"