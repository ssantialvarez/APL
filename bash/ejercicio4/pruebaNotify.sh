#!/bin/bash 
cd / 
REPO="/home/sirius/Documents/virtualizacion/APL" 
LOG="/home/sirius/Documents/virtualizacion/logs.log" 
CONFIG="/home/sirius/Documents/virtualizacion/APL/bash/ejercicio4/patrones.conf"

scan_file() {
    local file="$1"
    [ -f "$file" ] || return
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
}

if ! command -v inotifywait >/dev/null 2>&1; then
    echo "$0: El comando 'inotifywait' no está disponible."
    echo "$0: Se necesita el paquete 'inotify-tools' para monitorear cambios en el directorio."
    flag=1
    while [ $flag -eq 1 ]
    do
        echo -n "$0: ¿Desea instalarlo ahora? [Y/n]: "
        read -r respuesta

        case "$respuesta" in
            [Yy]* | "" )
                echo "$0: Instalando inotify-tools..."
                sudo apt update && sudo apt install inotify-tools -y
                flag=$(echo $?)
                ;;
            [Nn]* )
                echo "$0: No se instalará 'inotify-tools'."
                echo "$0: El script no podrá usar monitoreo en tiempo real."
                echo "$0: Saliendo..."
                exit 1
                ;;
            * )
                echo "$0: Respuesta no válida. Use Y o n."
                
                ;;
        esac
    done
fi

if ! find "$LOG" >/dev/null 2>&1; then
    touch $LOG || exit 1
fi


inotifywait -m -r -e modify,create,delete "$REPO" | while read dir event file; do
    full_path="$dir$file"
    # echo "[$(date '+%F %T')] Detectado cambio en $full_path ($event)" >> "$LOG"
    scan_file "$full_path"
done