
curl -s https://api.github.com/repos/ClementNerma/Trasher/releases/latest \
	| grep "browser_download_url.*trasher-linux-x86_64" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/trasher.zip"

unzip "$INSTALLER_TMPDIR/trasher.zip" -d "$INSTALLER_TMPDIR/trasher"
sudo mv "$INSTALLER_TMPDIR/trasher/"trasher /usr/local/bin/trasher
sudo chmod +x /usr/local/bin/trasher
