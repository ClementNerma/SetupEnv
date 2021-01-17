mkdir -p "$YTDL_WSL_PATH"

if [[ $ZER_UPDATING = 1 || ! -f "$YOUTUBEDL_BIN_PATH" ]]; then
    _step "Downloading Youtube-DL..."
    sudodl https://yt-dl.org/downloads/latest/youtube-dl.exe "$YOUTUBEDL_BIN_PATH"
fi

if [[ $ZER_UPDATING = 1 || ! -f "$FFMPEG_BIN_PATH" || ! -f "$FFPLAY_BIN_PATH" || ! -f "$FFPROBE_BIN_PATH" ]]; then
    _step "Downloading FFMpeg..."
    sudodl https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip "$YTDL_WSL_PATH/ffmpeg.zip"
    _step "Extracting FFMpeg..."
    sudo unzip -qq "$YTDL_WSL_PATH/ffmpeg.zip" -d "$YTDL_WSL_PATH/FFMpegExtracted"
    sudo rm "$YTDL_WSL_PATH/ffmpeg.zip"
    sudo mv $YTDL_WSL_PATH/FFMpegExtracted/ffmpeg*/bin/ffmpeg.exe "$FFMPEG_BIN_PATH"
    sudo mv $YTDL_WSL_PATH/FFMpegExtracted/ffmpeg*/bin/ffplay.exe "$FFPLAY_BIN_PATH"
    sudo mv $YTDL_WSL_PATH/FFMpegExtracted/ffmpeg*/bin/ffprobe.exe "$FFPROBE_BIN_PATH"
    sudo rm -rf "$YTDL_WSL_PATH/FFMpegExtracted"
fi

if [[ $ZER_UPDATING = 1 || ! -f "$ATOMICPARSLEY_BIN_PATH" ]]; then
    _step "Downloading AtomicParsley..."
    sudodl https://netix.dl.sourceforge.net/project/atomicparsley/atomicparsley/AtomicParsley%20v0.9.0/AtomicParsley-win32-0.9.0.zip "$YTDL_WSL_PATH/AtomicParsley.zip"
    _step "Extracting AtomicParsley..."
    sudo unzip -qq "$YTDL_WSL_PATH/AtomicParsley.zip" -d "$YTDL_WSL_PATH/AtomicParsleyExtracted"
    sudo rm "$YTDL_WSL_PATH/AtomicParsley.zip"
    sudo mv "$YTDL_WSL_PATH/AtomicParsleyExtracted/AtomicParsley-win32-0.9.0/AtomicParsley.exe" "$ATOMICPARSLEY_BIN_PATH"
    sudo rm -rf "$YTDL_WSL_PATH/AtomicParsleyExtracted"
fi

sudo chmod +x $YTDL_WSL_PATH/*.exe