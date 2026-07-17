#!/usr/bin/env bash
set -u

SOUND="/usr/share/sounds/freedesktop/stereo/complete.oga"

for _ in {1..3}; do
    if command -v paplay >/dev/null 2>&1 && [[ -f "$SOUND" ]]; then
        paplay "$SOUND"
    else
        printf '\a'
    fi
    sleep 0.35
done
