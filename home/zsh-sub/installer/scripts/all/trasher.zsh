if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	ghdl "ClementNerma/Trasher" "$INSTALLER_TMPDIR/trasher"
	cargo build --release --manifest-path="$INSTALLER_TMPDIR/trasher/Cargo.toml"
	sudo mv "$INSTALLER_TMPDIR/trasher/target/release/trasher" /usr/local/bin/trasher
	command rm -rf "$INSTALLER_TMPDIR/trasher"
	return
fi

dlghrelease "ClementNerma/Trasher" "trasher-linux-x86_64" "$INSTALLER_TMPDIR/trasher.zip"

unzip "$INSTALLER_TMPDIR/trasher.zip" -d "$INSTALLER_TMPDIR/trasher"
sudo mv "$INSTALLER_TMPDIR/trasher/"trasher /usr/local/bin/trasher
sudo chmod +x /usr/local/bin/trasher
