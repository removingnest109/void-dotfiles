#!/bin/sh
# Launch (or relaunch) polybar for bspwm.

# Terminate any running instances cleanly.
pkill -x polybar
# Wait until they're actually gone so the systray slot is free.
while pgrep -x polybar >/dev/null; do sleep 0.2; done

polybar main 2>&1 | tee -a /tmp/polybar-main.log &
