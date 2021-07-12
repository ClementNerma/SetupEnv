
if cat /etc/issue | grep "Ubuntu"; then
    sudo apt install python3-pip
    return
fi

sudo apt install -yqqq python3 python3-dev python-virtualenv
dl https://bootstrap.pypa.io/get-pip.py "$INSTALLER_TMPDIR/get-pip.py"
export PATH="$HOME/.local/bin:$PATH"
python3 "$INSTALLER_TMPDIR/get-pip.py"
sudo python3 "$INSTALLER_TMPDIR/get-pip.py"
pip3 install -U pip setuptools wheel