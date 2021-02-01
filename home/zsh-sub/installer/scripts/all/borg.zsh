
if [[ $ZER_UPDATING = 0 ]]; then
    _step "Installing dependencies..."
    sudo apt install libacl1-dev libacl1 liblz4-dev libzstd1 libzstd-dev liblz4-1 libb2-1 libb2-dev -y
fi

_step "Installing Borg..."
sudo pip3 install --upgrade "borgbackup[fuse]"

_step "Installing Borgmatic..."
sudo pip3 install --upgrade "borgmatic"
