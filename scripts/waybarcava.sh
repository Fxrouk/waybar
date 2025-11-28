#!/bin/bash

bar="▁▂▃▄▅▆▇█"
dict="s/;//g"

# Créer le dictionnaire de substitution
for ((i = 0; i < ${#bar}; i++)); do
    dict+=";s/$i/${bar:$i:1}/g"
done

# Fichier config unique pour cette instance
config_file="/tmp/waybar_cava_config_$$"
cat >"$config_file" <<'EOF'
[general]
framerate = 21
bars = 74
sensibility = 30
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Nettoyage à la sortie
cleanup() {
    [[ -f "$config_file" ]] && rm -f "$config_file"
    # Ne tuer que les processus Cava de CETTE instance
    pkill -f "cava -p $config_file" 2>/dev/null
}
trap cleanup EXIT

# Lancer Cava et traiter la sortie
cava -p "$config_file" | while IFS= read -r line; do
    # Nettoyer la ligne
    line_clean="${line//;/}"
    
    # Vérifier si c'est une ligne vide ou que des zéros
    if [[ -z "$line_clean" || "$line_clean" =~ ^0+$ ]]; then
        echo "  ㅤBA10  "
    else
        # Appliquer les substitutions avec sed
        bars_line=$(echo "$line_clean" | sed "$dict")
        
        # Inverser les deux moitiés
        len=${#bars_line}
        mid=$((len / 2))
        
        left="${bars_line:0:$mid}"
        right="${bars_line:$mid}"
        
        left_rev=$(echo "$left" | rev)
        right_rev=$(echo "$right" | rev)
        
        echo "$left_rev$right_rev"
    fi
done

