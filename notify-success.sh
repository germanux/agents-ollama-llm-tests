#!/usr/bin/env bash
set -u

sound="/usr/share/sounds/freedesktop/stereo/complete.oga"

for _ in {1..5}; do
    if command -v paplay >/dev/null 2>&1 && [[ -f "$sound" ]]; then
        paplay "$sound"
    else
        printf '\a'
    fi
    sleep 0.35
done
