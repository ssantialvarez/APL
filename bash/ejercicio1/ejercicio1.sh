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

declare -a miArray
miArray=()
DIRECTORIO=""
ARCHIVO=""
PANTALLA=false

options=$(getopt -o d:a:ph --l help,directorio:,pantalla,archivo: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]
then
    echo 'Opciones incorrectas'
    exit 1
fi

eval set -- "$options"

while true
do
    case "$1" in # switch ($1) { 
        -d | --directorio) # case "-e":
            DIRECTORIO="$2"
            shift 2

            ;;
        -p | --pantalla)
            PANTALLA=true
            shift 2
            
            ;;
        -a | --archivo)
            ARCHIVO="$2"
            shift
            
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
            echo "error"
            exit 1
            ;;
    esac
done

if [ $DIRECTORIO = "" ]
then
    echo "ejercicio1: no se ingreso ruta del directorio." >&2
    exit 1
fi

if [[ $PANTALLA == true && $ARCHIVO = "" ]]
then
    echo "ejercicio1: se ingreso ruta del archivo con opcion de pantalla." >&2
    exit 1
fi

miArray=$(awk -f ejercicio1.awk $DIRECTORIO)

echo ${miArray[@]} | jq