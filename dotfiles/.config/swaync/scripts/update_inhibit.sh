#!/bin/bash

INHIBIT_CMD="systemd-inhibit --what=idle sleep infinity"

if pgrep -f "$INHIBIT_CMD" > /dev/null; then
    echo "true"
else
    echo "false"
fi
