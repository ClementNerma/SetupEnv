#
# This file contains the default configuration used by all other ZSH files
# Its content can be overriden by the `local/config.zsh` file
#

# Is this my main computer?
# Set to '1' if it is
export ADF_CONF_MAIN_PERSONAL_COMPUTER=0

# Path to the restoration script
export ADF_CONF_RESTORATION_SCRIPT="/usr/local/bin/zerrestore"

# Disable automatic switching to directory if current path is home at startup
export ADF_CONF_DISABLE_DIR_HOME_SWITCHING=0

# Should the project directories be put in WSL's filesystem?
# Set to '1' if yes
export ADF_CONF_PROJECT_DIRS_IN_WSL_FS=0

# Youtube-DL commands history with temporary directory
export ADF_CONF_YTDL_HISTORY_FILE="$ADF_THISCOMP_DIR/youtube-dl.history"

# Minimum parallel downloads that have to occur in parallel to enable the temporary path feature
export ADF_CONF_YTDL_TEMP_DL_DIR_THRESOLD=0

# Temporary path (must be on a VERY FAST storage) where Youtube-DL downloaded files are put
# They are moved after the download has been finished, to avoid problems with parallel downloads
export ADF_CONF_YTDL_TEMP_DL_DIR_PATH="/tmp/ytdl-videos"

# Backup path for sessions (WSL-only)
export ADF_CONF_WSL_BACKUP_SESSION_DIR="/mnt/c/Temp/SessionBackup"

# Backup path for sessions' compilation (WSL-only) - must end with `.7z` extension
export ADF_CONF_WSL_BACKUP_SESSION_COMPILATION="$ADF_CONF_WSL_BACKUP_SESSION_DIR/session-backups.7z"

# CRON tasks' logs directory
export ADF_CONF_CRON_LOGS_DIR="$ADF_THISCOMP_DIR/cron-logs"

# Default bandwidth limit for the 'ytdl' functino
# Can be overriden with the YTDL_LIMIT_BANDWIDTH variable
export ADF_YTDL_DEFAUT_LIMIT_BANDWIDTH="5M"

# Bandwidth limit to use when synchronizing a Youtube-DL playlist with the "ytsync" or "ytrepairres" commands
# This is required in order to avoid temporary IP bans on most websites
export ADF_YTDL_SYNC_LIMIT_BANDWIDTH="5M"
