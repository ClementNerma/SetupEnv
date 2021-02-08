if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	cargo install trasher
	return
fi

dlghrelease "ClementNerma/Trasher" "trasher-linux-x86_64" "$INSTALLER_TMPDIR/trasher.zip"

unzip "$INSTALLER_TMPDIR/trasher.zip" -d "$INSTALLER_TMPDIR/trasher"
sudo mv "$INSTALLER_TMPDIR/trasher/"trasher /usr/local/bin/trasher
sudo chmod +x /usr/local/bin/trasher
