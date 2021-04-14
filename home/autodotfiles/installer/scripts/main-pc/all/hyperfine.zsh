if [[ $(dpkg --print-architecture) = "arm64" ]]; then
    _HYPERFINE_GREPPER="hyperfine_.*_arm64.deb"
else
    _HYPERFINE_GREPPER="hyperfine_.*_amd64.deb"
fi

dlghrelease "sharkdp/hyperfine" "$_HYPERFINE_GREPPER" "$INSTALLER_TMPDIR/hyperfine.deb"

sudo dpkg -i "$INSTALLER_TMPDIR/hyperfine.deb"

unset _HYPERFINE_GREPPER