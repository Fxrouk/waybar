#!/bin/bash

# Liste des chemins possibles pour la température
PATHS=(
    "/sys/class/hwmon/hwmon1/temp1_input"
    "/sys/class/thermal/thermal_zone0/temp"
)

TEMP_RAW=""
for path in "${PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        TEMP_RAW=$(cat "$path")
        break
    fi
done

# Si aucun chemin valide trouvé
if [[ -z "$TEMP_RAW" ]]; then
    echo '{"text":""}'
    exit 0
fi

# Conversion (souvent en millidegrés)
if [[ "$TEMP_RAW" -gt 1000 ]]; then
    TEMP_C=$((TEMP_RAW / 1000))
else
    TEMP_C=$TEMP_RAW
fi

# Icône du séparateur
ICON=""

# Gestion des classes selon la température
if [[ "$TEMP_C" -ge 82 ]]; then
    CLASS="temperature-blink"

elif [[ "$TEMP_C" -ge 65 && "$TEMP_C" -lt 82 ]]; then
    CLASS="temperature-warning"

elif [[ "$TEMP_C" -lt 40 ]]; then
    CLASS="temperature-cold"

else
    CLASS=""
fi

# Construction du JSON pour Waybar
if [[ -n "$CLASS" ]]; then
    echo "{\"text\":\"$ICON\", \"class\":\"$CLASS\"}"
else
    echo "{\"text\":\"$ICON\"}"
fi
