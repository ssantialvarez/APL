#!/bin/bash

# ----- Variables -----------

# Nombre pais
NOMBRE=""
# Tiempo en segundos que se guarda la cache
TTL=""

# ---------------------------

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
        *)
            echo "Uso: $0 -n <nombre> -t <ttl>"
            exit 1
            ;;
        esac
done

# Comprobamos que se han pasado los argumentos necesarios

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

        if [[ -z "$TTL" || $(find "$cache_file" -mmin +$TTL) ]]; then
            echo "La caché ha expirado o no está disponible"
            echo "Obteniendo información en tiempo real para el país $pais"
            result=$(get_country_info "$pais")
            status="${result%%|*}"
            # echo "Código de estado: $status"
            body="${result#*|}"
        else
            body=$(<"$cache_file")
            status="200"
        fi
    else
        echo "Obteniendo información en tiempo real para el país $pais"
        result=$(get_country_info "$pais")
        status="${result%%|*}"
        # echo "Código de estado: $status"
        body="${result#*|}"
    fi

    if [[ "$status" != "200" ]]; then
        echo "Error: País no encontrado"
        continue
    fi

    nombre=$(echo "$body" | jq -r '.[0].name.common')
    capital=$(echo "$body" | jq -r '.[0].capital[0]')
    region=$(echo "$body" | jq -r '.[0].region')
    poblacion=$(echo "$body" | jq -r '.[0].population')
    moneda_codigo=$(echo "$body" | jq -r '.[0].currencies | to_entries | map(.key) | .[]')
    moneda_nombre=$(echo "$body" | jq -r '.[0].currencies | to_entries | map(.value.name) | .[]')

    echo "País: $nombre"
    echo "Capital: $capital"
    echo "Región: $region"
    echo "Población: $poblacion"
    echo "Moneda: $moneda_nombre ($moneda_codigo)"
    echo ""

done

echo "Tiempo de caché: $TTL"