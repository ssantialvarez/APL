#!/bin/bash

# INTEGRANTES DEL GRUPO
# - Santiago Alvarez
# - Federico Loiero
# - Federico Rossendy


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
    exit 0
}

function procesamiento_parametros(){
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
                echo "$0: opcion no reconocida: $1" >&2
                
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
        echo "$0: argumentos conflictivos. Solo se permite una opcion de salida." >&2
        exit 1
    fi
}

function procesamiento_archivos(){
    # Se verifica que el directorio tenga archivos .txt
    # Se desactiva nullglob para encontrar los archivos que tengan el patron que buscamos 
    ARCHIVOS=()
    while IFS= read -r -d $'\0' file; do
        ARCHIVOS+=("$file")
    done < <(find "$DIRECTORIO" -maxdepth 1 -type f -name '*.txt' -print0)

    if [[ ${#ARCHIVOS[@]} -eq 0 ]]; then
        echo "Directorio vacio. $DIRECTORIO"
        exit 1
    fi

    # Verificar que $ARCHIVO NO sea un directorio y que se pueda crear o escribir en el archivo
    if [ -n "$ARCHIVO" ]
    then
        if [ -d "$ARCHIVO" ]
        then
            echo "$0: la ruta de salida es un directorio." >&2
            exit 1
        fi

        touch "$ARCHIVO" 2> /dev/null
        if [ "$?" != "0" ]
        then
            echo "$0: no se puede crear o escribir en el archivo de salida." >&2
            exit 1
        fi
    fi

    touch "$PATH_ENCUESTAS"
    for item in "${ARCHIVOS[@]}"; do
        cat "$item" >> "$PATH_ENCUESTAS"
        echo  >> "$PATH_ENCUESTAS"
    done

    awk 'BEGIN{FS="|"; tee = "tee /tmp/out.txt"}{split($2,a," "); print a[1], $3, $4, $5 | tee}' $PATH_ENCUESTAS >> /dev/null 

    rm $PATH_ENCUESTAS

    PATH_ENCUESTAS="/tmp/out.txt"
    sort -k1,1 -k2,2 $PATH_ENCUESTAS -o $PATH_ENCUESTAS
    mapfile -t ENCUESTAS < <(cat $PATH_ENCUESTAS)

    rm $PATH_ENCUESTAS
}

function calcular_promedios(){
    TIEMPO_PROMEDIO=$(echo "scale = 3; $TIEMPO_PROMEDIO / $CONTADOR" | bc -l)
    NOTA_PROMEDIO=$(echo "scale = 3; $NOTA_PROMEDIO / $CONTADOR" | bc -l)
    
    CANAL_JSON=$(jq -n \
        --arg tiempo "$TIEMPO_PROMEDIO" \
        --arg nota "$NOTA_PROMEDIO" \
        '{
            "tiempo_respuesta_promedio": ($tiempo | tonumber),
            "nota_satisfaccion_promedio": ($nota | tonumber)
        }')

    
    JSON_OUTPUT=$(echo "$JSON_OUTPUT" | jq \
        --arg fecha "$FECHA" \
        --arg canal "$CANAL" \
        --argjson canal_data "$CANAL_JSON" \
        '.[$fecha][$canal] = $canal_data')
}

declare -a ENCUESTAS
ENCUESTAS=()
DIRECTORIO=""
ARCHIVO=""
PANTALLA=false
PATH_ENCUESTAS="/tmp/fechas.txt"

procesamiento_parametros "$@"

procesamiento_archivos


IFS=' ' read -ra ADDR <<< "${ENCUESTAS[0]}"

CONTADOR=0

FECHA=${ADDR[0]}
CANAL=${ADDR[1]}
TIEMPO_PROMEDIO=0
NOTA_PROMEDIO=0

CALCULAR=false

JSON_OUTPUT="{}"


for elem in "${ENCUESTAS[@]}"
do 
    IFS=' ' read -ra ADDR <<< "$elem"

    if [[ ${ADDR[0]} != $FECHA || ${ADDR[1]} != $CANAL ]]
    then
        CALCULAR=true
    else
        TIEMPO_PROMEDIO=$(echo "$TIEMPO_PROMEDIO + ${ADDR[2]}" | bc -l)
        NOTA_PROMEDIO=$(echo "$NOTA_PROMEDIO + ${ADDR[3]}" | bc -l)
        (( CONTADOR+=1 ))
    fi

    if [ $CALCULAR = true ]
    then
        calcular_promedios

        
        FECHA=${ADDR[0]}
        CANAL=${ADDR[1]}
        TIEMPO_PROMEDIO=${ADDR[2]}
        NOTA_PROMEDIO=${ADDR[3]}
        CONTADOR=1
        CALCULAR=false
    fi
done

calcular_promedios



if [ "$PANTALLA" = true ]
then
    echo $JSON_OUTPUT | jq
else
    echo $JSON_OUTPUT | jq > "$ARCHIVO"
fi

exit 0