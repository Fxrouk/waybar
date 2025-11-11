#!/bin/bash

MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | sed 's/%//g' | head -n 1)
ACTIVE_SINK=$(pactl get-default-sink)

# Même logique que ton script volume pour la classe blink
if [[ "$MUTE" == "no" && "$ACTIVE_SINK" != *"Headphones"* && "$ACTIVE_SINK" != *"bluez"* && "$ACTIVE_SINK" != *"a2dp"* && "$VOL" -gt 0 ]]; then
    echo '{"text":"","class":"volume-blink"}'
else
    echo '{"text":""}'
fi

