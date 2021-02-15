if [[ $(dpkg --print-architecture) = "arm64" ]]; then
    dlghrelease "mikefarah/yq" "yq_linux_arm64" "$INSTALLER_TMPDIR/yq"
else
    dlghrelease "mikefarah/yq" "yq_linux_amd64" "$INSTALLER_TMPDIR/yq"
fi

chmod +x "$INSTALLER_TMPDIR/yq"
sudo mv "$INSTALLER_TMPDIR/yq" /usr/local/bin/yq
