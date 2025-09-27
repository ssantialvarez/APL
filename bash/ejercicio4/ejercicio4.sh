#!/bin/bash

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

trap process_USR1 SIGTERM

function process_USR1() {
    echo "HOLA" > "prueba.txt"
    exit 0
}

me_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
me_FILE=$(basename $0)
cd /

declare -a REGEX
REGEX=()
REPO=""
CONFIG=""
KILL=false
LOG=""

#### CHILD HERE --------------------------------------------------------------------->
if [ "$1" = "child" ] ; then   # 2. We are the child. We need to fork again.
    shift; tty="$1"; shift
    umask 0
    $me_DIR/$me_FILE XXrefork_daemonXX "$tty" "$@" </dev/null >/dev/null 2>/dev/null &
    exit 0
fi

##### ENTRY POINT HERE -------------------------------------------------------------->
if [ "$1" != "XXrefork_daemonXX" ] ; then # 1. This is where the original call starts.
    tty=$(tty)
    setsid $me_DIR/$me_FILE child "$tty" "$@" &
    exit 0
fi

##### RUNS AFTER CHILD FORKS (actually, on Linux, clone()s. See strace -------------->
                               # 3. We have been reforked. Go to work.
exec 0</dev/null
shift; tty="$1"; shift
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
        echo "$0: no se especificó archivo de configuración." >&2
        exit 1
    fi
else 
    echo "SE ELIMINA DEMONIO"
fi

if [[ "$CONFIG" =~ ^. ]]; then
    CONFIG="$me_DIR/$CONFIG"
fi

mapfile -t REGEX < <(cat $CONFIG)

if [ ${#REGEX[@]} -eq 0 ]
then
    echo "ARCHIVO CONFIG VACIO" >$tty
    exit 1
fi

#exec >/tmp/outfile
#exec 2>/tmp/errfile


echo "Se creo el daemon correctamente." >$tty
echo "esto tendria que leer el repo en busqueda de cambios." >$tty


exit 
