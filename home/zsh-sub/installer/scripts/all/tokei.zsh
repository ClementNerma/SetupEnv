
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_TOKEI_GREPPER="tokei-aarch64-linux-android.tar.gz"
else
	_TOKEI_GREPPER="tokei-x86_64-unknown-linux-gnu.tar.gz"
fi

dlghrelease "XAMPPRocky/tokei" "$_TOKEI_GREPPER" "$INSTALLER_TMPDIR/tokei.tar.gz"
tar zxf "$INSTALLER_TMPDIR/tokei.tar.gz"

sudo mv tokei /usr/local/bin

unset _TOKEI_GREPPER