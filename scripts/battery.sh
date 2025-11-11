#!/bin/bash

# Détection automatique du dossier de la batterie
BAT_PATH="/sys/class/power_supply/BAT0"
if [[ ! -d "$BAT_PATH" ]]; then
    BAT_PATH="/sys/class/power_supply/BAT1"
fi

# Si aucune batterie détectée
if [[ ! -d "$BAT_PATH" ]]; then
    echo '{"text":"󰁹 N/A"}'
    exit 0
fi

# Fichiers pour tracker si on a déjà relancé waybar
BATTERY_BLINK_RELOAD_FILE="/tmp/waybar-battery-blink-reloaded"
BATTERY_WARNING_RELOAD_FILE="/tmp/waybar-battery-warning-reloaded"

# Lecture des infos
CAPACITY=$(cat "$BAT_PATH/capacity")
STATUS=$(cat "$BAT_PATH/status")  # Charging, Discharging, Full, etc.

# Icônes de batterie selon le niveau
ICONS=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")

# Choix de l'icône
if [[ "$STATUS" == "Charging" ]]; then
    ICON="󱘖"  # Icône fixe en charge
else
    ICON_INDEX=$((CAPACITY / 10))
    if [[ $ICON_INDEX -gt 10 ]]; then ICON_INDEX=10; fi
    ICON=${ICONS[$ICON_INDEX]}
fi

# Récupération du temps restant via upower
UP_PATH=$(upower -e | grep BAT)
TIME_LINE=$(upower -i $UP_PATH | grep "time to")
TIME_VALUE=$(echo $TIME_LINE | awk '{print $4}')
TIME_UNIT=$(echo $TIME_LINE | awk '{print $5}')

# Remplacer la virgule par un point si besoin
TIME_VALUE=${TIME_VALUE/,/.}

# Convertir en minutes si nécessaire
if [[ "$TIME_UNIT" == "hours" ]]; then
    TIME_VALUE=$(echo "$TIME_VALUE * 60" | bc)
fi

# Arrondir à l'entier le plus proche
TIME_REMAINING=$(printf "%.0f" $TIME_VALUE)
# Ajouter "min"
TIME_REMAINING="${TIME_REMAINING}min"

# Gestion des classes Waybar
if [[ "$CAPACITY" -le 15 && "$STATUS" != "Charging" ]]; then
    CLASS="battery-blink"
elif [[ "$CAPACITY" -le 20 && "$CAPACITY" -gt 15 && "$STATUS" != "Charging" ]]; then
    CLASS="battery-warning"
elif [[ "$STATUS" == "Charging" && "$CAPACITY" -ge 80 && "$CAPACITY" -le 85 ]]; then
    CLASS="battery-warning"
elif [[ "$STATUS" == "Charging" && "$CAPACITY" -gt 85 ]]; then
    CLASS="battery-blink"
elif [[ "$STATUS" == "Charging" ]]; then
    CLASS="battery-charging"
else
    CLASS=""
fi

# Construction du JSON Waybar avec séparateur 
DISPLAY_TEXT="${ICON} ${CAPACITY}%"
if [[ -n "$TIME_REMAINING" ]]; then
    DISPLAY_TEXT="${DISPLAY_TEXT}  ${TIME_REMAINING}"
fi

# Relancer waybar seulement si battery-blink ET pas déjà fait
if [[ "$CLASS" == "battery-blink" && ! -f "$BATTERY_BLINK_RELOAD_FILE" ]]; then
    touch "$BATTERY_BLINK_RELOAD_FILE"
    # Relancer waybar de manière asynchrone
    nohup bash -c "killall waybar; sleep 0.2; waybar" > /dev/null 2>&1 &
fi

# Relancer waybar seulement si battery-warning ET pas déjà fait
if [[ "$CLASS" == "battery-warning" && ! -f "$BATTERY_WARNING_RELOAD_FILE" ]]; then
    touch "$BATTERY_WARNING_RELOAD_FILE"
    # Relancer waybar de manière asynchrone
    nohup bash -c "killall waybar; sleep 0.2; waybar" > /dev/null 2>&1 &
fi

# Supprimer les fichiers si on n'est plus dans les états correspondants
if [[ "$CLASS" != "battery-blink" && -f "$BATTERY_BLINK_RELOAD_FILE" ]]; then
    rm -f "$BATTERY_BLINK_RELOAD_FILE"
fi

if [[ "$CLASS" != "battery-warning" && -f "$BATTERY_WARNING_RELOAD_FILE" ]]; then
    rm -f "$BATTERY_WARNING_RELOAD_FILE"
fi

# Output pour Waybar
if [[ -n "$CLASS" ]]; then
    echo "{\"text\":\"${DISPLAY_TEXT}\", \"class\":\"${CLASS}\"}"
else
    echo "{\"text\":\"${DISPLAY_TEXT}\"}"
fi
