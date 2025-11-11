#!/bin/bash

# Détection automatique du dossier de la batterie
BAT_PATH="/sys/class/power_supply/BAT0"
if [[ ! -d "$BAT_PATH" ]]; then
    BAT_PATH="/sys/class/power_supply/BAT1"
fi

# Si aucune batterie détectée
if [[ ! -d "$BAT_PATH" ]]; then
    echo '{"text":""}'
    exit 0
fi

# Lecture des infos
CAPACITY=$(cat "$BAT_PATH/capacity")
STATUS=$(cat "$BAT_PATH/status")  # Charging, Discharging, Full, etc.

# Icône du séparateur gauche
ICON=""

# Gestion des classes Waybar
if [[ "$CAPACITY" -le 15 && "$STATUS" != "Charging" ]]; then
    # Batterie critique
    CLASS="battery-blink"

elif [[ "$CAPACITY" -le 20 && "$CAPACITY" -gt 15 && "$STATUS" != "Charging" ]]; then
    # Batterie faible
    CLASS="battery-warning"

elif [[ "$STATUS" == "Charging" && "$CAPACITY" -ge 80 && "$CAPACITY" -le 85 ]]; then
    # Batterie en charge mais proche de la limite "warning"
    CLASS="battery-warning"

elif [[ "$STATUS" == "Charging" && "$CAPACITY" -gt 85 ]]; then
    # Batterie presque pleine en charge
    CLASS="battery-blink"

elif [[ "$STATUS" == "Charging" ]]; then
    # En charge normale
    CLASS="battery-charging"

else
    CLASS=""
fi

# Construction du JSON pour Waybar
if [[ -n "$CLASS" ]]; then
    echo "{\"text\":\"$ICON\", \"class\":\"$CLASS\"}"
else
    echo "{\"text\":\"$ICON\"}"
fi
