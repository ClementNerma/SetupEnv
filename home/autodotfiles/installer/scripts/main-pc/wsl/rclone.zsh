
dlghrelease "rclone/rclone" "rclone-.*-windows-amd64" "$INSTALLER_TMPDIR/rclone.zip"
unzip "$INSTALLER_TMPDIR/rclone.zip" -d "$INSTALLER_TMPDIR/rclone"
sudo mv "$INSTALLER_TMPDIR/rclone/rclone-"*"/rclone.exe" "$ADF_BIN_DIR/rclone.exe"
chmod +x "$ADF_BIN_DIR/rclone.exe"
