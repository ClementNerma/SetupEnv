dl https://yt-dl.org/downloads/latest/youtube-dl "$ADF_BIN_DIR/youtube-dl"
sudo chmod a+rx "$ADF_BIN_DIR/youtube-dl"

_step "Installing FFMpeg and AtomicParsley for Youtube-DL..."
sudo apt install -yqqq ffmpeg atomicparsley
