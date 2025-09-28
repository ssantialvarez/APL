#!/bin/bash

#### FUNCIONES
function help() {
    cat << EOF
Usage: $0 [-r|--repo REPO] [-c|--configuracion CONFIG] [-l|--log LOG] [-k|--kill KILL]

Options:
  -r, --repo REPO            Ruta del repositorio Git a monitorear.
  -c, --configuracion CONFIG   Ruta del archivo de configuración que contiene la lista de patrones a buscar.
  -l, --log LOG              Ruta del archivo de logs que contiene la lista de eventos identificados.
  -k, --kill KILL            Flag para detener el demonio. Solo se usa junto con -r / -repo y debe validar que exista un demonio en ejecución.

  -h, --help                 Muestra este mensaje de ayuda
EOF
    exit 0
}

function procesamiento_parametros() {
    #### PROCESAMIENTO DE PARAMETROS
    options=$(getopt -o r:c:l:kh --l repo:,configuracion:,kill:,log,help -- "$@" 2> /dev/null)
    if [ "$?" != "0" ]
    then
        echo "$0: no se ingresó la ruta del repositorio o se ingresaron parametros incorrectos." >&2
        exit 1
    fi

    eval set -- "$options"

    while true
    do
        case "$1" in 
            -r | --repo)
                REPO="$2"
                shift 2

                ;;
            -c | --configuracion)
                CONFIG="$2"
                shift 2

                ;;
            -k | --kill)
                KILL=true
                shift 
                
                ;;
            -l | --log)
                LOG="$2"
                shift 2
                
                ;;
            -h | --help)
                help
                exit 0
                ;;
            --) # case "--":
                shift
                break
                ;;
            *) # default: 
                echo "$0: opcion no reconocida: $1" >&2
                
                exit 1
                ;;
        esac
    done

    if [ -z "$REPO" ]; 
    then
        echo "$0: no se ingresó la ruta del repositorio Git." >&2
        exit 1
    fi
    if [[ "$KILL" = false ]]; 
    then
        if [ -z "$CONFIG" ];
        then
            echo "$0: no se especificó archivo de configuración." >&2
            exit 1
        fi
        if [ -z "$LOG" ];
        then
            echo "$0: no se especificó archivo de log." >&2
            exit 1
        fi
    fi
}

function procesamiento_archivos(){
    #### PROCESAMIENTO DE REPOSITORIO
    #### VERIFICA QUE EL REPOSITORIO TENGA .git
    if [[ "$REPO" == .* ]]; then
        REPO="$me_DIR/$REPO"
    fi
    find "$REPO" -name ".git"
    FLAG=$(echo "$?")
    if [ $FLAG -eq 1 ]; then
        echo "$0: El directorio '$REPO' no tiene un repositorio git válido."
        exit 1
    fi

    #### SE GENERA HASH CON EL REPOSITORIO
    REPO_HASH=$(echo "$REPO" | sha1sum | cut -d' ' -f1)
    PIDFILE="/tmp/audit_${REPO_HASH}.pid"
    #### SE OBTIENE PID (SI ES QUE HAY)
    PID=$(cat "$PIDFILE" 2>/dev/null;)

    #### PROCESAMIENTO DE ARCHIVO .log
    if [[ "$LOG" == .* ]]; then
        LOG="$me_DIR/$LOG"
    fi

    if ! find "$LOG" >/dev/null 2>&1; then
        touch $LOG
    fi

    #### PROCESAMIENTO DE ARCHIVO .conf
    if [[ "$CONFIG" == .* ]]; then
        CONFIG="$me_DIR/$CONFIG"
    fi

    mapfile -t REGEX < <(cat $CONFIG)

    if [ ${#REGEX[@]} -eq 0 ]
    then
        echo "ARCHIVO CONFIG VACIO" 
        exit 1
    fi
}

function verifica_paquete(){
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
}

function scan_file() {
    local file="$1"
    [ -f "$file" ] || return
    while read pattern; do
        [ -z "$pattern" ] && continue
        if [[ "$pattern" == regex:* ]]; then
            regex="${pattern#regex:}"
            if grep -Eq "$regex" "$file"; then
                echo "[$(date '+%F %T')] ALERTA: patrón '$regex' en $file"
            fi
        else
            if grep -q "$pattern" "$file"; then
                echo "[$(date '+%F %T')] ALERTA: patrón '$pattern' en $file"
            fi
        fi
    done < "$CONFIG"
}

trap process_USR1 SIGTERM
function process_USR1() {
    kill 0
    exit 0
}

#### VARIABLES
me_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
me_FILE=$(basename $0)
declare -a REGEX
REGEX=()
REPO=""
CONFIG=""
KILL=false
LOG=""
tty=""

cd /

#### CHILD HERE --------------------------------------------------------------------->
if [ "$1" = "child" ] ; then   # 2. Proceso hijo, tiene que volver a hacer fork.
    shift; tty="$1"; shift
    umask 0
    $me_DIR/$me_FILE XXrefork_daemonXX "$tty" "$@" </dev/null >/dev/null 2>/dev/null &
    exit 0
fi

##### ENTRY POINT HERE -------------------------------------------------------------->
if [ "$1" != "XXrefork_daemonXX" ] ; then # 1. Proceso padre.
    procesamiento_parametros "$@"

    procesamiento_archivos

    if [[ "$KILL" == true ]]
    then
        if kill -0 "$PID" 2>/dev/null;
        then
            kill $PID
            echo "$0: El daemon de $REPO se detuvo correctamente."
        else
            echo "$0: El repositorio no tiene un daemon activo asociado."
        fi
        rm $PIDFILE 2>/dev/null;
        exit 1
    fi
    if kill -0 "$PID" 2>/dev/null;
    then
        echo "$0: El repositorio ya tiene un daemon activo asociado."
        exit 1
    fi
    
    tty=$(tty)
    setsid $me_DIR/$me_FILE child "$tty" "$REPO" "$CONFIG" "$LOG" "$REPO_HASH" "$PIDFILE" &
    exit 0
fi

##### RUNS AFTER CHILD FORKS 
                               # 3. Proceso del nieto/demonio.

shift; tty="$1"; shift
exec >"$3"
exec 0</dev/null
REPO="$1"
CONFIG="$2"
LOG="$3"
REPO_HASH="$4"
PIDFILE="$5"

echo $$ > $PIDFILE

verifica_paquete
#### LOOP PRINCIPAL
inotifywait -m -r -e close_write,create,delete "$REPO" | while read dir event file; do
    full_path="$dir$file"
    scan_file "$full_path"
done &

wait
