#
# This file contains the default configuration used by all other ZSH files
# Its content can be overriden by the `local/config.zsh` file
#

# Is this my main computer?
# Set to '1' if it is
export ZSH_MAIN_PERSONAL_COMPUTER=0

# Disable automatic switching to directory if current path is home at startup
export DISABLE_DIR_HOME_SWITCHING=0

# Should the project directories be put in WSL's filesystem?
# Set to '1' if yes
export PROJECT_DIRS_IN_WSL_FS=0

# Path to the YoutubeDL binaries, for WSL
export YTDL_WSL_PATH="/mnt/c/Users/Public/Documents/SetupEnvData/YoutubeDL"
export YOUTUBEDL_BIN_PATH="$YTDL_WSL_PATH/youtube-dl.exe"
export FFMPEG_BIN_PATH="$YTDL_WSL_PATH/ffmpeg.exe"
export FFPLAY_BIN_PATH="$YTDL_WSL_PATH/ffplay.exe"
export FFPROBE_BIN_PATH="$YTDL_WSL_PATH/ffprobe.exe"
export ATOMICPARSLEY_BIN_PATH="$YTDL_WSL_PATH/AtomicParsley.exe"
