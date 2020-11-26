
if [[ $(dpkg --print-architecture) = "arm64" ]]; then
	cargo install exa
	return
fi

curl -s https://api.github.com/repos/ogham/exa/releases/latest \
	| grep "browser_download_url.*exa-linux-x86_64-.*.zip" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$INSTALLER_TMPDIR/exa.zip"

unzip "$INSTALLER_TMPDIR/exa.zip" -d "$INSTALLER_TMPDIR/exa"

sudo mv "$INSTALLER_TMPDIR/exa/"exa-* /usr/local/bin/exa