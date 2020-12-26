
if [[ $IS_WSL_ENV = 1 ]]; then
    mkdir -p "$YTDL_WSL_PATH"

    if [[ ! -f "$YOUTUBEDL_BIN_PATH" ]]; then
        _step "Downloading Youtube-DL..."
        sudo wget -q --show-progress https://yt-dl.org/downloads/latest/youtube-dl.exe -O "$YOUTUBEDL_BIN_PATH"
    fi

    if [[ ! -f "$FFMPEG_BIN_PATH" || ! -f "$FFPLAY_BIN_PATH" || ! -f "$FFPROBE_BIN_PATH" ]]; then
        _step "Downloading FFMpeg..."
        sudo wget -q --show-progress https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip -O "$YTDL_WSL_PATH/ffmpeg.zip"
        _step "Extracting FFMpeg..."
        sudo unzip -qq "$YTDL_WSL_PATH/ffmpeg.zip" -d "$YTDL_WSL_PATH/FFMpegExtracted"
        sudo rm "$YTDL_WSL_PATH/ffmpeg.zip"
        sudo mv $YTDL_WSL_PATH/FFMpegExtracted/ffmpeg*/bin/ffmpeg.exe "$FFMPEG_BIN_PATH"
        sudo mv $YTDL_WSL_PATH/FFMpegExtracted/ffmpeg*/bin/ffplay.exe "$FFPLAY_BIN_PATH"
        sudo mv $YTDL_WSL_PATH/FFMpegExtracted/ffmpeg*/bin/ffprobe.exe "$FFPROBE_BIN_PATH"
        sudo rm -rf "$YTDL_WSL_PATH/FFMpegExtracted"
    fi

    if [[ ! -f "$ATOMICPARSLEY_BIN_PATH" ]]; then
        _step "Downloading AtomicParsley..."
        sudo wget -q --show-progress https://netix.dl.sourceforge.net/project/atomicparsley/atomicparsley/AtomicParsley%20v0.9.0/AtomicParsley-win32-0.9.0.zip -O "$YTDL_WSL_PATH/AtomicParsley.zip"
        _step "Extracting AtomicParsley..."
        sudo unzip -qq "$YTDL_WSL_PATH/AtomicParsley.zip" -d "$YTDL_WSL_PATH/AtomicParsleyExtracted"
        sudo rm "$YTDL_WSL_PATH/AtomicParsley.zip"
        sudo mv "$YTDL_WSL_PATH/AtomicParsleyExtracted/AtomicParsley-win32-0.9.0/AtomicParsley.exe" "$ATOMICPARSLEY_BIN_PATH"
        sudo rm -rf "$YTDL_WSL_PATH/AtomicParsleyExtracted"
    fi

    sudo chmod +x $YTDL_WSL_PATH/*.exe

    return
fi

sudo wget -q --show-progress https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl

_step "Installing FFMpeg and AtomicParsley for Youtube-DL..."
sudo apt install -yqqq ffmpeg atomicparsley
