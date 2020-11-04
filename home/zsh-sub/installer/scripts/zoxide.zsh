
curl -s https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest \
	| grep "browser_download_url.*zoxide-x86_64-unknown-linux-gnu" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/zoxide"

sudo mv "$INSTALLER_TMPDIR/zoxide" /usr/local/bin/zoxide

sudo chmod +x /usr/local/bin/zoxide