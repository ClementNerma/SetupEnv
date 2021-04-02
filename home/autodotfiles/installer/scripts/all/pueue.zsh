if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_PUEUE_GREPPER="armv7"
else
	_PUEUE_GREPPER="x86_64"
fi

dlghrelease "Nukesor/pueue" "pueue-linux-$_PUEUE_GREPPER" "$ADF_BIN_DIR/pueue"
dlghrelease "Nukesor/pueue" "pueued-linux-$_PUEUE_GREPPER" "$ADF_BIN_DIR/pueued"

sudo chmod +x "$ADF_BIN_DIR/pueue"
sudo chmod +x "$ADF_BIN_DIR/pueued"

unset _PUEUE_GREPPER