#!/bin/bash
if pgrep -x "hyprsunset" > /dev/null; then
    echo "true"
else
    echo "false"
fi
