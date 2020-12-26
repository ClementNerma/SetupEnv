
sudo wget -q --show-progress https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl

_step "Installing FFMpeg and AtomicParsley for Youtube-DL..."
sudo apt install -yqqq ffmpeg atomicparsley
