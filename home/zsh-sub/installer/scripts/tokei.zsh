
curl -s https://api.github.com/repos/XAMPPRocky/tokei/releases/latest \
	| grep "browser_download_url.*tokei-x86_64-unknown-linux-gnu.tar.gz" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/tokei.tar.gz"

tar zxf "$INSTALLER_TMPDIR/tokei.tar.gz"

sudo mv tokei /usr/local/bin
