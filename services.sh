#!/usr/bin/env bash

set -euo pipefail

services=(
    NetworkManager.service
    sddm.service
    earlyoom.service
)

if ! command -v systemctl >/dev/null 2>&1; then
    echo "Error: systemctl is required to manage services." >&2
    exit 1
fi

if [[ "$(ps -p 1 -o comm=)" != "systemd" ]]; then
    echo "Error: systemd is not running as PID 1." >&2
    exit 1
fi

if (( EUID == 0 )); then
    systemctl_cmd=(systemctl)
elif command -v sudo >/dev/null 2>&1; then
    systemctl_cmd=(sudo systemctl)
else
    echo "Error: sudo is required when this script is not run as root." >&2
    exit 1
fi

for service in "${services[@]}"; do
    if ! "${systemctl_cmd[@]}" cat "$service" >/dev/null 2>&1; then
        echo "Error: service unit '$service' was not found." >&2
        exit 1
    fi

    if ! "${systemctl_cmd[@]}" is-enabled --quiet "$service"; then
        echo ":: Enabling $service"
        "${systemctl_cmd[@]}" enable "$service"
    fi

    if "${systemctl_cmd[@]}" is-active --quiet "$service"; then
        echo ":: $service is already active"
    else
        echo ":: Starting $service"
        "${systemctl_cmd[@]}" start "$service"
    fi
done

echo ":: Services are configured and active."