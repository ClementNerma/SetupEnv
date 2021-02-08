if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_FD_GREPPER="fd-musl_.*_armhf.deb"
else
	_FD_GREPPER="fd-musl_.*_amd64.deb"
fi

dlghrelease "sharkdp/fd" "$_FD_GREPPER" "$INSTALLER_TMPDIR/fd.deb"

sudo dpkg -i "$INSTALLER_TMPDIR/fd.deb"

unset _FD_GREPPER