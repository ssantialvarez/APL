#!/bin/bash
DEBUG=false
REPO="/home/sirius/Documents/virtualizacion/APL"
CONFIG="./bash/ejercicio4/patrones.conf"
LOG="./bash/ejercicio4/logs.log"
BRANCH="ejercicio4"   # o master, según tu repo

cd "$REPO" || exit 1

# Guardamos el hash inicial de la rama principal
last_hash=$(git rev-parse "$BRANCH")

while true; do
    git fetch origin "$BRANCH" >/dev/null 2>&1
    new_hash=$(git rev-parse "origin/$BRANCH")
    $DEBUG && echo "LAST_HASH: $last_hash"
    $DEBUG && echo "NEW HASH: $new_hash"
    if [ "$new_hash" != "$last_hash" ]; then
        echo "[$(date '+%F %T')] Detectados cambios en $BRANCH" >> "$LOG"

        # Archivos modificados entre commits
        changed_files=$(git diff --name-only "$last_hash" "$new_hash")
        $DEBUG && echo "CHANGED FILES: $changed_files"
        for file in $changed_files; do
            [ -f "$file" ] || continue
            while read pattern; do
                [ -z "$pattern" ] && continue
                if [[ "$pattern" == regex:* ]]; then
                    regex="${pattern#regex:}"
                    if grep -Eq "$regex" "$file"; then
                        echo "[$(date '+%F %T')] ALERTA: patrón '$regex' en $file" >> "$LOG"
                    fi
                else
                    if grep -q "$pattern" "$file"; then
                        echo "[$(date '+%F %T')] ALERTA: patrón '$pattern' en $file" >> "$LOG"
                    fi
                fi
            done < "$CONFIG"
        done

        # Actualizar el último hash
        last_hash="$new_hash"
    fi

    sleep 10
done
