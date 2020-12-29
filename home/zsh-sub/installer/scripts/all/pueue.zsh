
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_FD_GREPPER="armv7"
else
	_FD_GREPPER="x86_64"
fi

dlghrelease "Nukesor/pueue" "pueue-linux-$_FD_GREPPER" "$INSTALLER_TMPDIR/pueue"
dlghrelease "Nukesor/pueue" "pueued-linux-$_FD_GREPPER" "$INSTALLER_TMPDIR/pueued"

sudo chmod +x "$INSTALLER_TMPDIR/pueue"
sudo chmod +x "$INSTALLER_TMPDIR/pueued"

sudo mv "$INSTALLER_TMPDIR/pueue" /usr/bin/pueue
sudo mv "$INSTALLER_TMPDIR/pueued" /usr/bin/pueued

unset _FD_GREPPER