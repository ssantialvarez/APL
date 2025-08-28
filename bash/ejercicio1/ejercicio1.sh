#!/bin/bash

# https://labex.io/tutorials/shell-bash-getopt-391993
function help() {
    cat << EOF
Usage: $0 [-d|--directorio DIR] [-a|--archivo FILE] [-p|--pantalla SCREEN] [-h|--help]

Options:
  -d, --directorio DIR       Especifica ruta del directorio con los archivos de encuestas a procesar
  -a, --archivo FILE         Especifica ruta completa del archivo JSON de salida. No se puede usar con -p / --pantalla
  -p, --pantalla SCREEN      Muestra la salida por pantalla. No se puede usar con -a / --archivo

  -h, --help                 Muestra este mensaje de ayuda
EOF
    exit 1
}

declare -a RESULTADO
RESULTADO=()
DIRECTORIO=""
ARCHIVO=""
PANTALLA=false

options=$(getopt -o d:a:ph --l help,directorio:,pantalla,archivo: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]
then
    echo "$0: Opciones incorrectas"
    exit 1
fi

eval set -- "$options"

while true
do
    case "$1" in 
        -d | --directorio)
            DIRECTORIO="$2"
            shift 2

            ;;
        -p | --pantalla)
            PANTALLA=true
            shift 
            
            ;;
        -a | --archivo)
            ARCHIVO="$2"
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
            "$0: opcion no reconocida: $1" >&2
            
            exit 1
            ;;
    esac
done

if [ -z "$DIRECTORIO" ]; 
then
    echo "$0: no se ingresó la ruta del directorio." >&2
    exit 1
elif [[ "$PANTALLA" = false && -z "$ARCHIVO" ]]; 
then
    echo "$0: no se especificó archivo de salida ni pantalla." >&2
    exit 1
elif [[ $PANTALLA = true && -n "$ARCHIVO" ]]
then
    echo "$0: argumentos conflictivos." >&2
    exit 1
fi

RESULTADO=$(awk -f ejercicio1.awk $DIRECTORIO)

if [ $PANTALLA = true ]
then
    echo ${RESULTADO[@]} | jq
else
    echo ${RESULTADO[@]} | jq > $ARCHIVO
fi
