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



function process_USR1() {
    echo "$0: El daemon se detuvo correctamente." >$tty
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
trap 'process_USR1 "$tty"' SIGTERM

cd /


#### CHILD HERE --------------------------------------------------------------------->
if [ "$1" = "child" ] ; then   # 2. We are the child. We need to fork again.
    shift; tty="$1"; shift
    umask 0
    $me_DIR/$me_FILE XXrefork_daemonXX "$tty" "$@" </dev/null >/dev/null 2>/dev/null &
    exit 0
fi

##### ENTRY POINT HERE -------------------------------------------------------------->
if [ "$1" != "XXrefork_daemonXX" ] ; then # 1. This is where the original call starts.
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

    #### PROCESAMIENTO DE REPOSITORIO
    #### SE GENERA HASH CON EL REPOSITORIO
    REPO_HASH=$(echo "$REPO" | sha1sum | cut -d' ' -f1)
    PIDFILE="/tmp/audit_${REPO_HASH}.pid"
    #### SE OBTIENE PID (SI ES QUE HAY)
    PID=$(cat "$PIDFILE" 2>/dev/null;)
    #### VERIFICAR QUE HAYA UN ARCHIVO .pid CON EL REPO
    FLAG=$( [ -f "$PIDFILE" ] && echo "true" || echo "false" )

    if [[ "$KILL" == true ]]
    then
        rm $PIDFILE 2>/dev/null;
        if kill -0 "$PID" 2>/dev/null;
        then
            kill $PID
            echo "$0: El daemon $PID se detuvo."
        else
            echo "$0: El repositorio no tiene un daemon activo asociado."
        fi
        exit
    fi
    if kill -0 "$PID" 2>/dev/null;
    then
        echo "$0: El repositorio ya tiene un daemon activo asociado."
        exit
    fi

    #### PROCESAMIENTO DE ARCHIVO .log
    if [[ "$LOG" =~ ^. ]]; then
        LOG="$me_DIR/$LOG"
    fi

    #### PROCESAMIENTO DE ARCHIVO .conf
    if [[ "$CONFIG" =~ ^. ]]; then
        CONFIG="$me_DIR/$CONFIG"
    fi

    mapfile -t REGEX < <(cat $CONFIG)

    if [ ${#REGEX[@]} -eq 0 ]
    then
        echo "ARCHIVO CONFIG VACIO" >$tty
        exit 1
    fi

    
    tty=$(tty)
    setsid $me_DIR/$me_FILE child "$tty" "$REPO" "$CONFIG" "$LOG" "$REPO_HASH" "$PIDFILE" &
    exit 0
fi

##### RUNS AFTER CHILD FORKS (actually, on Linux, clone()s. See strace -------------->
                               # 3. We have been reforked. Go to work.

shift; tty="$1"; shift
exec >"$3"
exec 0</dev/null
PIDFILE="$5"

#exec 2>/tmp/errfile


echo "Se creo el daemon correctamente." >$tty
echo "esto tendria que leer el repo en busqueda de cambios." >$tty
echo $$ > $PIDFILE
#echo "$PIDFILE" >$tty

while true; do
    echo "Change this loop, so this silly no-op goes away." 
    echo "Do something useful with your life, young padawan." 
    sleep 20
done



exit 
