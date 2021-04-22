if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	cargo install exa
	return
fi

dlghrelease "ogham/exa" "exa-linux-x86_64-.*.zip" "$INSTALLER_TMPDIR/exa.zip"

unzip "$INSTALLER_TMPDIR/exa.zip" -d "$INSTALLER_TMPDIR/exa"

mv "$INSTALLER_TMPDIR/exa/bin/exa" $ADF_BIN_DIR/exa