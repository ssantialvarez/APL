#!/bin/bash

function help() {
    cat << EOF
Usage: $0 [-r|--repo REPO] [-c|--configuracion CONF] [-l|--log LOG] [-k|--kill KILL]

Options:
  -r, --repo REPO            Ruta del repositorio Git a monitorear.
  -c, --configuracion CONF   Ruta del archivo de configuración que contiene la lista de patrones a buscar.
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

REPO=""
CONFIG=""
KILL=false
LOG=""


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
exit