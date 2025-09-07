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
            if [[ -z "$TTL" || $(( $(date +%s) - $(stat -c %Y "$cache_file") )) -gt $TTL ]]; then
                echo "La caché ha expirado o no está disponible"
                echo "Obteniendo información en tiempo real para el país $pais"
                result=$(get_country_info "$pais")
                status="${result%%|*}"
                # echo "Código de estado: $status"
                body="${result#*|}"
            fi
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
        echo "$body" > "$cache_file"
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