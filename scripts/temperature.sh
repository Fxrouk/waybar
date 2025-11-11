#!/bin/bash

# Liste des chemins possibles pour la température
PATHS=(
    "/sys/class/hwmon/hwmon1/temp1_input"
    "/sys/class/thermal/thermal_zone0/temp"
)

# Fichiers pour tracker si on a déjà relancé waybar
TEMP_BLINK_RELOAD_FILE="/tmp/waybar-temperature-blink-reloaded"
TEMP_WARNING_RELOAD_FILE="/tmp/waybar-temperature-warning-reloaded"

TEMP_RAW=""
for path in "${PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        TEMP_RAW=$(cat "$path")
        break
    fi
done

# Si aucun chemin valide trouvé
if [[ -z "$TEMP_RAW" ]]; then
    echo '{"text":"N/A"}'
    exit 0
fi

# Conversion (souvent en millidegrés)
if [[ "$TEMP_RAW" -gt 1000 ]]; then
    TEMP_C=$((TEMP_RAW / 1000))
else
    TEMP_C=$TEMP_RAW
fi

# Détermination de la classe selon la température
if [[ "$TEMP_C" -ge 82 ]]; then
    CLASS="temperature-blink"
elif [[ "$TEMP_C" -ge 65 && "$TEMP_C" -lt 82 ]]; then
    CLASS="temperature-warning"
elif [[ "$TEMP_C" -lt 40 ]]; then
    CLASS="temperature-cold"
else
    CLASS=""
fi

# Sélection de l'icône selon la classe
case "$CLASS" in
    "temperature-blink")
        ICON="󰈸"
        ;;
    "temperature-warning")
        ICON="󱗗"
        ;;
    "temperature-cold")
        ICON=""
        ;;
    *)
        ICON=""
        ;;
esac

# Relancer waybar seulement si temperature-blink ET pas déjà fait
if [[ "$CLASS" == "temperature-blink" && ! -f "$TEMP_BLINK_RELOAD_FILE" ]]; then
    touch "$TEMP_BLINK_RELOAD_FILE"
    # Relancer waybar de manière asynchrone
    nohup bash -c "killall waybar; sleep 0.2; waybar" > /dev/null 2>&1 &
fi

# Relancer waybar seulement si temperature-warning ET pas déjà fait
if [[ "$CLASS" == "temperature-warning" && ! -f "$TEMP_WARNING_RELOAD_FILE" ]]; then
    touch "$TEMP_WARNING_RELOAD_FILE"
    # Relancer waybar de manière asynchrone
    nohup bash -c "killall waybar; sleep 0.2; waybar" > /dev/null 2>&1 &
fi

# Supprimer les fichiers si on n'est plus dans les états correspondants
if [[ "$CLASS" != "temperature-blink" && -f "$TEMP_BLINK_RELOAD_FILE" ]]; then
    rm -f "$TEMP_BLINK_RELOAD_FILE"
fi

if [[ "$CLASS" != "temperature-warning" && -f "$TEMP_WARNING_RELOAD_FILE" ]]; then
    rm -f "$TEMP_WARNING_RELOAD_FILE"
fi

# Construction du JSON pour Waybar
if [[ -n "$CLASS" ]]; then
    echo "{\"text\":\"${ICON} ${TEMP_C}°C\", \"class\":\"${CLASS}\"}"
else
    echo "{\"text\":\"${ICON} ${TEMP_C}°C\"}"
fi
