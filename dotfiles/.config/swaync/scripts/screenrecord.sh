#!/usr/bin/env bash

# ==============================================================================
# SCREEN RECORDING SETTINGS
# Edit the values below to customize your recording experience.
# ==============================================================================

# -------------------------
# GENERAL SETTINGS
# -------------------------

# Where should the videos be saved? 
SAVE_DIR="$HOME/Videos/Recordings"

# What file format do you want? (Options: mkv, mp4, webm)
# Recommendation: 'mkv' is safer! If your PC crashes, an mkv file is still 
# playable, whereas an mp4 file will be completely corrupted.
FORMAT="mp4"

# -------------------------
# VIDEO SETTINGS
# -------------------------

# Frames per second. 
# Options: 30 (smaller files, lower CPU) or 60 (smoother motion).
FRAMERATE="60"

# The video encoder to use.
# 'libx264'    = CPU encoding. Uses more CPU but is highly stable.
# 'h264_vaapi' = GPU encoding for Intel/AMD. Low CPU usage, requires driver support.
# CODEC="libx264"
CODEC="libx264"

# Quality and speed tuning (Specific to libx264).
# 'crf=28' = Quality level. Lower number (e.g., 18) = better quality but huge files.
# 'preset=ultrafast' + 'tune=zerolatency' = Ensures CPU doesn't choke on frames.
CODEC_PARAMS="-p preset=ultrafast -p tune=zerolatency -p crf=28"

# AUDIO SETTINGS

# Do you want to record audio? (true / false)
RECORD_AUDIO=true

# HOW TO FIND YOUR AUDIO SOURCES
# Run these commands in your terminal to get the exact names:
# ==========================================================

# 1. To find your default MICROPHONE:
#    pactl get-default-source

# 2. To find your default Desktop Audio source:
#    echo "$(pactl get-default-sink).monitor"

# (Optional) To see a list of ALL available audio devices:
#    pactl list short sources
# To record a microphone, type its exact name here (find it using the 'pactl list sources' command).
AUDIO_SOURCE="$(pactl get-default-sink).monitor"


# SCRIPT LOGIC BELOW (Only edit if you know what you are doing)

# Handle the user-friendly Audio switch
if [ "$RECORD_AUDIO" = true ]; then
    if [ -z "$AUDIO_SOURCE" ]; then
        AUDIO_CMD="--audio" # Captures default system audio
    else
        AUDIO_CMD="--audio=$AUDIO_SOURCE" # Captures specific device
    fi
else
    AUDIO_CMD=""
fi

LOCKFILE="/tmp/screenrecord.lock"
FILENAME="$SAVE_DIR/recording_$(date +'%Y-%m-%d_%H-%M-%S').$FORMAT"

# Try to acquire an exclusive lock on file descriptor 9
exec 9>"$LOCKFILE"

if ! flock -n 9; then
    # If the script is run while already recording, it acts as a toggle to stop it.
    if pgrep -x "wf-recorder" > /dev/null; then
        killall -INT wf-recorder
        notify-send "Screen Recording" "Recording stopped and saved successfully." -h "boolean:transient:true"
    fi
    exit 0
fi

# If we get here, we have the lock and no recording is running.
mkdir -p "$SAVE_DIR"

notify-send "Screen Recording" "Recording started..." -h "boolean:transient:true"

# Run wf-recorder with the configured settings
# The lock is automatically released when the script exits.
wf-recorder $AUDIO_CMD -r "$FRAMERATE" -c "$CODEC" $CODEC_PARAMS -f "$FILENAME" || {
    notify-send -u critical "Screen Recording Failed" "wf-recorder crashed or could not start."
    [ -f "$FILENAME" ] && rm -f "$FILENAME"
}
