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
elif [[ "$PANTALLA" = false && -z "$ARCHIVO" ]]; 
then
    echo "$0: no se especificó archivo de salida ni pantalla." >&2
    exit 1
elif [[ $PANTALLA = true && -n "$ARCHIVO" ]]
then
    echo "$0: argumentos conflictivos." >&2
    exit 1
fi

# mapfile -t RESULTADO < <(LC_NUMERIC=C awk -f ejercicio1.awk "$DIRECTORIO")

if [ $PANTALLA = true ]
then
    LC_NUMERIC=C awk -f ejercicio1.awk "$DIRECTORIO" | \
    jq -R -s '
    split("\n")[:-1] 
    | map(split("\t"))
    | reduce .[] as $row ({}; 
        .[$row[0]] += { ($row[1]): {
            tiempo_respuesta_promedio: ($row[2]|tonumber),
            nota_satisfaccion_promedio: ($row[3]|tonumber)
        }}
        )'
else
    LC_NUMERIC=C awk -f ejercicio1.awk "$DIRECTORIO" | \
    jq -R -s '
    split("\n")[:-1] 
    | map(split("\t"))
    | reduce .[] as $row ({}; 
        .[$row[0]] += { ($row[1]): {
            tiempo_respuesta_promedio: ($row[2]|tonumber),
            nota_satisfaccion_promedio: ($row[3]|tonumber)
        }}
        )' > $ARCHIVO
fi


#mapfile -t RESULTADO < <(awk -f prueba.awk "$DIRECTORIO")

#CONTADOR=0
#FECHA=""
#NOTA_PARCIAL=0
#TIEMPO_PARCIAL=0

#for ((i=0; i<${#RESULTADO[@]}; i++)); do
#   ITEM=${RESULTADO[$i]}
#   i=$((i+1))
#   case "$ITEM" in 
#       Fecha)
#           #echo ${RESULTADO[$i]}
#           if [[ $i -eq 0 || $FECHA != ${RESULTADO[$i]} ]]
#           then
#               FECHA=${RESULTADO[$i]}
#               echo $TIEMPO_PARCIAL/$CONTADOR
#               CONTADOR=0
#           fi
#           ;;
#       Nota)
#            #echo ${RESULTADO[$i]}
#            
#            ;;
#        Tiempo)
#            #echo ${RESULTADO[$i]}
#            TIEMPO_PARCIAL=$(($TIEMPO_PARCIAL+${RESULTADO[$i]}))
#            ;;
#    Canal)
#         #echo ${RESULTADO[$i]}
#          ;;
#       *) # default: 
#            
#            exit 1
#           ;;
#   esac
#    CONTADOR=$((CONTADOR+1))
#    #echo "for: ${RESULTADO[$i]}"
#done

