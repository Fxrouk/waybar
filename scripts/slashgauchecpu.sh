#!/bin/bash

# Nombre de coeurs
CPU_CORES=12

# Fonction pour récupérer l'utilisation CPU moyenne
get_cpu_usage() {
    # Lecture initiale
    CPU1=($(grep '^cpu[0-9]' /proc/stat | awk '{idle=$5; total=$2+$3+$4+$5+$6+$7+$8; print idle, total}'))
    sleep 0.5
    # Lecture après 0.5s
    CPU2=($(grep '^cpu[0-9]' /proc/stat | awk '{idle=$5; total=$2+$3+$4+$5+$6+$7+$8; print idle, total}'))

    sum=0
    for ((i=0; i<CPU_CORES; i++)); do
        idx=$((i*2))
        idle1=${CPU1[$idx]}
        total1=${CPU1[$idx+1]}
        idle2=${CPU2[$idx]}
        total2=${CPU2[$idx+1]}

        idle_diff=$((idle2 - idle1))
        total_diff=$((total2 - total1))
        usage=$(( (100*(total_diff - idle_diff)) / total_diff ))
        sum=$((sum + usage))
    done

    # Moyenne sur tous les coeurs
    echo $((sum / CPU_CORES))
}

USAGE=$(get_cpu_usage)

# Icône séparateur gauche
ICON=""

# Classes Waybar selon l'utilisation CPU
if [[ "$USAGE" -gt 65 ]]; then
    CLASS="cpu-blink"
elif [[ "$USAGE" -gt 50 ]]; then
    CLASS="cpu-warning"
else
    CLASS=""
fi

# Construction JSON pour Waybar
if [[ -n "$CLASS" ]]; then
    echo "{\"text\":\"$ICON\", \"class\":\"$CLASS\"}"
else
    echo "{\"text\":\"$ICON\"}"
fi
