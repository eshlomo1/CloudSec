#!/bin/bash

# 1. The Obfuscated Data (The Stager)
# This represents the encoded ASCII frames or the logic to fetch them.
# For this demo, we'll keep the logic readable but the "payload" can be hidden.
DATA_URL="https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh"
AUDIO_URL="http://www.leeholmes.com/projects/ps_html5/background.mp3"

# 2. The Audio Hook (Background Process)
# We use afplay (Apple File Play), which is native to macOS.
# We background it (&) so the visuals can run simultaneously.
play_audio() {
    local tmp_audio="/tmp/bg.mp3"
    curl -sL "$AUDIO_URL" -o "$tmp_audio"
    afplay "$tmp_audio" &
    AUDIO_PID=$!
}

# 3. Environment Preparation (The "Hacker's Wit" layer)
# On macOS, we check if we are in a proper terminal.
prepare_terminal() {
    clear
    # Set terminal colors (White background, Black text)
    printf '\e]11;#FFFFFF\a'
    printf '\e]10;#000000\a'
    # Hide the cursor
    tput civis
}

# 4. Cleanup Function
cleanup() {
    # Restore terminal and kill background audio
    tput cnorm
    printf '\e]11;#000000\a' # Reset background to black
    printf '\e]10;#FFFFFF\a' # Reset text to white
    kill $AUDIO_PID 2>/dev/null
    rm /tmp/bg.mp3 2>/dev/null
    clear
    echo "Happy Scripting from the Mac Terminal..."
    exit
}

# 5. The Execution
trap cleanup SIGINT SIGTERM

play_audio
prepare_terminal

# Execute the ASCII visuals by piping directly into bash (The Cradle)
curl -sL "$DATA_URL" | bash

cleanup
