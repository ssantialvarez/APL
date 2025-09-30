#!/bin/bash

# INTEGRANTES DEL GRUPO
# - Santiago Alvarez
# - Federico Loiero
# - Federico Rossendy

# https://labex.io/tutorials/shell-bash-getopt-391993
function help() {
    cat << EOF
Usage: $0 [-d|--directorio DIR] [-p|--palabras WORDS] [-h|--help]

Options:
  -d, --directorio DIR        Especifica ruta del directorio con los archivos de logs a analizar
  -p, --palabras WORDS        Lista de palabras clave a contabilizar, separadas por comas.

  -h, --help                  Muestra este mensaje de ayuda
EOF
    exit 1
}

DIR=""
PALABRAS=""

options=$(getopt -o d:p: --l help,directorio:,palabras -- "$@" 2> /dev/null)
uso() {
    echo "Uso: $0 -d <directorio> -p <palabras separadas por coma>"
    echo "Ejemplo: $0 -d /var/log -p usb,invalid"
    exit 1
}

# Procesar parámetros
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--directorio)
            DIR="$2"
            shift 2
            ;;
        -p|--palabras)
            PALABRAS="$2"
            shift 2
            ;;

        -h|--help)
            help
            exit 0
            ;;
        *)
            uso
            ;;
    esac
done

# Validaciones
if [[ -z "$DIR" || -z "$PALABRAS" ]]; then
    uso
fi

if [[ ! -d "$DIR" ]]; then
    echo "Error: El directorio $DIR no existe."
    exit 1
fi

# Verificar que haya archivos .log
shopt -s nullglob
logs=("$DIR"/*.log)
shopt -u nullglob

if [[ ${#logs[@]} -eq 0 ]]; then
    echo "No se encontraron archivos .log en el directorio $DIR"
    exit 0
fi

# Convertir palabras a array (IFS = separador por coma)
IFS=',' read -r -a KEYWORDS <<< "$PALABRAS"

echo "Palabras clave: ${KEYWORDS[*]}"

# Inicializar conteos
declare -A conteos
for k in "${KEYWORDS[@]}"; do
    conteos["$k"]=0
done

# Procesar cada log con awk
for archivo in "${logs[@]}"; do
    for k in "${KEYWORDS[@]}"; do
        count=$(awk -v palabra="$k" 'BEGIN{IGNORECASE=1} { if($0 ~ palabra) c++ } END{print c+0}' "$archivo")
        conteos["$k"]=$(( conteos["$k"] + count ))
    done
done

# Mostrar resultados
for k in "${KEYWORDS[@]}"; do
    echo "$k: ${conteos[$k]}" 
done