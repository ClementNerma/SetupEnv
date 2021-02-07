dlghrelease "mikefarah/yq" "yq_linux_amd64" "$INSTALLER_TMPDIR/yq"
chmod +x "$INSTALLER_TMPDIR/yq"
sudo mv "$INSTALLER_TMPDIR/yq" /usr/local/bin/yq
