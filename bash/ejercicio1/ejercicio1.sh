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
ENCUESTAS="/tmp/fechas.txt"

options=$(getopt -o d:a:ph --l help,directorio:,pantalla,archivo: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]
then
    echo "$0: no se ingresó la ruta del directorio o no se especificó archivo de salida ni pantalla." >&2
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
fi
if [[ "$PANTALLA" = false && -z "$ARCHIVO" ]]; 
then
    echo "$0: no se especificó archivo de salida ni pantalla." >&2
    exit 1
fi
if [[ $PANTALLA = true && -n "$ARCHIVO" ]]
then
    echo "$0: argumentos conflictivos." >&2
    exit 1
fi

# Se verifica que el directorio tenga archivos txt
# Se desactiva nullglob para encontrar los archivos que tengan el patron que buscamos 
shopt -s nullglob
ARCHIVOS=("$DIRECTORIO"/*.txt)
shopt -u nullglob

if [[ ${#ARCHIVOS[@]} -eq 0 ]] 
then
    echo "Directorio vacio. $DIRECTORIO"
    exit 1
fi

touch $ENCUESTAS
for item in ${ARCHIVOS[@]}
do
    cat $item >> $ENCUESTAS
    echo  >> $ENCUESTAS
done

sort -t'|' -k2,2 $ENCUESTAS -o $ENCUESTAS

#LC_NUMERIC=C para convertir decimales con coma a decimales con punto
output=$(
  LC_NUMERIC=C awk -f ejercicio1.awk "$ENCUESTAS" | \
  jq -R -s '
  split("\n")[:-1] 
  | map(split("\t"))
  | reduce .[] as $row ({}; 
      .[$row[0]] += { ($row[1]): {
          tiempo_respuesta_promedio: ($row[2]|tonumber),
          nota_satisfaccion_promedio: ($row[3]|tonumber)
      }}
  )'
)

if [ "$PANTALLA" = true ]
then
    echo "$output"
else
    echo "$output" > "$ARCHIVO"
fi

rm $ENCUESTAS

exit 0