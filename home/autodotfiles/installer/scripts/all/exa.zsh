if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_EXA_GREPPER="armv7"
else
	_EXA_GREPPER="x86_64"
fi

dlghrelease "ogham/exa" "exa-linux-$_EXA_GREPPER-.*.zip" "$INSTALLER_TMPDIR/exa.zip"

unzip "$INSTALLER_TMPDIR/exa.zip" -d "$INSTALLER_TMPDIR/exa"

mv "$INSTALLER_TMPDIR/exa/bin/exa" $ADF_BIN_DIR/exa

unset _EXA_GREPPER