#!/usr/bin/env bash

# Check if wf-recorder is running
if pgrep -x "wf-recorder" > /dev/null; then
    echo "true"
else
    echo "false"
fi
