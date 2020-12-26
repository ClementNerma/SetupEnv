
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	_TOKEI_GREPPER="tokei-x86_64-unknown-linux-gnu.tar.gz"
else
	_TOKEI_GREPPER="tokei-aarch64-linux-android.tar.gz"
fi

curl -s https://api.github.com/repos/XAMPPRocky/tokei/releases/latest \
	| grep "browser_download_url.*$_TOKEI_GREPPER" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/tokei.tar.gz"

tar zxf "$INSTALLER_TMPDIR/tokei.tar.gz"

sudo mv tokei /usr/local/bin

unset _TOKEI_GREPPER