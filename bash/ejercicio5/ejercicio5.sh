#!/bin/bash

# INTEGRANTES DEL GRUPO
# - Santiago Alvarez
# - Federico Loiero
# - Federico Rossendy

function help() {
    cat << EOF
Usage: $0 [-n|--nombre NAME] [-t|--ttl TTL]
Options:
  -n, --nombre NAME          Nombre del país o países a consultar, separados por comas.
  -t, --ttl TTL              Tiempo en segundos que se guarda la cache. Si no se especifica, no se usa cache.

  -h, --help                 Muestra este mensaje de ayuda
EOF
    exit 1
}

# Nombre países
NOMBRE=""
# Tiempo en segundos que se guarda la cache
TTL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--nombre)
            NOMBRE="$2"
            shift 2
            ;;
        -t|--ttl)
            TTL="$2"
            shift 2
            ;;
        -h|--help)
            help
            exit 0
            ;;
        *)
            echo "Uso: $0 -n <nombre> -t <ttl>"
            exit 1
            ;;
        esac
done

if [[ -z "$NOMBRE" || -z "$TTL" ]]; then
    echo "Uso: $0 -n <nombre> -t <ttl>"
    exit 1
fi

IFS=',' read -ra PAISES <<< "$NOMBRE"

mkdir -p cache

get_country_info() {
    local pais="$1"
    response=$(curl -s -w "%{http_code}" "https://restcountries.com/v3.1/name/$pais")
    local status="${response: -3}"
    local body="${response::-3}"
    echo "$status|$body"
}

for pais in "${PAISES[@]}"; do
    echo ""
    echo "Nombre del país: $pais"

    cache_file="cache/$pais.json"
    if [[ -f "$cache_file" ]]; then
        echo "Cargando información de caché para el país $pais"

        if [[ -n "$TTL" ]]; then
            file_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || date -r "$cache_file" +%s 2>/dev/null || echo 0)
            age=$(( $(date +%s) - file_mtime ))
            if (( age > TTL )); then
                echo "La caché ha expirado (edad ${age}s > ${TTL}s)"
                echo "Obteniendo información en tiempo real para el país $pais"
                result=$(get_country_info "$pais")
                status="${result%%|*}"
                body="${result#*|}"
                if [[ "$status" == "200" ]]; then
                    echo "$body" > "$cache_file"
                fi
            else
                body=$(<"$cache_file")
                status="200"
            fi
        else
            body=$(<"$cache_file")
            status="200"
        fi
    else
        echo "Obteniendo información en tiempo real para el país $pais"
        result=$(get_country_info "$pais")
        status="${result%%|*}"
        body="${result#*|}"
        if [[ "$status" == "200" ]]; then
            echo "$body" > "$cache_file"
        fi
    fi

    if [[ "$status" != "200" ]]; then
        echo "Error: País no encontrado"
        continue
    fi

    nombre=$(echo "$body" | grep -o '"common":"[^"]*"' | head -1 | awk -F':' '{print $2}' | tr -d '"')
    capital=$(echo "$body" | grep -o '"capital":\["[^"]*"' | head -1 | awk -F'\\["' '{print $2}' | tr -d '"')
    region=$(echo "$body" | grep -o '"region":"[^"]*"' | head -1 | awk -F':' '{print $2}' | tr -d '"')
    poblacion=$(echo "$body" | grep -o '"population":[0-9]*' | head -1 | awk -F':' '{print $2}')
    moneda_codigo=$(echo "$body" | grep -o '"currencies":{[^}]*}' | grep -o '"[A-Z][A-Z][A-Z]"' | head -1 | tr -d '"')
    moneda_nombre=$(echo "$body" | grep -o '"name":"[^"]*"' | head -1 | awk -F':' '{print $2}' | tr -d '"')

    echo "País: $nombre"
    echo "Capital: $capital"
    echo "Región: $region"
    echo "Población: $poblacion"
    echo "Moneda: $moneda_nombre ($moneda_codigo)"
    echo ""

done

# echo "Tiempo de caché: $TTL"