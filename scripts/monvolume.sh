#!/bin/bash

MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | sed 's/%//g' | head -n 1)
ACTIVE_SINK=$(pactl get-default-sink)

# Fichier pour tracker si on a déjà relancé waybar
BLINK_RELOAD_FILE="/tmp/waybar-blink-reloaded"

# Choix de l'icône selon le volume et le périphérique
if [[ "$MUTE" == "yes" ]]; then
    ICON=" "
elif [[ "$ACTIVE_SINK" == *"Headphones"* ]]; then
    ICON=" "  # Icône casque/écouteurs
elif [[ "$ACTIVE_SINK" == *"bluez"* ]] || [[ "$ACTIVE_SINK" == *"a2dp"* ]]; then
    ICON=" 󰂯"  # Icône casque/écouteurs
elif [[ "$VOL" -eq 0 ]]; then
    ICON="  "
elif [[ "$VOL" -lt 50 ]]; then
    ICON="  "
else
    ICON="  "
fi

# Clignotement seulement si pas mute, haut-parleurs internes ET volume > 0%
if [[ "$MUTE" == "no" && "$ACTIVE_SINK" != *"Headphones"* && "$ACTIVE_SINK" != *"bluez"* && "$ACTIVE_SINK" != *"a2dp"* && "$VOL" -gt 0 ]]; then
    echo "{\"text\":\"$ICON $VOL%\",\"class\":\"volume-blink\"}"
    
    # Relancer waybar seulement si pas déjà fait
    if [[ ! -f "$BLINK_RELOAD_FILE" ]]; then
        touch "$BLINK_RELOAD_FILE"
        # Relancer waybar en arrière-plan avec un délai
        (
            sleep 0.5
            killall waybar
            sleep 0.1
            waybar &
            disown
        ) &
    fi
else
    echo "{\"text\":\"$ICON $VOL%\"}"
    # Quand on n'est plus en condition de blink, supprimer le fichier
    rm -f "$BLINK_RELOAD_FILE"
fi
